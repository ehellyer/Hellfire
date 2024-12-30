//
//  Clients.swift
//  Hellfire
//
//  Created by Ed Hellyer on 12/27/24.
//

import Foundation
import Combine

protocol HTTPClient {
    func publisher<T>(request: URLRequest, decodingType: T.Type) -> AnyPublisher<(T, HTTPURLResponse), Error> where T: JSONSerializable
}

protocol SocketClient {
    func publisher(request: URLRequest) -> AnyPublisher<URLResponse, Error>
}

protocol FileClient {
    func publisher(request: URLRequest) -> AnyPublisher<Data, Error>
}


