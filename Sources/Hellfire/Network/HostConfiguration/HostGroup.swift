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
public struct HostGroup: Identifiable, Hashable, JSONSerializable {
    
    // MARK: - Private API
    
    /// Internal list of host configurations associated with this group.
    private var hostConfigurations: [Environment: Host] = [:]

    /// The list of environments supported by this host group.
    /// This list determines which environments are valid for host configuration.
    private var environments: [Environment]
    
    // MARK: - Public API
    
    /// Initializes a new `HostGroup` with a unique identifier and supported environments.
    ///
    /// - Parameters:
    ///   - id: The unique identifier for this host group.
    ///   - environments: The list of supported environments of the app to be used by this host group.
    public init(id: String, environments: [Environment]) {
        self.id = id
        self.environments = environments
        self.hostConfigurations = [:]
    }
    
    /// The unique identifier for this host group.
    public var id: String
    
    /// Adds a `Host` configuration for the specified `Environment`.
    ///
    /// - Parameters:
    ///   - host: The host configuration to associate with the environment.
    ///   - environment: The environment for which to associate the host.
    /// - Throws: `HostRepositoryError.invalidEnvironment` if the environment is not supported by this group.
    public mutating func add(_ host: Host, for environment: Environment) throws {
        guard environments.contains(environment) else {
            throw HostRepositoryError.invalidEnvironment(environment)
        }
        self.hostConfigurations[environment] = host
    }
    
    /// Removes the `Host` configuration associated with the specified `Environment`.
    ///
    /// - Parameter environment: The environment whose host configuration should be removed.
    /// - Throws: `HostRepositoryError.invalidEnvironment` if the environment is not supported by this group.
    public mutating func removeHost(for environment: Environment) throws {
        guard environments.contains(environment) else {
            throw HostRepositoryError.invalidEnvironment(environment)
        }
        hostConfigurations[environment] = nil
    }
    
    /// Retrieves the `Host` configuration for the specified `Environment`, if one exists.
    ///
    /// - Parameter environment: The environment whose host configuration should be retrieved.
    /// - Returns: The `Host` configuration associated with the given environment, or `nil` if none exists.
    /// - Throws: `HostRepositoryError.invalidEnvironment` if the environment is not supported by this group.
    public func host(for environment: Environment) throws -> Host?  {
        guard environments.contains(environment) else {
            throw HostRepositoryError.invalidEnvironment(environment)
        }
        return hostConfigurations[environment]
    }
    
    /// Returns a list of environments that are declared but do not yet have a host configuration.
    ///
    /// This function compares the list of declared `environments` with the set of keys
    /// in `hostConfigurations`. Any environment that is expected but does not have an
    /// associated host configuration is considered missing.
    ///
    /// - Returns: An array of `Environment` values that are missing host configurations.
    public func missingConfigurations() -> [Environment] {
        let configured = Set(self.hostConfigurations.keys)
        let missing = environments.filter { !configured.contains($0) }
        return missing
    }
}

extension HostGroup: CustomDebugStringConvertible {
    
    /// A textual representation of this `HostGroup` for debugging purposes.
    ///
    /// Includes the group's ID and a list of configured hosts for each environment.
    public var debugDescription: String {
        let configs = hostConfigurations.map { config in
            "- [\(config.key.id)]: \(config.value.fullHostPath)"
        }.joined(separator: "\n")
        
        return """
        HostGroup ID: \(id)
        HostConfigurations:
        \(configs)
        """
    }
}
