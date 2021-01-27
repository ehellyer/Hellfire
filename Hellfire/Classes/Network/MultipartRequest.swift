//
//  MultipartUploadRequest.swift
//  Hellfire
//
//  Created by Ed Hellyer on 1/14/21.
//

import Foundation

public class MultipartRequest: NetworkRequest {
    
    public init(url: URL,
                method: HTTPMethod,
                multipartFormData: MultipartFormData) {
        self.multipartFormData = multipartFormData
        self.fileManager = multipartFormData.fileManager
        super.init(url: url,
                   method: method,
                   contentType: multipartFormData.contentType.value)
    }
    
    public var multipartFormData: MultipartFormData
    
    public func build() throws -> (request: URLRequest, fileURL: URL) {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = self.method.name
        urlRequest.setValue(self.multipartFormData.contentType.value, forHTTPHeaderField: self.multipartFormData.contentType.name)
        urlRequest.setValue("\(self.multipartFormData.contentLength)", forHTTPHeaderField: "Content-Length")
        
        let tempDirectoryURL = fileManager.temporaryDirectory
        let directoryURL = tempDirectoryURL.appendingPathComponent("hellfire/multipart.form.data")
        let fileName = "MultipartFormDataRequest\(String.randomString(length: 10)).txt"
        let fileURL = directoryURL.appendingPathComponent(fileName)
        
        try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
        
        do {
            try multipartFormData.writeEncodedData(to: fileURL)
        } catch {
            // Cleanup after attempted write if it fails.
            try? fileManager.removeItem(at: fileURL)
            throw error
        }
        
//        self.inputStream = InputStream(url: fileURL)
//        urlRequest.httpBodyStream = self.inputStream
        
        return (request: urlRequest, fileURL: fileURL)
    }
    
    private let fileManager: FileManager
//    private var inputStream: InputStream?
}



