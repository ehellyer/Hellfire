//
//  RequestItem.swift
//  Hellfire
//
//  Created by Ed Hellyer on 2/23/21.
//

import Foundation

/// This object is associated with the URLSessionTask so that the application can identify the task.
internal struct RequestItem: JSONSerializable {
    
    init(requestIdentifier: RequestTaskIdentifier,
         taskIdentifier: Int,
         streamBodyURL: URL? = nil,
         requestDate: Date = Date()) {
        
        self.requestIdentifier = requestIdentifier
        self.taskIdentifier = taskIdentifier
        self.streamBodyURL = streamBodyURL
        self.requestDate = requestDate
    }
    
    let requestIdentifier: RequestTaskIdentifier
    
    let taskIdentifier: Int
    
    let streamBodyURL: URL?
    
    let requestDate: Date
}
