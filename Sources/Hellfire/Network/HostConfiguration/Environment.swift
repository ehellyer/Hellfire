//
//  Environment.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

import Foundation

/// Represents a logical environment (e.g., development, staging, production) used within the application context.
/// Conforms to `Identifiable` for use in SwiftUI and `Hashable` for collection operations.
public struct Environment: Identifiable, JSONSerializable, Hashable {
    
    /// Initializes a new instance of `Environment`
    /// - Parameters:
    ///   - id: A unique name for the environment.  The name should be unique to the host group.
    ///   - description: A descriptive name of the environment.
    public init(id: String, description: String? = nil) {
        self.id = id
        self.description = description
    }
    
    /// The unique identifier for the environment.  e.g. DevMain, TestMain, TestRelease, Production.
    public var id: String
    
    /// The description of the environment.
    public var description: String?
    
    /// A presentation name.  Returns description by default or id if description is nil.
    public var displayName: String {
        description?.nilIfEmpty() ?? id
    }
}
