//
//  SessionInterface.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

public typealias RequestTaskIdentifier = UUID
public typealias ServiceErrorHandler = (ServiceError) -> Void
public typealias JSONTaskResult<T: JSONSerializable> = (JSONSerializableResult<T>) -> Void
public typealias DataTaskResult = (RequestResult) -> Void

/// Multiple instances can be created, each with there own session and session delegate.
///
/// Be aware that DiskCache storage are shared between multiple SessionInterface instances.
/// Concerning DiskCache, although a unique hash insertion key will be created, storage will be shared between the instances.
public class SessionInterface: NSObject {
    
    //MARK: - ServiceInterface overrides API
    
    deinit {
#if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
#endif
    }
    
    public required override init() {
        self.backgroundSessionIdentifier = "Hellfire.BackgroundUrlSession"
        self.defaultRequestHeaders = [HTTPHeader.defaultUserAgent].headers
        super.init()
    }
    
    public required init(backgroundSessionIdentifier: String) {
        self.backgroundSessionIdentifier = backgroundSessionIdentifier
        self.defaultRequestHeaders = [HTTPHeader.defaultUserAgent].headers
        super.init()
    }
    
    //MARK: - Private Property API
    
    private lazy var diskCache: DiskCacheStore = {
        let processInfo = ProcessInfo.processInfo
        let appName = processInfo.processName
        var cacheURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first!
        cacheURL.append(component: "HellfireDiskCache")
        cacheURL.append(component: appName)
        
        let dcs = DiskCacheStore(rootPath: cacheURL,
                                 configuration: DiskCacheConfiguration())
        return dcs
    }()
        
    private lazy var db: SQLiteManager = SQLiteManager()
    private var backgroundSessionIdentifier: String
    
    private lazy var dataTaskSession: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = nil
        configuration.shouldUseExtendedBackgroundIdleMode = true
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: nil)
        return urlSession
    }()
    
    private lazy var backgroundSession: URLSession = {
        let operationQueue = OperationQueue()
        //Allow the system automatically determine concurrent tasks based on current system resources. (via OperationQueue.defaultMaxConcurrentOperationCount)
        operationQueue.maxConcurrentOperationCount = OperationQueue.defaultMaxConcurrentOperationCount
        operationQueue.qualityOfService = .userInteractive
        
        let configuration = URLSessionConfiguration.background(withIdentifier: self.backgroundSessionIdentifier)
        configuration.httpAdditionalHeaders = self.defaultRequestHeaders
        configuration.requestCachePolicy = .reloadIgnoringCacheData
        configuration.urlCache = nil
        configuration.sessionSendsLaunchEvents = true
        configuration.isDiscretionary = false
        configuration.shouldUseExtendedBackgroundIdleMode = true
        //configuration.timeoutIntervalForRequest = {For now using default - 60 seconds}
        //configuration.timeoutIntervalForResource = {For now using default - 7 days}
        let urlSession = URLSession(configuration: configuration, delegate: self, delegateQueue: operationQueue)
        return urlSession
    }()
    
    private var defaultRequestHeaders: [AnyHashable: Any]
    
    //MARK: - Private Func API
    
    private func statusCodeForResponse(_ response: URLResponse?) -> StatusCode? {
        let statusCode: StatusCode? = (response as? HTTPURLResponse)?.statusCode
        return statusCode
    }
    
    private func sendToDelegate(responseHeaders: [HTTPHeader], forRequest request: NetworkRequest) {
        self.sessionDelegate?.responseHeaders(headers: responseHeaders, forRequest: request)
    }
    
    private func httpHeadersFrom(_ response: URLResponse?) -> [HTTPHeader] {
        guard let headers = (response as? HTTPURLResponse)?.allHeaderFields else { return [] }
        let httpHeaders = headers.compactMap { HTTPHeader(name: "\($0.key)", value: "\($0.value)") }
        return httpHeaders
    }
    
    private func createServiceError(data: Data?,
                                    statusCode: StatusCode?,
                                    error: Error?,
                                    requestURL: URL?) -> ServiceError {
        let requestCancelled = (error as NSError?)?.code == HellfireError.userCancelled
        let error = error ?? HellfireError.generalError
        let serviceError = ServiceError(requestURL: requestURL,
                                        error: error,
                                        statusCode: statusCode,
                                        responseBody: data,
                                        userCancelledRequest: requestCancelled)
        if let serviceErrorHandler = self.serviceErrorHandler {
            serviceErrorHandler(serviceError)
        } else {
            self.defaultServiceErrorHandler(serviceError)
        }
        return serviceError
    }
    
    private func urlRequest(fromNetworkRequest request: NetworkRequest) -> URLRequest {
        var urlRequest = URLRequest(url: request.url)
        urlRequest.httpMethod = request.method.urlRequestMethod
        urlRequest.httpBody = request.body
        urlRequest.timeoutInterval = request.timeoutInterval
        
        //Ask session delegate for global headers for this request.
        let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
        appHeaders.forEach({ (header) in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        })
        
        //Set request headers per request.
        request.headers.forEach({ (header) in
            urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
        })
        return urlRequest
    }
    
    private func hasCachedResponse(forRequest request: NetworkRequest) -> Data? {
        if request.cachePolicyType != CachePolicyType.doNotCache, let response = self.diskCache.load(for: request) {
            return response
        }
        return nil
    }
    
    private func taskResponseHandler(request: NetworkRequest,
                                     data: Data?,
                                     response: URLResponse?,
                                     error: Error?,
                                     completion: @escaping DataTaskResult) {
        let statusCode = self.statusCodeForResponse(response)
        let responseHeaders = self.httpHeadersFrom(response)
        self.sendToDelegate(responseHeaders: responseHeaders, forRequest: request)
        
        if error == nil, HTTPCode.isOk(statusCode), let responseData = data {
            self.diskCache.store(responseData, for: request)
        }
        
        //Call completion block
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if error == nil && HTTPCode.isOk(statusCode) {
                let dataResponse = DataResponse(headers: responseHeaders,
                                                statusCode: statusCode,
                                                body: data)
                completion(.success(dataResponse))
            } else {
                let serviceError = self.createServiceError(data: data,
                                                           statusCode: statusCode,
                                                           error: error,
                                                           requestURL: request.url)
                completion(.failure(serviceError))
            }
        }
    }
    
    private func taskResponseHandler<T: JSONSerializable>(request: NetworkRequest,
                                                          data: Data?,
                                                          response: URLResponse?,
                                                          error: Error?,
                                                          completion: @escaping JSONTaskResult<T>) {
        let statusCode = self.statusCodeForResponse(response)
        let responseHeaders = self.httpHeadersFrom(response)
        self.sendToDelegate(responseHeaders: responseHeaders, forRequest: request)
        
        //Call completion block
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            
            if error == nil && HTTPCode.isOk(statusCode) {
                do {
                    let jsonObject = try T.initialize(jsonData: data)
                    let dataResponse = JSONSerializableResponse<T>(headers: responseHeaders,
                                                                   statusCode: statusCode,
                                                                   jsonObject: jsonObject)
                    if let responseData = data {
                        self.diskCache.store(responseData, for: request)
                    }
                    completion(.success(dataResponse))
                } catch {
                    let serviceError = self.createServiceError(data: data,
                                                               statusCode: nil,
                                                               error: error,
                                                               requestURL: request.url)
                    completion(.failure(serviceError))
                }
            } else {
                let serviceError = self.createServiceError(data: data,
                                                           statusCode: statusCode,
                                                           error: error,
                                                           requestURL: request.url)
                completion(.failure(serviceError))
            }
        }
    }
    
    //MARK: - Public Property API
    
    /// Gets or sets the handler for the service error handler
    public var serviceErrorHandler: ServiceErrorHandler?

    /// A protocol this is implemented optionally by the SessionInterface delegate.
    public weak var sessionDelegate: HellfireSessionDelegate?
    
    //MARK: - Public API Upload
    
    /// Executes the `MultipartRequest` request asynchronously as a [URLSessionUploadTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionUploadTask).
    ///
    /// Upload tasks are run on a background URLSession.  The default URLSession identifier for this background session is Hellfire.BackgroundUrlSession.  A custom background session identifier can be passed in on init.
    /// - Parameter request: The multipart form data request that is to be executed.
    /// - Returns: Unique task identifier for the [URLSessionUploadTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionUploadTask). This identifier can be used to cancel the network request.
    public func executeUpload(_ request: MultipartRequest) throws -> RequestTaskIdentifier {
        do {
            let requestComponents = try request.build()
            var urlRequest = requestComponents.urlRequest
            
            //Ask session delegate for additional headers or updates to headers for this request.
            let appHeaders: [HTTPHeader] = self.sessionDelegate?.headerCollection(forRequest: request) ?? []
            appHeaders.forEach({ (header) in
                if urlRequest.value(forHTTPHeaderField: header.name) == nil {
                    urlRequest.setValue(header.value, forHTTPHeaderField: header.name)
                }
            })
            
            let task = self.backgroundSession.uploadTask(with: urlRequest, fromFile: requestComponents.requestBody)
            
            let taskIdentifier = UUID()
            let requestItem = RequestItem(requestIdentifier: taskIdentifier,
                                          taskIdentifier: task.taskIdentifier,
                                          streamBodyURL: requestComponents.requestBody)
            try self.db.insert(requestItem: requestItem)
            task.taskDescription = requestItem.requestIdentifier.uuidString
            task.resume()
            return requestItem.requestIdentifier
        } catch (let error) {
            let serviceError = self.createServiceError(data: error.localizedDescription.data(using: .utf8),
                                                       statusCode: nil,
                                                       error: error,
                                                       requestURL: request.url)
            
            throw HellfireError.ServiceRequestError.unableToCreateTask(result: RequestResult.failure(serviceError))
        }
    }
    
    //MARK: - Public API Async/Await Data fetch
    
    public func execute(_ request: NetworkRequest) async throws -> DataResponse {
        if let cachedResponse = hasCachedResponse(forRequest: request) {
            let dataResponse = DataResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                            statusCode: HTTPCode.ok.rawValue,
                                            body: cachedResponse)
            return dataResponse
        }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let (data, response) = try await self.dataTaskSession.data(for: urlRequest, delegate: self)
        
        let statusCode = self.statusCodeForResponse(response)
        let responseHeaders = self.httpHeadersFrom(response)
        self.sendToDelegate(responseHeaders: responseHeaders, forRequest: request)
        
        if HTTPCode.isOk(statusCode) {
            self.diskCache.store(data, for: request)
        }
        
        let dataResponse = DataResponse(headers: responseHeaders,
                                        statusCode: statusCode,
                                        body: data)
        return dataResponse
    }
    
    //MARK: - Public API Async/Await JSONSerializable fetch
    
    public func execute<T: JSONSerializable>(_ request: NetworkRequest) async throws -> JSONSerializableResponse<T> {
        
        if let cachedResponse = hasCachedResponse(forRequest: request), let jsonObject = try? T.initialize(jsonData: cachedResponse) {
            let jsonResponse = JSONSerializableResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                                        statusCode: HTTPCode.ok.rawValue,
                                                        jsonObject: jsonObject)
            return jsonResponse
        }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let (data, response) = try await self.dataTaskSession.data(for: urlRequest, delegate: self)

        let statusCode = self.statusCodeForResponse(response)
        let responseHeaders = self.httpHeadersFrom(response)
        self.sendToDelegate(responseHeaders: responseHeaders, forRequest: request)

        if HTTPCode.isOk(statusCode) {
            self.diskCache.store(data, for: request)
        }
        
        do {
            let jsonObject = try T.initialize(jsonData: data)
            let jsonResponse = JSONSerializableResponse<T>(headers: responseHeaders,
                                                           statusCode: statusCode,
                                                           jsonObject: jsonObject)
            return jsonResponse
        } catch {
            
            let serviceError = self.createServiceError(data: data,
                                                       statusCode: statusCode,
                                                       error: error,
                                                       requestURL: request.url)
            
            throw serviceError
        }
    }

    //MARK: - Public API Async/Completion block Data fetch
    
    /// Executes the network request asynchronously as a [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask), intended to be a relatively short request.
    ///
    /// Cached and network responses are called back by dispatching to the main thread and calling the completion block.  For cached responses, the network response object will have a response header added with the name `CachedResponse` with a value of `true`.
    /// A `RequestTaskIdentifier` is returned for a NetworkRequest that is dispatched to URL session.  This identifier can be used to cancel the network request.
    /// - Parameters:
    ///     - request: The network request to be executed
    ///     - completion: The completion function to be called with the response.
    /// - Returns: `RequestTaskIdentifier`  Unique task identifier for the [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask).  This identifier can be used to cancel the network request.
    public func execute(_ request: NetworkRequest,
                        completion: @escaping DataTaskResult) throws -> RequestTaskIdentifier? {
        if let cachedResponse = hasCachedResponse(forRequest: request) {
            DispatchQueue.main.async {
                let dataResponse = DataResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                                statusCode: HTTPCode.ok.rawValue,
                                                body: cachedResponse)
                completion(.success(dataResponse))
            }
            return nil
        }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let task = self.dataTaskSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self else { return }
            self.taskResponseHandler(request: request,
                                     data: data,
                                     response: response,
                                     error: error,
                                     completion: completion)
        }
        
        let taskIdentifier = UUID()
        let requestItem = RequestItem(requestIdentifier: taskIdentifier,
                                      taskIdentifier: task.taskIdentifier)
        try self.db.insert(requestItem: requestItem)
        task.taskDescription = requestItem.requestIdentifier.uuidString
        task.resume()
        return taskIdentifier
    }
    
    //MARK: - Public API Async/Completion block JSONSerializable fetch
    
    /// Executes the network request asynchronously as a [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask), intended to be a relatively short request.
    ///
    /// Cached and network responses are called back by dispatching to the main thread and calling the completion block.  For cached responses, the network response object will have a response header added with the name `CachedResponse` with a value of `true`.
    /// A `RequestTaskIdentifier` is returned for a NetworkRequest that is dispatched to URL session.  This identifier can be used to cancel the network request.
    /// - Parameters:
    ///     - request: The network request to be executed
    ///     - completion: The completion function to be called with the response.
    /// - Returns: `RequestTaskIdentifier`  Unique task identifier for the [URLSessionDataTask](apple-reference-documentation://ls%2Fdocumentation%2Ffoundation%2FURLSessionDataTask).  This identifier can be used to cancel the network request.
    public func execute<T: JSONSerializable>(_ request: NetworkRequest,
                                             completion: @escaping JSONTaskResult<T>) throws -> RequestTaskIdentifier? {
        
        if let cachedResponse = hasCachedResponse(forRequest: request), let jsonObject = try? T.initialize(jsonData: cachedResponse) {
            DispatchQueue.main.async {
                let dataResponse = JSONSerializableResponse(headers: [HTTPHeader(name: "CachedResponse", value: "true")],
                                                            statusCode: HTTPCode.ok.rawValue,
                                                            jsonObject: jsonObject)
                completion(.success(dataResponse))
            }
            return nil
        }
        
        let urlRequest = self.urlRequest(fromNetworkRequest: request)
        let task = self.dataTaskSession.dataTask(with: urlRequest) { [weak self] data, response, error in
            guard let self else { return }
            self.taskResponseHandler(request: request,
                                     data: data,
                                     response: response,
                                     error: error,
                                     completion: completion)
        }
        
        let taskIdentifier = UUID()
        let requestItem = RequestItem(requestIdentifier: taskIdentifier,
                                       taskIdentifier: task.taskIdentifier)
        try self.db.insert(requestItem: requestItem)
        task.taskDescription = requestItem.requestIdentifier.uuidString
        task.resume()
        return  requestItem.requestIdentifier
    }
    
    //MARK: - Public API Control Functions
    
    /// Gets all the tasks currently running on the background session.
    /// - Parameter completion: Returns a tuple of three arrays via an asynchronous completion block. ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask])
    public func getBackgroundTasks(completion: @escaping ([URLSessionDataTask], [URLSessionUploadTask], [URLSessionDownloadTask]) -> Void) {
        self.backgroundSession.getTasksWithCompletionHandler { (dataTasks, uploadTasks, downloadTasks) in
            completion(dataTasks, uploadTasks, downloadTasks)
        }
    }
    
    /// Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Unique task identifier for the URLSessionTask.
    public func cancelUploadRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier?.uuidString else { return }
        self.backgroundSession.getAllTasks { (backgroundSessionTasks) in
            if let task = backgroundSessionTasks.first(where: { $0.taskDescription == taskId }) {
                task.cancel()
            }
        }
    }
    
    /// Cancels the network request for the specified request task identifier.
    ///
    /// - Parameters:
    ///     - taskIdentifier: Unique task identifier for the URLSessionTask.
    public func cancelDataRequest(taskIdentifier: RequestTaskIdentifier?) {
        guard let taskId = taskIdentifier?.uuidString else { return }
        
        self.dataTaskSession.getAllTasks { (dataSessionTasks) in
            if let task = dataSessionTasks.first(where: { $0.taskDescription == taskId }) {
                task.cancel()
            }
        }
    }
    
    /// Cancels all current network requests on all sessions.
    public func cancelAllCurrentRequests() {
        self.backgroundSession.getAllTasks { (backgroundSessionTasks) in
            backgroundSessionTasks.forEach { $0.cancel() }
        }
        self.dataTaskSession.getAllTasks { (dataSessionTasks) in
            dataSessionTasks.forEach { $0.cancel() }
        }
    }
    
    /// Clears all cached data for any instance of ServiceInterface.
    public func clearCache() {
        self.diskCache.clearAll()
    }
    
    /// Clears cached data for the specified cache policy type only
    /// - Parameter policyType: The cache bucket that is to be cleared.
    public func clearCache(policyType: CachePolicyType) {
        self.diskCache.clear(for: policyType)
    }
}

//MARK: - URLSessionDataDelegate protocol
extension SessionInterface: URLSessionDataDelegate {
    
    public func urlSession(_ session: URLSession,
                           dataTask: URLSessionDataTask,
                           didReceive data: Data) {
        
        self.sessionDelegate?.session(session,
                                      dataTask: dataTask,
                                      didReceive: data)
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didCompleteWithError error: Error?) {
        let statusCode = self.statusCodeForResponse(task.response)
        let responseHeaders: [HTTPHeader] = self.httpHeadersFrom(task.response)
        var result: RequestResult
        
        if HTTPCode.isOk(statusCode) {
            let dataResponse = DataResponse(headers: responseHeaders,
                                            statusCode: statusCode,
                                            body: nil)
            result = .success(dataResponse)
        } else {
            let serviceError = self.createServiceError(data: nil,
                                                       statusCode: statusCode,
                                                       error: error,
                                                       requestURL: task.originalRequest?.url)
            result = .failure(serviceError)
        }
        
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task, didCompleteWithResult: result)
        }
        
        // Clean up
        if let uuidString = task.taskDescription
            , let requestTaskIdentifier = RequestTaskIdentifier(uuidString: uuidString)
            , let requestItem = try? self.db.fetchRequestItem(byId: requestTaskIdentifier)
            , let fileURL = requestItem.streamBodyURL {
            try? FileManager.default.removeItem(at: fileURL)
        }
    }
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didSendBodyData bytesSent: Int64,
                           totalBytesSent: Int64,
                           totalBytesExpectedToSend: Int64) {
        DispatchQueue.main.async { [weak self] in
            self?.sessionDelegate?.backgroundTask(task,
                                                  didSendBytes: bytesSent,
                                                  totalBytesSent: totalBytesSent,
                                                  totalBytesExpectedToSend: totalBytesExpectedToSend)
        }
    }
}

//MARK: - URLSessionTaskDelegate protocol
extension SessionInterface: URLSessionTaskDelegate {
    
    public func urlSession(_ session: URLSession,
                           task: URLSessionTask,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let sessionDelegate =  self.sessionDelegate else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        sessionDelegate.session(session,
                                task: task,
                                didReceive: challenge,
                                completionHandler: completionHandler)
    }
}


//MARK: - URLSessionDelegate protocol
extension SessionInterface: URLSessionDelegate {
    
    public func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        self.sessionDelegate?.backgroundSessionDidFinishEvents(session: session)
    }
    
    public func urlSession(_ session: URLSession,
                           didBecomeInvalidWithError error: Error?) {
        self.sessionDelegate?.session(session,
                                      didBecomeInvalidWithError: error)
    }
    
    public func urlSession(_ session: URLSession,
                           didReceive challenge: URLAuthenticationChallenge,
                           completionHandler: @escaping @Sendable (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let sessionDelegate =  self.sessionDelegate else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        sessionDelegate.session(session,
                                didReceive: challenge,
                                completionHandler: completionHandler)
    }
}

extension SessionInterface {
    /// This default implementation of global error handler, prints out the service error.  If the error was a JSONSerializable error, a useful message if printed identifying what and where the issue is with the JSON.
    public func defaultServiceErrorHandler(_ serviceError: ServiceError) -> Void {
        var errorMessage: NSString
        
        switch serviceError.error {
            case JSONSerializableError.decodingError.keyNotFound(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.valueNotFound(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.dataCorrupted(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.typeMismatch(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.exception(let message):
                errorMessage = message as NSString
            default:
                errorMessage = "Error: \(serviceError.error.localizedDescription)" as NSString
        }
        
        
        let logId = String.randomString(length: 10)
        print("-- Hellfire service error - start - Id: \(logId) --")
        print("An error occurred for this request: \(serviceError.requestURL?.absoluteString ?? "Request URL was nil.")")
        print("")
        if let statusCode = serviceError.statusCode {
            print("HTTP StatusCode: \(statusCode)")
        }
        print("")
        print(errorMessage)
        print("")
        
        if serviceError.userCancelledRequest {
            print("Request was cancelled.")
        } else {
            var responseAsString = (serviceError.responseBody != nil) ? String(data: serviceError.responseBody!, encoding: String.Encoding.utf8) : ""
            responseAsString = ((responseAsString ?? "").isEmpty == true) ? "Response: Nothing in response body" : "Response: \(responseAsString!)"
            print(responseAsString ?? "" as Any)
        }
        print("")
        print("-- Hellfire service error - end - Id: \(logId) --")
    }
    
    public func defaultJSONSerializableErrorHandler(_ jsonError: Error) -> NSString {
        var errorMessage: NSString
        
        switch jsonError {
            case JSONSerializableError.decodingError.keyNotFound(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.valueNotFound(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.dataCorrupted(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.typeMismatch(let message):
                errorMessage = message as NSString
            case JSONSerializableError.decodingError.exception(let message):
                errorMessage = message as NSString
            default:
                errorMessage = "Error: \(jsonError.localizedDescription)" as NSString
        }
        
        return errorMessage
    }
}
