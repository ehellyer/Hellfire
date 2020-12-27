//
//  ServiceConfig.swift
//  Hellfire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

struct ServiceConfig {
    var services: [ServiceHost] = [ServiceHost(environment: .customHost,
                                                procol: "https",
                                                host: "127.0.0.1",
                                                hostPort: 5000),
                                    ServiceHost(environment: .developmentMainExternal,
                                                procol: "https",
                                                host: "jsonplaceholder.typicode.com"),
                                    ServiceHost(environment: .developmentReleExternal,
                                                procol: "https",
                                                host: "jsonplaceholder.typicode.com"),
                                    ServiceHost(environment: .testMainExternal,
                                                procol: "https",
                                                host: "jsonplaceholder.typicode.com"),
                                    ServiceHost(environment: .testReleExternal,
                                                procol: "https",
                                                host: "jsonplaceholder.typicode.com"),
                                    ServiceHost(environment: .productionExternal,
                                                procol: "https",
                                                host: "jsonplaceholder.typicode.com")]
}

//https://itunes.apple.com/search?media=music&entity=song&term=cohen
