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
                multipartFormData: MultipartFormData,
                isInBackgroundSession: Bool) {
        self.multipartFormData = multipartFormData
        self.fileManager = multipartFormData.fileManager
        self.isInBackgroundSession = isInBackgroundSession
        super.init(url: url, method: method)
    }
    
    public var multipartFormData: MultipartFormData
    
    public func build() throws -> URLRequest {
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = method.name
        urlRequest.setValue(multipartFormData.contentType.value, forHTTPHeaderField: multipartFormData.contentType.name)
        
        if multipartFormData.contentLength < encodingMemoryThreshold && !isInBackgroundSession {
            let data = try multipartFormData.encode()
            urlRequest.httpBody = data
        } else {
            let tempDirectoryURL = fileManager.temporaryDirectory
            let directoryURL = tempDirectoryURL.appendingPathComponent("hellfire/multipart.form.data")
            let fileName = UUID().uuidString
            let fileURL = directoryURL.appendingPathComponent(fileName)
            
            try fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true, attributes: nil)
            
            do {
                try multipartFormData.writeEncodedData(to: fileURL)
            } catch {
                // Cleanup after attempted write if it fails.
                try? fileManager.removeItem(at: fileURL)
                throw error
            }
            
            //TODO: - EJH - Need to setup the file and stream parts of URLRequest.
        }
        
        return urlRequest
    }
    
    private let encodingMemoryThreshold: UInt64 = 10_000_000
    private let isInBackgroundSession: Bool
    private let fileManager: FileManager
}



