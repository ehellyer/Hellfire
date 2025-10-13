//
//  HostGroupTests.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/14/25.
//

import XCTest
@testable import Hellfire

final class HostGroupTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private let dev = Environment(id: "dev")
    private let test = Environment(id: "test")
    private let prod = Environment(id: "prod")
    
    private var devHost: Hellfire.Host {
        Hellfire.Host(protocol: .https, host: "dev.api.com")
    }
    
    private var prodHost: Hellfire.Host {
        Hellfire.Host(protocol: .https, host: "api.com")
    }
    
    func testInitSetsIdAndEnvironments() throws {
        let group = HostGroup(id: "DataService", environments: [dev, test])
        XCTAssertEqual(group.id, "DataService")
    }
    
    func testMissingConfigurations() throws {
        let host = Hellfire.Host(protocol: .https, host: "dev.api.com")
        var group = HostGroup(id: "DataService", environments: [dev, test])
        try group.add(host, for: dev)
        XCTAssertEqual(group.missingConfigurations(), [test])
    }
    
    func testAddHostSucceedsWhenEnvironmentIsValid() throws {
        var group = HostGroup(id: "DataService", environments: [dev, test])
        try group.add(devHost, for: dev)
        
        let retrievedHost = try group.host(for: dev)
        XCTAssertEqual(retrievedHost, devHost)
    }
    
    func testAddHostThrowsOnInvalidEnvironment() {
        var group = HostGroup(id: "DataService", environments: [test])
        XCTAssertThrowsError(try group.add(devHost, for: dev)) { error in
            guard case HostRepositoryError.invalidEnvironment(let env) = error else {
                return XCTFail("Expected invalidEnvironment error")
            }
            XCTAssertEqual(env, dev)
        }
    }
    
    func testHostReturnsNilWhenNotSet() throws {
        let group = HostGroup(id: "DataService", environments: [dev])
        let host = try group.host(for: dev)
        XCTAssertNil(host)
    }
    
    func testHostThrowsOnInvalidEnvironment() {
        let group = HostGroup(id: "DataService", environments: [dev])
        XCTAssertThrowsError(try group.host(for: prod)) { error in
            guard case HostRepositoryError.invalidEnvironment(let env) = error else {
                return XCTFail("Expected invalidEnvironment error")
            }
            XCTAssertEqual(env, prod)
        }
    }
    
    func testRemoveHostClearsHostForEnvironment() throws {
        var group = HostGroup(id: "DataService", environments: [dev])
        try group.add(devHost, for: dev)
        try group.removeHost(for: dev)
        
        let host = try group.host(for: dev)
        XCTAssertNil(host)
    }
    
    func testRemoveHostThrowsOnInvalidEnvironment() {
        var group = HostGroup(id: "DataService", environments: [dev])
        XCTAssertThrowsError(try group.removeHost(for: test)) { error in
            guard case HostRepositoryError.invalidEnvironment(let env) = error else {
                return XCTFail("Expected invalidEnvironment error")
            }
            XCTAssertEqual(env, test)
        }
    }
    
    func testDebugDescriptionIncludesIdAndHostPaths() throws {
        var group = HostGroup(id: "DataService", environments: [dev])
        try group.add(devHost, for: dev)
        
        let debugOutput = group.debugDescription
        XCTAssertTrue(debugOutput.contains("HostGroup ID: DataService"))
        XCTAssertTrue(debugOutput.contains(devHost.fullHostPath))
    }
}
