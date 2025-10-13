//
//  String+Extension.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

extension String {
    
    /// Generates a random alphanumeric string of the specified length.
    ///
    /// Characters are chosen uniformly at random from the set:
    /// `[a–z][A–Z][0–9]`.
    ///
    /// Example:
    /// ```swift
    /// let token = String.randomString(length: 12)
    /// print(token)
    /// // "aZ8nB31fQx2R"
    /// ```
    ///
    /// - Parameter length: The number of characters to generate.
    /// - Returns: A new string containing random alphanumeric characters.
    static func randomString(length: Int) -> String {
        precondition(length > 0, "Length must be greater than zero.")
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).compactMap { _ in letters.randomElement() })
    }
    
    /// Returns a copy of the string with leading and trailing whitespace
    /// and newline characters removed.
    ///
    /// Example:
    /// ```swift
    /// "  Hello\n".trim()
    /// // returns "Hello"
    /// ```
    ///
    /// - Returns: A new string trimmed of whitespace and newline characters.
    ///   The result may be an empty string if the receiver contained only
    ///   whitespace or newline characters.
    func trim() -> String {
        return self.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
    }
    
    /// Returns `nil` if the string is empty after trimming whitespace
    /// and newline characters; otherwise returns the trimmed string.
    ///
    /// Example:
    /// ```swift
    /// "  ".nilIfEmpty()
    /// // returns nil
    ///
    /// " hello ".nilIfEmpty()
    /// // returns "hello"
    /// ```
    ///
    /// - Returns: The trimmed string, or `nil` if it is empty after trimming.
    func nilIfEmpty() -> String? {
        let trimmed = self.trim()
        return trimmed.isEmpty ? nil : trimmed
    }
}
