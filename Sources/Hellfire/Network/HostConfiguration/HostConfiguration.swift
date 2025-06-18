//
//  HostConfiguration.swift
//  HellFire
//
//  Created by Ed Hellyer on 5/26/25.
//  Copyright © 2025 Ed Hellyer. All rights reserved.
//

import Foundation

/// Represents the configuration details for a host in a specific environment, including protocol, host address, port, and relative path.
/// Useful for constructing fully qualified URLs in a configurable and environment-aware manner.
public struct HostConfiguration: Codable {
    
    /// Initializes a new instance of `HostConfiguration`.
    ///
    /// - Parameters:
    ///   - environment: The environment in which the host configuration is valid (e.g., development, staging, production).
    ///   - protocol: The network protocol to use (e.g., http, https).
    ///   - host: The host address (e.g., "api.example.com").
    ///   - hostPort: An optional custom port. If nil, the default for the protocol will be used.
    ///   - hostPath: An optional static path component to append to the base URL.
    public init(environment: Environment,
                `protocol`: IAPType,
                host: String,
                hostPort: Int? = nil,
                hostPath: String? = nil) {
        
        self.environment = environment
        self.protocol = `protocol`
        self.host = host
        self.hostPort = hostPort
        self.hostPath = hostPath
    }
    
    /// The environment for which this configuration is applicable.
    public var environment: Environment
    
    /// The network protocol to be used (e.g., "http", "https").
    public var `protocol`: IAPType
    
    /// The hostname or domain name (e.g., "server.domain.com").
    public var host: String
    
    /// The port number used by the host. If nil, the default port for the given protocol is assumed.
    public var hostPort: Int? = nil
    
    /// An optional path segment to be appended to the host (e.g., "api/v1").
    public var hostPath: String? = nil
    
    /// A computed property that returns the fully assembled URL string,
    /// including protocol, host, optional port, and optional host path.
    ///
    /// Example output: `https://server.domain.com:8080/api/`
    public var fullHostPath: String {
        let port = (hostPort != nil) ? ":\(hostPort!)" : ""
        let hostPath = (hostPath != nil) ? "\(ensureTrailingSlash(hostPath!))" : ""
        return "\(`protocol`)://\(host)\(port)/\(hostPath)"
    }
    
    /// Ensures that a path string has a trailing slash.
    ///
    /// - Parameter pathPart: The input path string.
    /// - Returns: The path with a trailing slash if it was not already present.
    private func ensureTrailingSlash(_ pathPart: String) -> String {
        return pathPart.hasSuffix("/") ? pathPart : pathPart + "/"
    }
}

extension HostConfiguration: Hashable {
    
    /// Hashes the essential components of the `HostConfiguration`.
    ///
    /// This enables use in sets or as dictionary keys.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(environment)
        hasher.combine(`protocol`)
        hasher.combine(host)
        hasher.combine(hostPort ?? -666)
        hasher.combine(hostPath ?? "")
    }
    
    /// Compares two `HostConfiguration` instances for equality.
    ///
    /// - Note: Equality is determined based on the computed `hashValue`.
    public static func == (lhs: HostConfiguration, rhs: HostConfiguration) -> Bool {
        return lhs.hashValue == rhs.hashValue
    }
}

extension HostConfiguration: CustomDebugStringConvertible {
    
    /// Returns a detailed string representation of the configuration for debugging purposes.
    public var debugDescription: String {
        """
        HostConfiguration(
            environment: \(environment.id),
            protocol: \(`protocol`),
            host: \(host),
            hostPort: \(hostPort.map { "\($0)" } ?? "nil"),
            hostPath: \(hostPath ?? "nil"),
            fullHostPath: \(fullHostPath)
        )
        """
    }
}
