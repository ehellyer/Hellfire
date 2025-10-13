//
//  HostRepository.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

/// A repository that manages a collection of `HostGroup`s, allowing resolution of host configurations across multiple environments.
/// Useful for managing service endpoints in development, staging, and production.
public struct HostRepository: JSONSerializable {
    
    public init(environments: [Environment]) {
        self.environments = environments
        self.hostGroups = []
    }
    
    public private(set) var environments: [Environment]
    
    /// Internal collection of host groups.
    private var hostGroups: [HostGroup]
    
    /// Adds a new host group to the repository.
    ///
    /// - Parameter hostGroup: The `HostGroup` to be added.
    /// - Throws: `HostRepositoryError.hostGroupAlreadyExists` if the group already exists.
    public mutating func add(hostGroup: HostGroup) throws {
        if hostGroups.contains(hostGroup) {
            throw HostRepositoryError.hostGroupAlreadyExists(hostGroup)
        }
        self.hostGroups.append(hostGroup)
    }
    
    /// Resolves the `HostConfiguration` for a given group name and environment.
    ///
    /// - Parameters:
    ///   - hostGroupId: The identifier of the host group.
    ///   - environment: The environment for which the host is needed (e.g., dev, test, prod).
    /// - Returns: The resolved `HostConfiguration`.
    /// - Throws: `HostRepositoryError.groupNotFound` if the group or environment is not found.
    public func resolveHost(in hostGroupId: String, for environment: Environment) throws -> Host {
        guard let hostGroup = hostGroups.first(where: { $0.id == hostGroupId }) else {
            throw HostRepositoryError.groupNotFound(hostGroupId)
        }
        
        guard let host = try hostGroup.host(for: environment) else {
            throw HostRepositoryError.invalidEnvironment(environment)
        }
        
        return host
    }
    
    /// Returns a list of host group identifiers
    /// - Returns: An array of identifiers used to identify registered host group configurations.
    public func listHostGroupIds() -> [String] {
        return hostGroups.map { $0.id }
    }
}

/// Defines errors that can occur when interacting with a `HostRepository`.
public enum HostRepositoryError: Swift.Error {
    
    /// The specified group was not found in the repository.
    case groupNotFound(String)
    
    /// An invalid `Environment` was passed as a parameter.
    case invalidEnvironment(Environment)
    
    /// The specified host configuration already exists within a group.
    case hostAlreadyExistsInGroup(Host)
    
    /// The specified host configuration could not be found in a group.
    case hostNotFoundInGroup(Host)
    
    /// The specified host group already exists in the repository.
    case hostGroupAlreadyExists(HostGroup)
}
