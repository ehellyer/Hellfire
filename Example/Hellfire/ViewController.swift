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
        self.fetchPosts()
        self.fetchUsers()
    }
    
    private var serviceInterface: ServiceInterface {
        let si = ServiceInterface.sharedInstance
        si.sessionDelegate = self
        return si
    }
    private lazy var webServiceResolver = WebServiceResolver()
    
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
