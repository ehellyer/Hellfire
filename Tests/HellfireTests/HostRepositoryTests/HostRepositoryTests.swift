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
        Environment(id: id,
                    description: id.capitalized)
    }
    
    private func makeHost(url: String) -> Hellfire.Host {
        Hellfire.Host(protocol: .https,
                      host: url)
    }
    
    private func makeGroup(id: String, environments: [Environment]) -> HostGroup {
        HostGroup(id: id, environments: environments)
    }
    
    func testAddHostGroup_success() throws {
        
        let env = makeEnvironment("dev")
        var repo = HostRepository(environments: [env])
        let host = makeHost(url: "dev.com")
        var group = makeGroup(id: "ServiceA",
                              environments: [env])
        try group.add(host, for: env)
        try repo.add(hostGroup: group)
        
        let result = try repo.resolveHost(in: "ServiceA", for: env)
        XCTAssertEqual(result.host, "dev.com")
    }
    
    func testAddHostGroup_duplicateThrows() throws {
        let env = makeEnvironment("dev")
        var repo = HostRepository(environments: [env])
        let host = makeHost(url: "dev.com")
        var group = makeGroup(id: "ServiceA",
                              environments: repo.environments)
        try group.add(host, for: env)
        try repo.add(hostGroup: group)

        XCTAssertThrowsError(try repo.add(hostGroup: group)) { error in
            guard case HostRepositoryError.hostGroupAlreadyExists(let existing) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(existing.id, group.id)
        }
    }
    
    func testResolveHost_returnsCorrectHost() throws {
        
        let devEnv = makeEnvironment("dev")
        let prdEnv = makeEnvironment("prd")
        let devHost = makeHost(url: "dev.example.com")
        let prdHost = makeHost(url: "prod.example.com")
        var repo = HostRepository(environments: [devEnv, prdEnv])
        var group = makeGroup(id: "ServiceA",
                              environments: repo.environments)
        try group.add(devHost, for: devEnv)
        try group.add(prdHost, for: prdEnv)
        try repo.add(hostGroup: group)

        
        let resolved = try repo.resolveHost(in: "ServiceA", for: prdEnv)
        XCTAssertEqual(resolved.host, "prod.example.com")
    }
    
    func testResolveHost_groupNotFoundThrows() {
        
        let devEnv = makeEnvironment("dev")
        let repo = HostRepository(environments: [devEnv])
        XCTAssertThrowsError(try repo.resolveHost(in: "FakeGroup", for: devEnv)) { error in
            guard case HostRepositoryError.groupNotFound(let name) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(name, "FakeGroup")
        }
    }
    
    func testResolveHost_environmentNotFoundThrows() {
        let devEnv = makeEnvironment("dev")
        let prdEnv = makeEnvironment("prd")
        let devHost = makeHost(url: "dev.example.com")
        var repo = HostRepository(environments: [devEnv])
        var group = makeGroup(id: "ServiceA",
                              environments: repo.environments)
        try? group.add(devHost, for: devEnv)
        try? repo.add(hostGroup: group)
        
        XCTAssertThrowsError(try repo.resolveHost(in: "ServiceA", for: prdEnv)) { error in
            guard case HostRepositoryError.invalidEnvironment(let env) = error else {
                return XCTFail("Unexpected error: \(error)")
            }
            XCTAssertEqual(env, prdEnv)
        }
    }
}
