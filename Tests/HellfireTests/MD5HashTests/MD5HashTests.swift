//
//  MD5HashTests.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/16/25.
//

import XCTest
@testable import Hellfire

final class MD5HashTests: XCTestCase {
    
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testMD5Hash_KnownValues() {
        let hasher = MD5Hash()
        
        let testCases: [(input: String, expected: String)] = [
            ("", "D41D8CD98F00B204E9800998ECF8427E"),
            ("a", "0CC175B9C0F1B6A831C399E269772661"),
            ("abc", "900150983CD24FB0D6963F7D28E17F72"),
            ("message digest", "F96B697D7CB7938D525A2F31AAF161D0"),
            ("abcdefghijklmnopqrstuvwxyz", "C3FCD3D76192E4007DFB496CCA67E13B"),
            ("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789", "D174AB98D277D9F5A5611C2C9F419D9F"),
            ("12345678901234567890123456789012345678901234567890123456789012345678901234567890", "57EDF4A22BE3C955AC49DA2E2107B67A")
        ]
        
        for testCase in testCases {
            let result = hasher.MD5(testCase.input)
            XCTAssertEqual(result.uppercased(), testCase.expected, "Failed for input: \(testCase.input)")
        }
    }
    
    func testMD5Hash_DifferentInputsProduceDifferentHashes() {
        let hasher = MD5Hash()
        let hash1 = hasher.MD5("input one")
        let hash2 = hasher.MD5("input two")
        
        XCTAssertNotEqual(hash1, hash2)
    }
    
    func testMD5Hash_SameInputConsistentOutput() {
        let hasher = MD5Hash()
        let input = "consistency test"
        let hash1 = hasher.MD5(input)
        let hash2 = hasher.MD5(input)
        
        XCTAssertEqual(hash1, hash2)
    }
}
