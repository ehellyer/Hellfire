//
//  TheTests.swift
//  Hellfire_Tests
//
//  Created by Ed Hellyer on 9/16/19.
//  Copyright © 2019 CocoaPods. All rights reserved.
//

import Hellfire
import XCTest

class TheTests: BaseTestCase {
    

    func testMultipartFormDataUpload() {
        //Build the request
//        let url = URL(string: "https://httpbin.org/post")!
//        let fileURL = self.url(forResource: "Murphy", withExtension: "jpg")
//
//        let mpfd = MultipartFormData()
//        mpfd.append("This is a comment".data(using: .utf8)!, withName: "Metadata.AttachmentComment")
//        mpfd.append("\(9)".data(using: .utf8)!, withName: "Metadata.AttachmentSource") //9 - LoopNet
//        mpfd.append("\(4)".data(using: .utf8)!, withName: "Metadata.AttachmentType") //4 - BuildingPhoto
//        mpfd.append("\(6)".data(using: .utf8)!, withName: "Metadata.AttachmentTypeExtension") //6 - JPG
//        mpfd.append(true.description.data(using: .utf8)!, withName: "Metadata.IsPublished")
//        mpfd.append(true.description.data(using: .utf8)!, withName: "Metadata.IsMarketingPublished")
//        mpfd.append("\(3910450)".data(using: .utf8)!, withName: "Metadata.OriginiatedByContactId")
//        mpfd.append("\(800)".data(using: .utf8)!, withName: "Metadata.ImageWidthInPixels")
//        mpfd.append("\(600)".data(using: .utf8)!, withName: "Metadata.ImageHeightInPixels")
//        mpfd.append(fileURL, withName: "File")
//        let request = MultipartRequest(url: url, method: .post, multipartFormData: mpfd)
//
//        guard let urlRequest = try? request.build() else {
//            XCTFail()
//            return
//        }
//
        
//        //Make the call
//        let _ = self.serviceInterface.execute(request) { (result) in
//            switch result {
//            case .failure(let serviceError):
//                print("Service error occured \(serviceError.error?.localizedDescription ?? "No error description")")
//            case .success(let dataResponse):
//                if let t = [Post].initialize(jsonData: dataResponse.body) {
//                    print("Item Count: \(t.count)")
//                    print(t[0])
//                }
//            }
//        }
    }


    //Mark: - Service Tests
    func testSerializerPerson() {
        let jsonStr = """
        {
        "first_Name": "Edward",
        "last_Name": "Hellyer",
        "a_fantastic_person": true
        }
        """
        let jsonData = Data(jsonStr.utf8)
        if let person = Person.initialize(jsonData: jsonData) {
            print(person.firstName)
            print(person.lastName)
            print("Is this person awesome? \(person.isAwesome ? "Yes" : "Not so much")")
            if let personJSONStr = person.toJSONString() {
                print(personJSONStr as NSString)
            }
        }
        
        XCTAssertEqual("Hello, World!", "Hello, World!")
    }
    
//    func testSerializerBirthday1() {
//        let jsonStr = """
//        {
//        "birthdate": "1975-03-21"
//        }
//        """
//        let jsonData = Data(jsonStr.utf8)
//        let bday = Birthday.initialize(jsonData: jsonData)
//
//        XCTAssert(bday != nil, "Date string was not recognized.")
//    }
//
//    func testSerializerBirthday2() {
//        let jsonStr = """
//        {
//        "birthdate": "2004-03-09"
//        }
//        """
//        let jsonData = Data(jsonStr.utf8)
//        let bday = Birthday.initialize(jsonData: jsonData)
//
//        XCTAssert(bday != nil, "Date string was not recognized.")
//    }
}
