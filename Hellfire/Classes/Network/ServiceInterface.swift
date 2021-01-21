//
//  ServiceInterface.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias RequestTaskIdentifier = Int
public typealias ReachabilityHandler = (ReachabilityStatus) -> Void
public typealias ServiceErrorHandler = (ServiceError) -> Void
public typealias TaskResult = (RequestResult) -> Void

/// Only one instance per app should be created.  However, rather than trying to enforce this via a singleton, its up to the app developer when to create multiple instances.
/// Be aware that DiskCache storage is shared between multiple ServiceInterface instances.  Although a unique hash insertion key will be created, storage size will be shared.
public class ServiceInterface: NSObject {
    
    //MARK: - Private API
    
    private var reachabilityManager: NetworkReachabilityManager?
    private var privateReachabilityHost: String?
    private lazy var requestCollection = RequestCollection()
    private lazy var diskCache = DiskCache()
    private lazy var backgroundSessionIdentifier: String = "Hellfire.BackgroundUrlSession"
    private lazy var dataTaskSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        let urlSession = URLSession(configuration: configuration)
        return urlSession
    }()
    private lazy var backgroundSession: URLSession = {
        let operationQueue = OperationQueue()
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        operationQueue.qualityOfService = .userInteractive

        let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        //configuration.timeoutIntervalForRequest = {For now using default - 60 seconds}
        //configuration.timeoutIntervalForResource = {For now using default - 7 days}
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        return urlSession
    }()
    private lazy var defaultRequestHeaders: [AnyHashable: Any] = {
        var headers = [AnyHashable: Any]()
        [HTTPHeader.defaultUserAgent,
         HTTPHeader(name: "X-Correlation-ID", value: UUID().uuidString)]
            .forEach { headers[$0.name] = $0.value }
        return headers
    }()
    
    private func statusCodeForResponse(_ response: HTTPURLResponse?, error: Error?) -> StatusCode {
        /*
         In Hellfire, we always want to have a value in statusCode for easier error detection.
         This means that for non URL reponse errors, we set the statusCode to the negative values of 'URL Loading System Error Codes'.
         */
        let statusCode: StatusCode = response?.statusCode ??
            (error as NSError?)?.code ??
            //We should never get to this last option.  But if there was no statusCode from the response and there was no error instance, we are defaulting to HTTP.ok
            HTTPCode.ok.rawValue
        return statusCode
    }
    
    private func responseHeaders(_ response: HTTPURLResponse?) -> [HTTPHeader] {
        guard let headers = response?.allHeaderFields else { return [] }
        let httpHeaders = headers.compactMap { HTTPHeader(name: "\($0.key)", value: "\($0.value)") }
        return httpHeaders
    }
    
    private func createServiceError(data: Data?, statusCode: StatusCode, error: Error?, request: URLRequest) -> ServiceError {
        let requestCancelled = HTTPCode.wasRequestCancelled(statusCode: statusCode)
        let serviceError = ServiceError(request: request, error: error, statusCode: statusCode, responseBody: data, userCancelledRequest: requestCancelled)
        self.serviceErrorHandler?(serviceError)
        return serviceError
    }
    
    private func urlRequest(fromNetworkRequest request: NetworkRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.name
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval
        
        //Set ContentType per request.
        let contentTypeHeader = HTTPHeader.contentType(request.contentType)
        urlRequest.setValue(contentTypeHeader.value, forHTTPHeaderField: contentTypeHeader.name)
        
        //Ask session delegate for additional headers or updates to headers for this request.
        let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
        appHeaders.forEach({ (header) in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        })
        
        return urlRequest
    }
    
    private func hasCachedResponse(forRequest request: NetworkRequest, completion: @escaping TaskResult) -> Bool {
        if request.cachePolicyType != CachePolicyType.doNotCache {
            if let response = self.diskCache.getCacheDataFor(request: request) {
                DispatchQueue.main.async {
                    let dataResponse = NetworkResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                                       body: response,
                                                       statusCode: HTTPCode.ok.rawValue)
                    completion(.success(dataResponse))
                }
                return true
            }
        }
        return false
    }
    
    private func setupReachabilityManager(host: String) {
        self.reachabilityManager?.stopListening()
        self.reachabilityManager?.listener = nil
        self.reachabilityManager = NetworkReachabilityManager(host: host)
        self.reachabilityManager?.listener = { [weak self] status in
            guard let strongSelf = self else { return }
            switch status {
            case .notReachable:
                strongSelf.reachabilityHandler?(.notReachable)
            case .unknown :
                strongSelf.reachabilityHandler?(.unknown)
            case .reachable(.ethernetOrWiFi):
                strongSelf.reachabilityHandler?(.reachable(.wiFiOrEthernet))
            case .reachable(.wwan):
                strongSelf.reachabilityHandler?(.reachable(.cellular))
            }
        }
        self.reachabilityManager?.startListening()
    }
    
    private func taskResponseHandler(request: NetworkRequest, urlRequest: URLRequest, completion: @escaping TaskResult, data: Data?, response: URLResponse?, error: Error?) {
        let httpURLResponse = response as? HTTPURLResponse
        let statusCode = self.statusCodeForResponse(httpURLResponse, error: error)
        
        //If call was successful and we have data, store response in disk cache.
        if let responseData = data, HTTPCode.isOk(statusCode: statusCode), request.cachePolicyType != .doNotCache {
            self.diskCache.cache(data: responseData, forRequest: request)
        }
        
        //Send back response headers to delegate.  (Headers will be additionally included with the NetworkResponse.)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(httpURLResponse)
        self.sessionDelegate?.responseHeaders(headers: responseHeaders, forRequest: request)
        
        //Remove task from request collection
        self.requestCollection.removeTask(forRequest: urlRequest)
        
        //Call completion block
        DispatchQueue.main.async {
            if HTTPCode.isOk(statusCode: statusCode) {
                let dataResponse = NetworkResponse(headers: responseHeaders, body: data, statusCode: statusCode)
                completion(.success(dataResponse))
            } else {
                let serviceError = self.createServiceError(data: data, statusCode: statusCode, error: error, request: urlRequest)
                completion(.failure(serviceError))
            }
        }
    }
    
    //MARK: - Public API
    
    deinit {
        #if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
        #endif
    }

    
    //TODO: Finish the injection of this configuration.
//    public init(backgroundSessionConfiguration: URLSessionConfiguration) {
//        self.backgroundSession.configuration = backgroundSessionConfiguration
//    }
    
    ///Gets or sets the handler for the reachability status change events.
    public var reachabilityHandler: ReachabilityHandler?
    
    ///Gets or sets the handler for the service error handler
    public var serviceErrorHandler: ServiceErrorHandler?
    
    /**
     Gets or sets the reachability host (e.g. "www.apple.com").
     Setting the host to some value starts the listener.
     Setting the host to nil will stop the listener.
     IMPORTANT NOTE: You must set self.reachabilityHost after setting self.reachabilityHandler, otherwise reachability manager will not start listening for network change events.
     */
    public var reachabilityHost: String? {
        get {
            return self.privateReachabilityHost
        }
        set {
            self.privateReachabilityHost = newValue
            if let host = newValue, host.isEmpty == false {
                self.setupReachabilityManager(host: host)
            }
        }
    }
    
    public weak var sessionDelegate: HellfireSessionDelegate?
    
    /// Executes a background upload task for the `NetworkRequest` using a local `URL` as the source to be uploaded.  The upload task is created on the background session.  Response is returned via the delegate callback.
    /// - Parameters:
    ///   - request: The network request to be executed
    ///   - localURL: Local URL to the source that is to be uploaded.
    /// - Returns: `RequestTaskIdentifier` that identifies the underlying URLSessionDataTask.  This identifier can be used to cancel the network request.
    public func executeBackgroundUpload(_ request: NetworkRequest, localURL: URL) -> RequestTaskIdentifier? {
        let _request = NetworkRequest.uploadRequest(fromRequest: request)
        let urlRequest = self.urlRequest(fromNetworkRequest: _request)
        let task = self.backgroundSession.uploadTask(with: urlRequest, fromFile: localURL)
        self.requestCollection.add(request: urlRequest, task: task)
        task.resume()
        return task.taskIdentifier
    }
    

    public func executeUpload(_ request: MultipartRequest) -> RequestTaskIdentifier? {
        guard let urlRequest = try? request.build() else {
//            completion(.failure(ServiceError(request: <#T##URLRequest#>, error: <#T##Error?#>, statusCode: <#T##StatusCode#>, responseBody: <#T##Data?#>, userCancelledRequest: <#T##Bool#>)))
            return nil
        }
        
        let task = self.backgroundSession.uploadTask(withStreamedRequest: urlRequest)
        
//        { [weak self] (data, response, error) in
//            guard let strongSelf = self else { return }
//            strongSelf.taskResponseHandler(request: _request, urlRequest: urlRequest, completion: completion, data: data, response: response, error: error)
//        }
//
//        self.requestCollection.add(request: urlRequest, task: task)
        task.resume()
        
        return task.taskIdentifier
    }
    
    ///Executes the network request asynchronously as a [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask), intended to be a relatively short request.
    ///Cached and network responses are called back by dispatching to the main thread and calling the completion block.  For cached responses, the network response object will have a response header added with the name `CachedResponse` with a value of `true`.
    ///A `RequestTaskIdentifier` is returned for a NetworkRequest that is dispatched to URL session.  This identifier can be used to cancel the network request.
    ///
    /// - Parameters:
    ///     - request: The network request to be executed
    ///     - completion: The completion function to be called with the response.
    /// - Returns: `RequestTaskIdentifier` that identifies the underlying [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask).  This identifier can be used to cancel the network request.
    public func execute(_ request: NetworkRequest, completion: @escaping TaskResult) -> RequestTaskIdentifier? {
        if hasCachedResponse(forRequest: request, completion: completion) { return nil }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let task = self.dataTaskSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let strongSelf = self else { return }
            strongSelf.taskResponseHandler(request: request, urlRequest: urlRequest, completion: completion, data: data, response: response, error: error)
        }
        
        self.requestCollection.add(request: urlRequest, task: task)
        task.resume()
        
        return task.taskIdentifier
    }
    
    ///Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Identifer for the network request.
    public func cancelRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier else { return }
        self.requestCollection.removeRequest(forTaskIdentifier: taskId)
    }
    
    ///Cancels all current network requests.
    public func cancelAllCurrentRequests() {
        let tasks = self.requestCollection.allTasks()
        tasks.forEach { (task) in
            self.cancelRequest(taskIdentifier: task)
        }
    }
    
    ///Clears all cached data for any instance of ServiceInterface.
    public func clearCache() {
        self.diskCache.clearCache()
    }
    
    /// Clears cached data for the specified cache policy type only
    /// - Parameter policyType: The cache bucket that is to be cleared.
    public func clearCache(policyType: CachePolicyType) {
        self.diskCache.clearCache(policyType: policyType)
    }
}

//MARK: - URLSessionDataDelegate protocol
extension ServiceInterface: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        self.sessionDelegate?.session(session, dataTask: dataTask, didReceive: data)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let request = self.requestCollection.task(forTaskIdentifier: task.taskIdentifier) else { return }
        
        self.requestCollection.removeRequest(forTaskIdentifier: task.taskIdentifier)
        let httpURLResponse = task.response as? HTTPURLResponse
        let statusCode = self.statusCodeForResponse(httpURLResponse, error: error)
        let responseHeaders: [HTTPHeader] = self.responseHeaders(httpURLResponse)
        
        if HTTPCode.isOk(statusCode: statusCode) {
            let dataResponse = NetworkResponse(headers: responseHeaders, body: nil, statusCode: statusCode)
            DispatchQueue.main.async { [weak self] in
                self?.sessionDelegate?.backgroundTask(task, didComplete: .success(dataResponse))
            }
        } else {
            let serviceError = self.createServiceError(data: nil, statusCode: statusCode, error: error, request: request)
            DispatchQueue.main.async { [weak self] in
                self?.sessionDelegate?.backgroundTask(task, didComplete: .failure(serviceError))
            }
        }
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didSendBodyData bytesSent: Int64, totalBytesSent: Int64, totalBytesExpectedToSend: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task, didSendBytes: Int(bytesSent), totalBytesSent: Int(totalBytesSent), totalBytesExpectedToSend: Int(totalBytesExpectedToSend))
        }
    }
}


//MARK: - URLSessionTaskDelegate protocol
extension ServiceInterface: URLSessionTaskDelegate {
    
    //Handles task specific challenges.  e.g. Username/Password
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        completionHandler(.performDefaultHandling, nil)
        print("============================ Task auth challenge delegate callback ============================ ")
        if challenge.previousFailureCount > 0 {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}


//MARK: - URLSessionDelegate protocol
extension ServiceInterface: URLSessionDelegate {
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async { [weak self] in
            //Need to call the saved completion handler.
            self?.sessionDelegate?.backgroundSessionDidFinishEvents(session: session)
        }
        
//        DispatchQueue.main.async {
//            guard let appDelegate = UIApplication.shared.delegate as? AppDelegate,
//                  let backgroundCompletionHandler =
//                    appDelegate.backgroundCompletionHandler else {
//                return
//            }
//            backgroundCompletionHandler()
//        }
    }

    public func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        self.sessionDelegate?.session(session, didBecomeInvalidWithError: error)
    }

    //Handles session wide challenges.  e.g. TLS validation
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        print("============================  Session auth challenge delegate callback ============================ ")
        if challenge.previousFailureCount > 0 {
            completionHandler(.cancelAuthenticationChallenge, nil)
        } else {
            completionHandler(.performDefaultHandling, nil)
        }
    }
}
