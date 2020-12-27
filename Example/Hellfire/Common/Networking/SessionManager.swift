//
//  SessionManager.swift
//  Hellfire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import UIKit
import Hellfire

//MARK: - Public Types

class SessionManager {

    //MARK: - SessionManager Overrides
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
    }
    
    init() {
        self.registerNotificationObservers()
    }

    //MARK: - Private API
    
    private func registerNotificationObservers() {

    }
}

extension SessionManager: HellfireSessionDelegate {

    //Set the appropriate headers for dataRequest here.
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]? {
        
        var headers: [HTTPHeader] = []
        
        //Add content-type header.
        headers.append(HTTPHeader(name: "Content-Type", value: dataRequest.contentType))
        
        return headers
    }
    
    func responseHeaders(headers: [HTTPHeader], forRequest: NetworkRequest) {
        //This demo parent app does nothing here... yet.
    }
}
