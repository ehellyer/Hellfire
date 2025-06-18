//
//  SessionInterfaceTests.swift
//  
//
//  Created by Ed Hellyer on 1/6/24.
//

import XCTest
@testable import Hellfire

final class SessionInterfaceTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testDataTask() throws {
        let expectation = self.expectation(description: "Waiting for network call to complete.")
        
        let interface = SessionInterface.sharedInstance
        let request = NetworkRequest(url: URL(string: "https://api.escuelajs.co/api/v1/products")!, method: .get)
        let _ = try interface.execute(request) { (result) in
            switch result {
                case .success(let dataResponse):
                    print(NSString(data: dataResponse.body!, encoding: 4)!)
                case .failure(let serviceError):
                    XCTFail(serviceError.localizedDescription)
            }
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }
    
    func testJSONTask() throws {
        let expectation = self.expectation(description: "Waiting for network call to complete.")
        
        let interface = SessionInterface.sharedInstance
        let request = NetworkRequest(url: URL(string: "https://api.escuelajs.co/api/v1/products")!, method: .get, timeoutInterval: 2)
        let _ = try interface.execute(request) { (result: JSONSerializableResult<[ProductElement]>) in
            switch result {
                case .success(let dataResponse):
                    print(dataResponse.jsonObject)
                case .failure(let serviceError):
                    XCTFail(serviceError.localizedDescription)
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10)
    }

    
    func testMultipartFormDataTask() throws {
        let expectation = self.expectation(description: "Waiting for network call to complete.")
        
        guard let dogImageURL = Bundle.module.url(forResource: "Dog", withExtension: "jpeg") else {
            XCTFail("Failed to build URL for Dog.jpeg from module bundle.")
            return
        }
        
        let interface = SessionInterface.sharedInstance
        interface.sessionDelegate = self
        
        let multipartFormData = MultipartFormData()
        multipartFormData.append(dogImageURL, withName: "fileData", fileName: "Dog.jpeg", mimeType: "image/jpeg")
        multipartFormData.append(UUID().uuidString.data(using: .utf8)!, withName: "userId")
        multipartFormData.append("This is a Hellfire test firing".data(using: .utf8)!, withName: "caption")
        
        let multipartRequest = MultipartRequest(url: URL(string: "http://127.0.0.1:8089/api/attachment/upload")!,
                                             method: .post,
                                             multipartFormData: multipartFormData)
        
        let _ = try interface.executeUpload(multipartRequest)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 19) {
            expectation.fulfill()
        }
        
        
        waitForExpectations(timeout: 20)
    }
    
    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }
}

extension SessionInterfaceTests: HellfireSessionDelegate {
    func headerCollection(forRequest request: NetworkRequest) -> [HTTPHeader]? {
        return nil
    }
    
    func responseHeaders(headers: [HTTPHeader],
                         forRequest request: NetworkRequest) {
        print(headers)
    }
    
    func session(_ session: URLSession,
                 didBecomeInvalidWithError error: Error?) {
        if let error {
            print("Error: \(error)")
        }
    }
    
    func session(_ session: URLSession,
                 dataTask: URLSessionDataTask,
                 didReceive data: Data) {
        print("Background session did receive data")
    }
    
    func backgroundTask(_ task: URLSessionTask,
                        didCompleteWithResult result: RequestResult) {
        print("Completed background tasks")
    }
    
    func backgroundTask(_ task: URLSessionTask,
                        didSendBytes bytesSent: Int64,
                        totalBytesSent: Int64,
                        totalBytesExpectedToSend: Int64) {
        print("Bytes sent: \(bytesSent), total bytes sent: \(totalBytesSent), total bytes expected: \(totalBytesExpectedToSend)")
    }
    
    func backgroundSessionDidFinishEvents(session: URLSession) {
        print("Completed background tasks")
    }
}
