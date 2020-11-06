//
//  HTTPHeader+Extension.swift
//  Hellfire
//
//  Created by Ed Hellyer on 6/28/20.
//  Copyright © 2020 Ed Hellyer. All rights reserved.
//

/*
Header default code taken from Alamofire, because it was a really smart idea of theirs to default some of the more commonly used headers.
*/

import Foundation

extension HTTPHeader {
    /// Returns default `User-Agent` header.
    public static let defaultUserAgent: HTTPHeader = {
        let info = Bundle.main.infoDictionary
        let executable = (info?[kCFBundleExecutableKey as String] as? String) ??
            (ProcessInfo.processInfo.arguments.first?.split(separator: "/").last.map(String.init)) ?? "Unknown"
        let bundle = info?[kCFBundleIdentifierKey as String] as? String ?? "Unknown"
        let appVersion = info?["CFBundleShortVersionString"] as? String ?? "Unknown"
        let appBuild = info?[kCFBundleVersionKey as String] as? String ?? "Unknown"
        
        let osNameVersion: String = {
            let version = ProcessInfo.processInfo.operatingSystemVersion
            let versionString = "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
            let osName: String = {
                #if os(iOS)
                #if targetEnvironment(macCatalyst)
                return "macOS(Catalyst)"
                #else
                return "iOS"
                #endif
                #elseif os(watchOS)
                return "watchOS"
                #elseif os(tvOS)
                return "tvOS"
                #elseif os(macOS)
                return "macOS"
                #elseif os(Linux)
                return "Linux"
                #elseif os(Windows)
                return "Windows"
                #else
                return "Unknown"
                #endif
            }()
            
            return "\(osName) \(versionString)"
        }()
        
        let podVersion = Bundle(for: CachePolicySetting.self).infoDictionary?["CFBundleShortVersionString"] as? String  ?? "VersionUndetermined"
        let hellfireVersion = "Hellfire/\(podVersion)"
        let deviceLocale = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        let userAgent = "\(executable)/\(appVersion) (\(bundle); build:\(appBuild); \(osNameVersion); \(deviceLocale) \(hellfireVersion)"
        
        return .userAgent(userAgent)
    }()
    
    ///Returns an `Accept-Language` header.
    public static func acceptLanguage(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Accept-Language", value: value)
    }
    
    ///Returns default `Accept-Language` header, generated by querying `Locale` for the user's`preferredLanguages`.
    public static let defaultAcceptLanguage: HTTPHeader = {
        .acceptLanguage(Locale.preferredLanguages.prefix(6).qualityEncoded())
    }()
    
    ///Returns a `Content-Disposition` header.
    public static func contentDisposition(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Disposition", value: value)
    }
    
    ///Returns a `Content-Type` header with the specified string value.
    public static func contentType(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Content-Type", value: value)
    }
    
    ///Returns a `Basic` `Authorization` header using the `username` and `password` provided.
    public static func authorization(username: String, password: String) -> HTTPHeader {
        let credential = Data("\(username):\(password)".utf8).base64EncodedString()
        return authorization("Basic \(credential)")
    }
    
    ///Returns a `Bearer` `Authorization` header using the `bearerToken` provided
    public static func authorization(bearerToken: String) -> HTTPHeader {
        authorization("Bearer \(bearerToken)")
    }
    
    ///Returns an `Authorization` header.
    public static func authorization(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "Authorization", value: value)
    }
    
    ///Returns a `User-Agent` header with the specified string value.
    public static func userAgent(_ value: String) -> HTTPHeader {
        HTTPHeader(name: "User-Agent", value: value)
    }
}

extension HTTPHeader: CustomStringConvertible, CustomDebugStringConvertible {
    public var debugDescription: String {
        return "{name: \"\(self.name)\" value:\"\(self.value)\"}"
    }
    
    public var description: String {
        return self.debugDescription
    }
}
