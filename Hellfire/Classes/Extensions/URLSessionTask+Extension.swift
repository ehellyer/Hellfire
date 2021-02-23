//
//  URLSessionTask+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 2/23/21.
//

import Foundation

private var associateKey: Void?

internal extension URLSessionTask {
    var networkRequest: NetworkRequest? {
        get {
            return objc_getAssociatedObject(self, &associateKey) as? NetworkRequest
        }
        set {
            objc_setAssociatedObject(self, &associateKey, newValue, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}
