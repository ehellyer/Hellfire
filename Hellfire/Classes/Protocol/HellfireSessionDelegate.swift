//
//  HellfireSessionDelegate.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

/// A protocol this is implemented optionally by the `ServiceInterface` delegate.
public protocol HellfireSessionDelegate: class {
    
    /// Asks delegate to return all the additional headers required for the `NetworkRequest`
    /// - Note: Duplicate headers returned in this call will override those that were set by the `ServiceInterface` based on the `NetworkRequest` parameters and defaults.
    /// - Parameter dataRequest: The `NetworkRequest` that initiated this delegate call.
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]?
    
    /// A  optional global way of telling the delegate the returned response headers for a given request.
    /// - Note: Response headers are also incuded in the `NetworkResponse` of a successfull `NetworkRequest`
    /// - Parameters:
    ///   - headers: An array of headers returned in the response.
    ///   - forRequest: The `NetworkRequest` that initiated this response.
    func responseHeaders(headers: [HTTPHeader], forRequest: NetworkRequest)
    
    /// Tells the delegate that the background `URLSessionUploadTask` finished transferring data in the background.
    /// - Parameter result: Represents the success or failure result of a `NetworkRequest`.
    func backgroundTaskDidComplete(result: RequestResult?)
}

//Empty private protocol extension to make protocol methods optional for the delegate.
public extension HellfireSessionDelegate {
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]? { return nil }
    func responseHeaders(headers: [HTTPHeader], forRequest: NetworkRequest) {}
    func backgroundTaskDidComplete(result: RequestResult?) {}
}
