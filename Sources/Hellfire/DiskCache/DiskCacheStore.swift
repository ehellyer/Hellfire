//
//  DiskCache.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

/// A protocol defining a generic cache interface for storing, retrieving, and clearing cached data.
protocol CacheStore {
    /// Stores the given data for a specified request.
    func store(_ data: Data?, for request: NetworkRequest)
    
    /// Loads cached data for a specified request.
    func load(for request: NetworkRequest) -> Data?
    
    /// Clears cache data for a specific policy type.
    func clear(for policyType: CachePolicyType)
    
    /// Clears all cached data across all policy types.
    func clearAll()
}


// MARK: - DiskCacheStore

/// A concrete implementation of `CacheStore` that stores data on disk using time-based and size-based cache policies.
final class DiskCacheStore: CacheStore {
    
    deinit {
#if DEBUG
        print("\(String(describing: type(of: self))) has deallocated. - \(#function)")
#endif
    }
    
    init(rootPath: URL,
         fileManager: FileManaging = FileManager.default,
         hasher: MD5Hash = MD5Hash(),
         configuration: DiskCacheConfiguration = DiskCacheConfiguration(policyMaxByteSize: CachePolicyType.defaultByteSizes)) {
        
        self.rootPath = rootPath
        self.fileManager = fileManager
        self.hasher = hasher
        self.configuration = configuration
        
        self.diskCacheEnabled = self.initializeCacheSettings(config: configuration)
        self.updateCurrentByteSizeForAllPolicies()
        
#if DEBUG
        print("DiskCache root path: \(self.rootPath.path)")
#endif
    }
    
    //MARK: - Private API
    
    private let fileManager: FileManaging
    private let rootPath: URL
    private let hasher: MD5Hash
    private let configuration: DiskCacheConfiguration
    private var policies: [CachePolicyType: CachePolicy] = [:]
    private let accessQueue = DispatchQueue(label: "DiskCacheStore.Serial")
    private let fileExtension = "dkc"
    private lazy var cachePolicies = CachePolicies(cacheRootPath: self.rootPath)
    private var diskCacheEnabled = true
    private var activePolicyTrimming = Set<CachePolicyType>()
    private var cacheTrimConcurrentQueue = DispatchQueue(label: "DiskCache_ConcurrentTrimCacheQueue",
                                                         qos: DispatchQoS.userInitiated,
                                                         attributes: .concurrent)
    private var serialAccessQueue = DispatchQueue(label: "DiskCache_SerialAccessQueue")
    
    private func getBytesUsed(forPolicy policy: CachePolicy) -> UInt64 {
        self.serialAccessQueue.sync {
            return policy.bytesUsed
        }
    }
    
    private func incrementBytesUsed(forPolicy policy: CachePolicy, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            policy.bytesUsed += bytes
            return policy.bytesUsed
        }
    }
    
    private func decrementBytesUsed(forPolicy policy: CachePolicy, bytes: UInt64) -> UInt64 {
        self.serialAccessQueue.sync {
            let result = policy.bytesUsed - bytes
            policy.bytesUsed = max(0, result)
            return policy.bytesUsed
        }
    }
    
    private func setBytesUsed(_ bytes: UInt64, forPolicy policy: CachePolicy) {
        self.serialAccessQueue.sync {
            policy.bytesUsed = bytes
        }
    }
    
    private func isTrimmingPolicyType(_ policyType: CachePolicyType) -> Bool {
        self.serialAccessQueue.sync {
            return self.activePolicyTrimming.contains(policyType)
        }
    }
    
    private func insertTrimmingPolicyType(_ policyType: CachePolicyType) {
        self.serialAccessQueue.sync {
            _ = self.activePolicyTrimming.insert(policyType)
        }
    }
    
    private func removeTrimmingPolicyType(_ policyType: CachePolicyType) {
        self.serialAccessQueue.sync {
            _ = self.activePolicyTrimming.remove(policyType)
        }
    }
    
    private func initializeCacheSettings(config: DiskCacheConfiguration) -> Bool {
        var success = true
        for policy in self.cachePolicies.allPolicies() {
            policy.maxByteSize = config.policyMaxByteSize[policy.policyType] ?? 0
            success = self.createFolder(forPolicy: policy)
            if (success == false) { break }
        }
        return success
    }
    
    private func createFolder(forPolicy policy: CachePolicy) -> Bool {
        guard policy.policyType != .doNotCache else {
            return true
        }
        var pathCreated = true
        if (self.fileManager.fileExists(at: policy.cacheFolder) == false) {
            do {
                try self.fileManager.createDirectoryIfNeeded(at: policy.cacheFolder)
            } catch {
                pathCreated = false
            }
        }
        return pathCreated
    }
    
    private func updateCurrentByteSizeForAllPolicies() {
        guard self.diskCacheEnabled else { return }
        for policy in self.cachePolicies.allPolicies() {
            var fileDiskBytesUsed: UInt64 = 0
            let directoryContents = self.fileManager.contentsOfDirectory(at: policy.cacheFolder,
                                                                         withExtension: self.fileExtension)
            for fileUrl in directoryContents {
                if let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]),
                   let fileSize = fileAttributes.fileSize {
                    let fileSizeU64 = UInt64(fileSize)
                    fileDiskBytesUsed += fileSizeU64
                }
            }
            
            self.setBytesUsed(fileDiskBytesUsed, forPolicy: policy)
        }
    }
    
    private func doesCachedItem(atPath filePath: URL, violateTTLFor policy: CachePolicy) -> Bool {
        var doesViolateTTL = false
        if let attributes = self.fileManager.attributesOfItem(at: filePath),
           let fileCreatedDate = attributes[FileAttributeKey.creationDate] as? Date {
            let timeInterval = fileCreatedDate.timeIntervalSinceNow
            if (fabs(timeInterval) > TimeInterval(policy.ttlInSeconds)) {
                doesViolateTTL = true
                try? self.fileManager.removeItem(at: filePath)
            }
        }
        return doesViolateTTL
    }
    
    private func flushCacheFor(policy: CachePolicy) -> Bool {
        var success = false
        try? self.fileManager.removeItem(at: policy.cacheFolder)
        success = self.createFolder(forPolicy: policy)
        return success
    }
    
    private func flushCache() -> Bool {
        var success = true
        for policy in self.cachePolicies.allPolicies() {
            success = self.flushCacheFor(policy: policy)
            if (!success) { break }
        }
        return success
    }
    
    private func key(forRequest request: NetworkRequest) -> String {
        var httpBody = ""
        if let bodyData = request.body {
            httpBody = String(data: bodyData, encoding: .utf8) ?? ""
        }
        let url = request.url.absoluteString
        let languageIdentifier = NSLocale.current.identifier
        let requestString = url + httpBody + languageIdentifier
        let requestKey = self.hasher.MD5(requestString)
        return requestKey
    }
    
    private func trimCache(forPolicy policy: CachePolicy) {
        self.cacheTrimConcurrentQueue.async { [weak self] in
            guard let self else { return }
            
            let targetBytes = UInt64(Double(policy.maxByteSize) * 0.75)
            if targetBytes > self.getBytesUsed(forPolicy: policy) || self.isTrimmingPolicyType(policy.policyType) {
                return
            }
            
            self.insertTrimmingPolicyType(policy.policyType)
            
            let directoryContents = self.fileManager.contentsOfDirectory(at: policy.cacheFolder,
                                                                         withExtension: self.fileExtension)
            //Sort oldest files first in the array.
            var sortedDirectoryContents: [URL] = (
                try? directoryContents.sorted(by: { (lhs, rhs) -> Bool in
                    let lhsCreationDate = try lhs.resourceValues(forKeys: [.creationDateKey]).creationDate
                    let rhsCreationDate = try rhs.resourceValues(forKeys: [.creationDateKey]).creationDate
                    return self.isDate(lhsCreationDate, before: rhsCreationDate)
                })
            ) ?? []
            
            //Remove files until we are within targetBytes
            while sortedDirectoryContents.isEmpty == false && (targetBytes < self.getBytesUsed(forPolicy: policy)) {
                let fileManager = self.fileManager
                autoreleasepool {
                    if let fileUrl = sortedDirectoryContents.first,
                       let fileAttributes = try? fileUrl.resourceValues(forKeys: [.fileSizeKey]),
                       let fileSize = fileAttributes.fileSize {
                        let fileSizeU64 = UInt64(fileSize)
                        try? fileManager.removeItem(at: fileUrl)
                        _ = self.decrementBytesUsed(forPolicy: policy, bytes: fileSizeU64)
                    }
                    sortedDirectoryContents.removeFirst()
                }
            }
            
            self.removeTrimmingPolicyType(policy.policyType)
        }
    }
    
    
    private func isDate(_ lhs: Date?, before rhs: Date?) -> Bool {
        guard let lhs, let rhs else { return true }
        return lhs < rhs
    }
    
    //MARK: - Internal API
    
    /// Stores the data on disk for the request using the specified cache policy
    /// - Parameters:
    ///   - data: The data to be cached on disk.  If nil, this function does nothing and returns early.
    ///   - request: The network request that requested the data to be cached.  The requests cache policy effect how the caching works.  If the cache policy is do not cache, then this function returns early.
    func store(_ data: Data?,
               for request: NetworkRequest) {
        
        guard self.diskCacheEnabled,
              let data,
              data.isEmpty == false,
              request.cachePolicyType != CachePolicyType.doNotCache else {
            return
        }
        
        let policy = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        guard requestKey.isEmpty == false else { return }
        
        //Queue up trimming if not already in process for this cache policy type.
        if self.isTrimmingPolicyType(policy.policyType) == false {
            self.trimCache(forPolicy: policy)
        }
        
        //Save the data
        let fileName = requestKey + "." + self.fileExtension
        let cachePath = policy.cacheFolder.appendingPathComponent(fileName)
        if (self.fileManager.fileExists(at: policy.cacheFolder) == false) {
            try? self.fileManager.createDirectoryIfNeeded(at: policy.cacheFolder)
        }
        if (self.fileManager.fileExists(at: cachePath)) {
            try? self.fileManager.removeItem(at: cachePath)
        }
        try? self.fileManager.createFile(at: cachePath, contents: data)
        
        //Update bytes used.
        let fileSize = UInt64(data.count)
        _ = self.incrementBytesUsed(forPolicy: policy, bytes: fileSize)
    }
    
    /// Returns the data for the request.
    func load(for request: NetworkRequest) -> Data? {
        guard self.diskCacheEnabled, request.cachePolicyType != CachePolicyType.doNotCache else { return nil }
        
        let policy = self.cachePolicies.policy(forType: request.cachePolicyType)
        let requestKey = self.key(forRequest: request)
        guard requestKey.isEmpty == false else { return nil }
        
        let fileName = requestKey + "." + self.fileExtension
        let cachePath = policy.cacheFolder.appendingPathComponent(fileName)
        var data: Data? = nil
        if (self.fileManager.fileExists(at: cachePath) && self.doesCachedItem(atPath: cachePath, violateTTLFor: policy) == false) {
            data = try? Data.init(contentsOf: cachePath)
        }
        return data
    }
    
    /// Clear the cache for a specific cache policy.
    func clear(for policyType: CachePolicyType) {
        let policy = self.cachePolicies.policy(forType: policyType)
        let _ = self.flushCacheFor(policy: policy)
        self.updateCurrentByteSizeForAllPolicies()
    }
    
    /// Clear all cache from disk.
    func clearAll() {
        let _ = self.flushCache()
        self.updateCurrentByteSizeForAllPolicies()
    }
}

// MARK: - Supporting Types

/// Configuration structure defining the maximum byte size allowed per cache policy.
struct DiskCacheConfiguration {
    
    init(policyMaxByteSize: [CachePolicyType: UInt64] = CachePolicyType.defaultByteSizes) {
        self.policyMaxByteSize = policyMaxByteSize
    }
    
    let policyMaxByteSize: [CachePolicyType: UInt64]
}

/// Enumeration of supported cache policy types, each with a TTL and directory name.
public enum CachePolicyType: CaseIterable {
    case hour
    case fourHours
    case day
    case week
    case month
    case untilSpaceNeeded
    case doNotCache
    
    /// Returns the TTL in seconds for each policy type.
    var ttlInSeconds: UInt32 {
        switch self {
            case .hour: return 3600
            case .fourHours: return 14400
            case .day: return 86400
            case .week: return 604800
            case .month: return 2721600
            case .untilSpaceNeeded: return 32659200
            case .doNotCache: return 0
        }
    }
    
    /// Returns the folder name associated with the cache policy type.
    var folderName: String {
        switch self {
            case .hour: return "HourCache"
            case .fourHours: return "FourHourCache"
            case .day: return "DayCache"
            case .week: return "WeekCache"
            case .month: return "MonthCache"
            case .untilSpaceNeeded: return "UntilSpaceNeeded"
            case .doNotCache: return "DoNotCache"
        }
    }
    
    /// Returns the default maximum byte sizes for all cache policy types.
    static var defaultByteSizes: [CachePolicyType: UInt64] {
        return [
            .hour: 50 * 1024 * 1024,                    // 50 MB
            .fourHours: 100 * 1024 * 1024,              // 100 MB
            .day: 250 * 1024 * 1024,                    // 250 MB
            .week: 500 * 1024 * 1024,                   // 500 MB
            .month: 1024 * 1024 * 1024,                 // 1 GB
            .untilSpaceNeeded: 1024 * 1024 * 1024       // 1 GB
        ]
    }
}

/// Represents a single cache policy with its associated TTL and storage directory.
class CachePolicy {
    
    init(policyType: CachePolicyType, cacheRootPath: URL) {
        self.policyType = policyType
        self.bytesUsed = 0
        self.maxByteSize = 0 //Configured later
        self.cacheFolder = cacheRootPath.appendingPathComponent(self.policyType.folderName)
        self.ttlInSeconds = self.policyType.ttlInSeconds
    }
    
    let policyType: CachePolicyType
    var bytesUsed: UInt64
    var maxByteSize: UInt64
    let cacheFolder: URL
    let ttlInSeconds: UInt32
}

extension CachePolicy: Hashable {
    static func == (lhs: CachePolicy, rhs: CachePolicy) -> Bool {
        return lhs.policyType == rhs.policyType
    }
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(self.policyType)
    }
}

class CachePolicies {
    
    init(cacheRootPath: URL) {
        self.policies = CachePolicyType.allCases.reduce(into: [CachePolicyType: CachePolicy]()) {
            $0[$1] = CachePolicy.init(policyType: $1, cacheRootPath: cacheRootPath)
        }
    }
    
    private var policies: [CachePolicyType: CachePolicy]
    
    func policy(forType policyType: CachePolicyType) -> CachePolicy {
        let setting = self.policies[policyType]
        return setting!
    }
    
    func allPolicies() -> [CachePolicy] {
        return Array(self.policies.values)
    }
}
