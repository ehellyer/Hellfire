//
//  DiskCacheStoreTests.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/16/25.
//

import XCTest
@testable import Hellfire

final class DiskCacheStoreTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func makeRequest(policy: CachePolicyType = .day, url: String = "https://example.com", body: String? = nil) -> NetworkRequest {
        let data = body?.data(using: .utf8)
        return NetworkRequest(url: URL(string: url)!, method: .get, cachePolicyType: policy, body: data)
    }
    
    func testStoreAndLoadData_succeeds() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DiskCacheStore(rootPath: tempDir)
        
        let request = makeRequest()
        let expectedData = "Test Data".data(using: .utf8)!
        
        store.store(expectedData, for: request)
        let result = store.load(for: request)
        
        XCTAssertEqual(result, expectedData)
    }
    
//    func testLoadExpiredData_returnsNil() {
//        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
//        let policyType = CachePolicyType.hour
//        let store = DiskCacheStore(rootPath: tempDir)
//        
//        let request = makeRequest(policy: policyType)
//        let testData = "Old Data".data(using: .utf8)!
//        store.store(testData, for: request)
//        
//        let fileURL = tempDir
//            .appendingPathComponent(policyType.folderName)
//            .appendingPathComponent("\(store.generateKey(for: request)).dkc")
//        
//        let oldDate = Date(timeIntervalSinceNow: -Double(policyType.ttlInSeconds) - 10)
//        try? FileManager.default.setAttributes([.creationDate: oldDate], ofItemAtPath: fileURL.path)
//        
//        let result = store.load(for: request)
//        XCTAssertNil(result)
//    }
    
    func testClearPolicy_removesDataOnlyForThatPolicy() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DiskCacheStore(rootPath: tempDir)
        
        let dayRequest = makeRequest(policy: .day)
        let weekRequest = makeRequest(policy: .week)
        let testData = "Some Data".data(using: .utf8)!
        
        store.store(testData, for: dayRequest)
        store.store(testData, for: weekRequest)
        
        store.clear(for: .day)
        
        XCTAssertNil(store.load(for: dayRequest))
        XCTAssertEqual(store.load(for: weekRequest), testData)
    }
    
    func testClearAll_removesAllData() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DiskCacheStore(rootPath: tempDir)
        
        let request1 = makeRequest(policy: .hour)
        let request2 = makeRequest(policy: .month)
        let testData = "All gone".data(using: .utf8)!
        
        store.store(testData, for: request1)
        store.store(testData, for: request2)
        
        store.clearAll()
        
        XCTAssertNil(store.load(for: request1))
        XCTAssertNil(store.load(for: request2))
    }
    
    func testStoreWithDoNotCachePolicy_doesNothing() {
        let tempDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let store = DiskCacheStore(rootPath: tempDir)
        
        let request = makeRequest(policy: .doNotCache)
        let testData = "Should not store".data(using: .utf8)!
        
        store.store(testData, for: request)
        let result = store.load(for: request)
        
        XCTAssertNil(result)
    }
        
    func stressTestDiskCache() {
        let config = DiskCacheConfiguration(policyMaxByteSize: [CachePolicyType.hour: 1000,
                                                                .fourHours: 1000,
                                                                .day: 1000,
                                                                .week: 1000,
                                                                .month: 1000,
                                                                .untilSpaceNeeded: 1000])
        
        let processInfo = ProcessInfo.processInfo
        let appName = processInfo.processName
        var cacheURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.cachesDirectory,
                                                in: FileManager.SearchPathDomainMask.userDomainMask).first!
        cacheURL.append(component: "HellfireDiskCache")
        cacheURL.append(component: "TestApp_\(appName)")
        
        let dc = DiskCacheStore(rootPath: cacheURL, configuration: config)
        dc.clearAll()
        
        for i in 10000000...10006000 {
            autoreleasepool {
                let data = "\(i)".data(using: .utf8)!
                let request1 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .hour, body: data)
                let request2 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .day, body: data)
                let request3 = NetworkRequest(url: URL(string: "https://www.apple.com/\(i)")!, method: .get, cachePolicyType: .week, body: data)
                let _ = dc.store(data, for: request1)
                let _ = dc.store(data, for: request2)
                let _ = dc.store(data, for: request3)
            }
        }
    }
    
}
