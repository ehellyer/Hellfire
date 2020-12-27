//
//  RequestCollection.swift
//  HellFire
//
//  Created by Ed Hellyer on 2/12/19.
//  Copyright © 2019 Ed Hellyer. All rights reserved.
//

import Foundation

internal class RequestCollection {

    //MARK: - Class setup
    
    init() {
        let queueLabel = "ThreadSafeMessageQueue." + String.randomString(length: 12)
        self.serialMessageQueue = DispatchQueue(label: queueLabel)
    }

    //MARK: - Private API

    //Queue used to ensure synchronous access to the 'requests' collection and the index 'taskIndex'
    private var serialMessageQueue: DispatchQueue

    //Type definition of Task and Request.
    private typealias TaskRequestPair = (task: URLSessionTask, request: URLRequest)
    
    //Collection of concurrent requests in call
    private var requests = [URLRequest: URLSessionTask]()
    
    //Index of the tasks
    private var taskIndex = [RequestTaskIdentifier: TaskRequestPair]()
    
    //MARK: - Internal API
    
    internal func removeTask(forRequest request: URLRequest) {
        self.serialMessageQueue.sync {
            if let key = self.requests.removeValue(forKey: request) {
                let _ = self.taskIndex.removeValue(forKey: key.taskIdentifier)
                key.cancel()
            }
        }
    }

    internal func removeRequest(forTaskIdentifier taskIdentifier: RequestTaskIdentifier) {
        self.serialMessageQueue.sync {
            if let key = self.taskIndex.removeValue(forKey: taskIdentifier) {
                let request = self.requests.removeValue(forKey: key.request)
                request?.cancel()
            }
        }
    }
    
    internal func add(request: URLRequest, task: URLSessionTask) {
        self.serialMessageQueue.sync {
            let _ = self.requests.updateValue(task, forKey: request)
            let _ = self.taskIndex.updateValue((task, request), forKey: task.taskIdentifier)
        }
    }
    
    internal func allTasks() -> [RequestTaskIdentifier] {
        let taskIdentifiers = self.taskIndex.compactMap { $0.key }
        return taskIdentifiers
    }
    
    internal func task(forTaskIdentifier taskIdentifier: RequestTaskIdentifier) -> URLRequest? {
        self.serialMessageQueue.sync {
            return self.taskIndex[taskIdentifier]?.request
        }
    }
}
