//
//  HostRepositoryTests.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/14/25.
//

import XCTest
@testable import Hellfire

final class HostRepositoryTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    private func makeEnvironment(_ id: String) -> Environment {
        Environment(id: id, description: id.capitalized)
    }
    
    private func makeHost(envId: String, url: String) -> HostConfiguration {
        HostConfiguration(
            environment: makeEnvironment(envId),
            protocol: .https,
            host: url
        )
    }
    
    private func makeGroup(id: String, hosts: [HostConfiguration]) -> HostGroup {
        HostGroup(id: id, hostConfigurations: hosts)
    }
    
    func testAddHostGroup_success() throws {
        var repo = HostRepository()
        let group = makeGroup(id: "ServiceA", hosts: [makeHost(envId: "dev", url: "dev.com")])
        
        try repo.add(hostGroup: group)
        
        let result = try repo.resolveHost(in: makeEnvironment("dev"), for: "ServiceA")
        XCTAssertEqual(result.host, "dev.com")
    }
    
    func testAddHostGroup_duplicateThrows() {
        let group = makeGroup(id: "ServiceA", hosts: [makeHost(envId: "dev", url: "dev.com")])
        var repo = HostRepository(hostGroups: [group])
        
        XCTAssertThrowsError(try repo.add(hostGroup: group)) { error in
            guard case HostRepositoryError.hostGroupAlreadyExists(let existing) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(existing.id, group.id)
        }
    }
    
    func testResolveHost_returnsCorrectHost() throws {
        let devHost = makeHost(envId: "dev", url: "dev.com")
        let prodHost = makeHost(envId: "prod", url: "prod.com")
        let group = makeGroup(id: "ServiceA", hosts: [devHost, prodHost])
        let repo = HostRepository(hostGroups: [group])
        
        let resolved = try repo.resolveHost(in: makeEnvironment("prod"), for: "ServiceA")
        XCTAssertEqual(resolved.host, "prod.com")
    }
    
    func testResolveHost_groupNotFoundThrows() {
        let repo = HostRepository()
        
        XCTAssertThrowsError(try repo.resolveHost(in: makeEnvironment("dev"), for: "UnknownGroup")) { error in
            guard case HostRepositoryError.groupNotFound(let name) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(name, "UnknownGroup")
        }
    }
    
    func testResolveHost_environmentNotFoundThrows() {
        let devHost = makeHost(envId: "dev", url: "dev.com")
        let group = makeGroup(id: "ServiceA", hosts: [devHost])
        let repo = HostRepository(hostGroups: [group])
        
        XCTAssertThrowsError(try repo.resolveHost(in: makeEnvironment("prod"), for: "ServiceA")) { error in
            guard case HostRepositoryError.groupNotFound(let name) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(name, "ServiceA")
        }
    }
}
