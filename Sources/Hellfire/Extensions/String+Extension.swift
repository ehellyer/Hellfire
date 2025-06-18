//
//  String+Extension.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

extension String {
    
    //Generates a random string of length
    static func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    
    /// Removes leading and trailing whitespace characters from the string and returns the result as a new string.
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespaces)
    }
    
    /// Removes leading and trailing whitespace characters from the string then checks if the result isEmpty.  If the new string is empty a result of nil will be returned, else the trimmed string will be returned.
    func nilIfEmpty() -> String? {
        let _self = self.trim()
        return _self.isEmpty == true ? nil : _self
    }
}
