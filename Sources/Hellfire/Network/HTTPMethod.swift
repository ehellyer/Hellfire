//
//  HTTPMethod.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

/// Represents standard HTTP methods as defined in [RFC 7231](https://tools.ietf.org/html/rfc7231#section-4.3)
/// These methods indicate the desired action to be performed on a given resource in HTTP requests.
///
/// Conforms to `Hashable` and `JSONSerializable` for use in collections and JSON representations.
public enum HTTPMethod: String, Hashable, JSONSerializable {
    
    /// The `GET` method requests a representation of the specified resource.
    /// Requests using GET should only retrieve data and must not have side effects.
    case get = "GET"
    
    /// The `POST` method is used to submit data to be processed to a specified resource.
    /// Typically used for creating resources or invoking server-side operations.
    case post = "POST"
    
    /// The `PUT` method replaces all current representations of the target resource with the request payload.
    /// Commonly used for full updates of a resource.
    case put = "PUT"
    
    /// The `DELETE` method deletes the specified resource.
    case delete = "DELETE"
    
    /// The `PATCH` method is used to apply partial modifications to a resource.
    /// Unlike PUT, PATCH is not required to be idempotent.
    case patch = "PATCH"
    
    /// The `HEAD` method is identical to GET except that the server must not return a message body in the response.
    /// Often used for testing links or checking resource metadata.
    case head = "HEAD"
    
    /// The `CONNECT` method establishes a tunnel to the server identified by the target resource.
    /// Commonly used for HTTPS connections through a proxy.
    case connect = "CONNECT"
    
    /// The `TRACE` method performs a message loop-back test along the path to the target resource.
    /// Mainly used for diagnostics.
    case trace = "TRACE"
    
    /// The `OPTIONS` method describes the communication options for the target resource.
    /// Often used in CORS preflight requests.
    case options = "OPTIONS"
    
    /// Returns the method as an `NSString` compatible string for use in `URLRequest`.
    public var urlRequestMethod: String {
        return self.rawValue
    }
    
    /// Indicates whether the method is considered "safe" (does not alter server state).
    public var isSafe: Bool {
        switch self {
            case .get, .head, .options, .trace: return true
            default: return false
        }
    }
    
    /// Indicates whether the method is idempotent (can be repeated without different outcomes).
    public var isIdempotent: Bool {
        switch self {
            case .get, .put, .delete, .head, .options, .trace: return true
            default: return false
        }
    }
    
    /// Indicates whether the method typically includes a request body.
    public var hasBody: Bool {
        switch self {
            case .post, .put, .patch: return true
            default: return false
        }
    }
}
