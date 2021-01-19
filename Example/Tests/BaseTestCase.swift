//
//  BaseTestCase.swift
//  Hellfire_Tests
//
//  Created by Ed Hellyer on 1/18/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import Foundation
import XCTest
import Hellfire

class BaseTestCase: XCTestCase {
    var serviceInterface: ServiceInterface {
        let si = ServiceInterface.sharedInstance
        return si
    }
    
    func url(forResource fileName: String, withExtension ext: String) -> URL {
        let bundle = Bundle(for: BaseTestCase.self)
        return bundle.url(forResource: fileName, withExtension: ext)!
    }
        
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
}
