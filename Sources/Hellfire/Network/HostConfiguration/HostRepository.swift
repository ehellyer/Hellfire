//
//  HostRepository.swift
//  Hellfire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

/// A repository that manages a collection of `HostGroup`s, allowing resolution of host configurations across multiple environments.
/// Useful for managing service endpoints in development, staging, and production.
public struct HostRepository {
    
    /// Initializes a new `HostRepository` with an optional list of `HostGroup`s.
    ///
    /// - Parameter hostGroups: The initial list of host groups to populate the repository.
    public init(hostGroups: [HostGroup] = []) {
        self.hostGroups = hostGroups
    }
    
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
    ///   - environment: The environment for which the host is needed (e.g., dev, test, prod).
    ///   - groupName: The identifier of the host group.
    /// - Returns: The resolved `HostConfiguration`.
    /// - Throws: `HostRepositoryError.groupNotFound` if the group or environment is not found.
    public func resolveHost(in environment: Environment, for groupName: String) throws -> HostConfiguration {
        guard let host = hostGroups.first(where: { $0.id == groupName })?.host(for: environment) else {
            throw HostRepositoryError.groupNotFound(groupName)
        }
        return host
    }
}

/// Defines errors that can occur when interacting with a `HostRepository`.
public enum HostRepositoryError: Swift.Error {
    
    /// The specified group was not found in the repository.
    case groupNotFound(String)
    
    /// The specified host configuration already exists within a group.
    case hostAlreadyExistsInGroup(HostConfiguration)
    
    /// The specified host configuration could not be found in a group.
    case hostNotFoundInGroup(HostConfiguration)
    
    /// The specified host group already exists in the repository.
    case hostGroupAlreadyExists(HostGroup)
}
