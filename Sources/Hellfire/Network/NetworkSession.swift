//
//  NetworkSession.swift
//  Hellfire
//
//  Created by Ed Hellyer on 12/27/24.
//

import Foundation

public typealias UserAuthCompletion = (StatusCode?, Error?) -> Void

public struct Credentials {
    let username: String
    let password: String
}

public protocol NetworkSessionManager {
    func authenticate(credentials: Credentials,
                      url: URL
    ) async throws -> UserAuthCompletion
}

