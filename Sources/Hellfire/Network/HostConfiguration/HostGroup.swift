//
//  HostGroup.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

import Foundation

/// A `HostGroup` represents a logical grouping of host configurations across multiple environments.
/// Each group contains the same logical host (e.g., a service endpoint), but with different settings per environment (e.g., dev, test, production).
///
/// For example, a `HostGroup` for a "DataService" might contain host configurations for dev (`https://dev.api.com`), test (`https://test.api.com`), and production (`https://api.com`).
public struct HostGroup: Identifiable, Hashable {
    
    // MARK: - Private API
    
    /// Internal list of host configurations associated with this group.
    private var hostConfigurations: [HostConfiguration] = []
    
    // MARK: - Public API
    
    /// Initializes a new `HostGroup` with the specified ID and an initial list of host configurations.
    ///
    /// - Parameters:
    ///   - id: A unique string identifier for the group (e.g., "DataService").
    ///   - hostConfigurations: An array of `HostConfiguration` entries for the group.
    public init(id: String, hostConfigurations: [HostConfiguration]) {
        self.id = id
        self.hostConfigurations = hostConfigurations
    }
    
    /// The unique identifier for this host group.
    public var id: String
    
    /// Adds a new host configuration to the group.
    ///
    /// - Parameter host: The `HostConfiguration` to add.
    /// - Throws: `HostRepositoryError.hostAlreadyExistsInGroup` if the host configuration already exists in the group.
    public mutating func add(_ host: HostConfiguration) throws {
        if hostConfigurations.contains(host) {
            throw HostRepositoryError.hostAlreadyExistsInGroup(host)
        }
        self.hostConfigurations.append(host)
    }
    
    /// Removes an existing host configuration from the group.
    ///
    /// - Parameter host: The `HostConfiguration` to remove.
    /// - Throws: `HostRepositoryError.hostNotFoundInGroup` if the host configuration is not found in the group.
    public mutating func remove(_ host: HostConfiguration) throws {
        if !hostConfigurations.contains(host) {
            throw HostRepositoryError.hostNotFoundInGroup(host)
        }
        self.hostConfigurations.removeAll { $0 == host }
    }
    
    /// Retrieves the host configuration for the specified environment, if one exists.
    ///
    /// - Parameter environment: The environment to match against (e.g., development, test, production).
    /// - Returns: The matching `HostConfiguration` or `nil` if not found.
    public func host(for environment: Environment) -> HostConfiguration? {
        hostConfigurations.first { $0.environment == environment }
    }
}

extension HostGroup: CustomDebugStringConvertible {
    
    /// Returns a debug description of the host group, including its ID and configurations.
    public var debugDescription: String {
        let configs = hostConfigurations.map { config in
            "- [\(config.environment.id)]: \(config.fullHostPath)"
        }.joined(separator: "\n")
        
        return """
        HostGroup ID: \(id)
        HostConfigurations:
        \(configs)
        """
    }
}
