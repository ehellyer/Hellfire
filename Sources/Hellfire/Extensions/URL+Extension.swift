//
//  URL+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 7/15/25.
//

import Foundation

extension URL: @retroactive ExpressibleByStringLiteral {
    
    /// Initializes a `URL` instance from a string literal.
    ///
    /// This initializer allows a `URL` to be created using string literal syntax:
    ///
    /// ```swift
    /// let website: URL = "https://www.example.com"
    /// ```
    ///
    /// The use of `StaticString` ensures that only string literals (known at compile time) can be used,
    /// which helps avoid runtime errors from invalid or dynamically constructed URLs.
    ///
    /// Because the string is known at design time and assumed to be a valid URL,
    /// the initializer force-unwraps the result of `URL(string:)`. If the string is not a valid URL,
    /// it will trigger a runtime crash.
    ///
    /// - Parameter value: A string literal representing a valid URL.
    public init(stringLiteral value: StaticString) {
        self.init(string: value.description)!
    }
}

