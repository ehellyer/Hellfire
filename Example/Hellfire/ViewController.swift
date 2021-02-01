//
//  ViewController.swift
//  Hellfire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import UIKit
import Hellfire

class ViewController: UIViewController {

    @IBAction func executeButton_TouchUp(_ sender: UIButton) {
//        self.fetchPosts()
//        self.fetchUsers()
        self.uploadImage()
    }
    
    private var serviceInterface: ServiceInterface {
        let si = ServiceInterface.sharedInstance
        si.sessionDelegate = self
        return si
    }
    private lazy var webServiceResolver = WebServiceResolver()

    private func url(forResource fileName: String, withExtension ext: String) -> URL {
        let bundle = Bundle(for: ViewController.self)
        return bundle.url(forResource: fileName, withExtension: ext)!
    }
    
    private func uploadImage() {
        //Build the request
        let url = URL(string: "https://httpbin.org/post")!
        let fileURL = self.url(forResource: "Murphy", withExtension: "jpg")
        
        let mpfd = MultipartFormData()
        mpfd.append("This is a comment".data(using: .utf8)!, withName: "Metadata.AttachmentComment")
        mpfd.append("\(9)".data(using: .utf8)!, withName: "Metadata.AttachmentSource") //9 - LoopNet
        mpfd.append("\(4)".data(using: .utf8)!, withName: "Metadata.AttachmentType") //4 - BuildingPhoto
        mpfd.append("\(6)".data(using: .utf8)!, withName: "Metadata.AttachmentTypeExtension") //6 - JPG
        mpfd.append(true.description.data(using: .utf8)!, withName: "Metadata.IsPublished")
        mpfd.append(true.description.data(using: .utf8)!, withName: "Metadata.IsMarketingPublished")
        mpfd.append("\(3910450)".data(using: .utf8)!, withName: "Metadata.OriginiatedByContactId")
        mpfd.append("\(800)".data(using: .utf8)!, withName: "Metadata.ImageWidthInPixels")
        mpfd.append("\(600)".data(using: .utf8)!, withName: "Metadata.ImageHeightInPixels")
        mpfd.append(fileURL, withName: "File")
        let request = MultipartRequest(url: url, method: .post, multipartFormData: mpfd)
        _ = self.serviceInterface.executeUpload(request)
        
    }
    
    private func fetchPosts() {

        //Build the request
        let route = ServiceRoutes.JSONPlaceholder.comments
        let url = self.webServiceResolver.url(forRoute: route)
        let request = NetworkRequest(url: url, method: .get)
        
        //Make the call
        let _ = self.serviceInterface.execute(request) { (result) in
            switch result {
            case .failure(let serviceError):
                print("Service error occured \(serviceError.error?.localizedDescription ?? "No error description")")
            case .success(let dataResponse):
                if let t = [Post].initialize(jsonData: dataResponse.body) {
                    print("Item Count: \(t.count)")
                    print(t[0])
                }
            }
        }
    }

    private func fetchUsers() {
        
        //Build the request
        let route = ServiceRoutes.JSONPlaceholder.users
        let url = self.webServiceResolver.url(forRoute: route)
        let request = NetworkRequest(url: url, method: .get)
        
        //Make the call
        let _ = self.serviceInterface.execute(request) { (result) in
            switch result {
            case .failure(let serviceError):
                print("Service error occured \(serviceError.error?.localizedDescription ?? "No error description")")
            case .success(let dataResponse):
                if let t = [User].initialize(jsonData: dataResponse.body) {
                    print("Item Count: \(t.count)")
                    print(t[0])
                }
            }
        }
    }
}

extension ViewController: HellfireSessionDelegate {
    
    func headerCollection(forRequest dataRequest: NetworkRequest) -> [HTTPHeader]? {
        let headers = [HTTPHeader.defaultAcceptLanguage]
        return headers
    }
    
}
