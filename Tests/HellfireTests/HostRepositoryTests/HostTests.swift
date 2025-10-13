//
//  HostTests.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/14/25.
//

import XCTest
@testable import Hellfire

final class HostTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testFullHostPath_withPortAndPath() {
        let config = Host(protocol: .https,
                          host: "api.example.com",
                          hostPort: 8080,
                          hostPath: "v1")
        
        XCTAssertEqual(config.fullHostPath, "https://api.example.com:8080/v1/")
    }
    
    func testFullHostPath_withoutPortAndPath() {
        let config = Host(protocol: .https,
                          host: "prod.example.com")
        
        XCTAssertEqual(config.fullHostPath, "https://prod.example.com/")
    }
    
    func testEnsureTrailingSlash() {
        let config = Host(protocol: .http,
                          host: "localhost",
                          hostPath: "api")
        
        XCTAssertTrue(config.fullHostPath.hasSuffix("/"))
    }
    
    func testHashableAndEquatable_positiveMatch() {
        
        let config1 = Host(protocol: .http,
                           host: "test",
                           hostPort: 80,
                           hostPath: "api")
        
        let config2 = Host(protocol: .http,
                           host: "test",
                           hostPort: 80,
                           hostPath: "api")
        
        XCTAssertEqual(config1, config2)
        XCTAssertEqual(config1.hashValue, config2.hashValue)
    }
    
    func testHashableAndEquatable_negative_protocolMismatch() {
        let config1 = Host(protocol: .http,
                           host: "host.com")
        let config2 = Host(protocol: .https,
                           host: "host.com")
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testHashableAndEquatable_negative_hostMismatch() {
        let config1 = Host(protocol: .https,
                           host: "host1.com")
        let config2 = Host(protocol: .https,
                           host: "host2.com")
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testHashableAndEquatable_negative_portMismatch() {
        let config1 = Host(protocol: .https,
                           host: "host.com",
                           hostPort: 8080)
        let config2 = Host(protocol: .https,
                           host: "host.com",
                           hostPort: 443)
        
        XCTAssertNotEqual(config1, config2)
    }
    
    func testHashableAndEquatable_negative_pathMismatch() {
        let config1 = Host(protocol: .https,
                           host: "host.com",
                           hostPath: "v1")
        let config2 = Host(protocol: .https,
                           host: "host.com",
                           hostPath: "v2")
        
        XCTAssertNotEqual(config1, config2)
    }
}
