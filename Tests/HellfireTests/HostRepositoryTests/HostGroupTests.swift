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
    
    private func makeEnvironment(_ id: String) -> Environment {
        Environment(id: id, description: nil)
    }
    
    private func makeHost(envId: String, url: String) -> HostConfiguration {
        HostConfiguration(
            environment: makeEnvironment(envId),
            protocol: .https,
            host: url
        )
    }
    
    func testAddHostConfiguration_success() throws {
        var group = HostGroup(id: "TestGroup", hostConfigurations: [])
        let host = makeHost(envId: "dev", url: "dev.example.com")
        
        try group.add(host)
        
        XCTAssertEqual(group.host(for: makeEnvironment("dev")), host)
    }
    
    func testAddHostConfiguration_duplicateThrows() {
        let host = makeHost(envId: "dev", url: "dev.example.com")
        var group = HostGroup(id: "TestGroup", hostConfigurations: [host])
        
        XCTAssertThrowsError(try group.add(host)) { error in
            guard case HostRepositoryError.hostAlreadyExistsInGroup(let duplicate) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(duplicate, host)
        }
    }
    
    func testRemoveHostConfiguration_success() throws {
        let host = makeHost(envId: "dev", url: "dev.example.com")
        var group = HostGroup(id: "TestGroup", hostConfigurations: [host])
        
        try group.remove(host)
        
        XCTAssertNil(group.host(for: makeEnvironment("dev")))
    }
    
    func testRemoveHostConfiguration_notFoundThrows() {
        let host = makeHost(envId: "dev", url: "dev.example.com")
        var group = HostGroup(id: "TestGroup", hostConfigurations: [])
        
        XCTAssertThrowsError(try group.remove(host)) { error in
            guard case HostRepositoryError.hostNotFoundInGroup(let missing) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(missing, host)
        }
    }
    
    func testHostLookup_returnsCorrectConfiguration() {
        let devHost = makeHost(envId: "dev", url: "dev.example.com")
        let prodHost = makeHost(envId: "prod", url: "prod.example.com")
        
        let group = HostGroup(id: "TestGroup", hostConfigurations: [devHost, prodHost])
        
        XCTAssertEqual(group.host(for: makeEnvironment("prod")), prodHost)
        XCTAssertNil(group.host(for: makeEnvironment("test")))
    }
    
    func testDebugDescription_containsExpectedText() {
        let devHost = makeHost(envId: "dev", url: "dev.example.com")
        let group = HostGroup(id: "ServiceX", hostConfigurations: [devHost])
        
        let debugText = group.debugDescription
        XCTAssertTrue(debugText.contains("HostGroup ID: ServiceX"))
        XCTAssertTrue(debugText.contains(devHost.fullHostPath))
        XCTAssertTrue(debugText.contains("[dev]"))
    }
}
