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
public struct Environment: Identifiable, Codable, Hashable {
    
    /// The unique identifier for the environment.  e.g. DevMain, TestMain, TestRelease, Production.
    public var id: String
    
    /// The description of the environment.
    public var description: String?
    
    public var displayName: String {
        description?.nilIfEmpty() ?? id
    }
}
