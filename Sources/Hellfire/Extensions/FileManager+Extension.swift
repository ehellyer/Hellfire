//
//  FileManager+Extension.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

protocol FileManaging {
    
    /// Creates a directory if it doesn't already exist.
    func createDirectoryIfNeeded(at path: URL) throws

    /// Creates the file at the specified path with the contents.
    func createFile(at path: URL, contents: Data) throws

    /// Removes the item at the specified path.
    func removeItem(at path: URL) throws
    
    /// Checks if a file exists at the specified path.
    func fileExists(at path: URL) -> Bool
    
    /// Returns the contents of a directory filtered by file extension.
    func contentsOfDirectory(at path: URL, withExtension: String) -> [URL]
    
    /// Returns the attributes of a file at a given path.
    func attributesOfItem(at path: URL) -> [FileAttributeKey: Any]?
}


extension FileManager: FileManaging {
       
    func createDirectoryIfNeeded(at url: URL) throws {
        if !self.fileExists(at: url) {
            try self.createDirectory(atPath: url.path, withIntermediateDirectories: true, attributes: nil)
        }
    }

    func createFile(at path: URL, contents: Data) throws {
        guard createFile(atPath: path.path, contents: contents, attributes: nil) else {
            throw NSError(domain: "FileManager+Extension", code: 1, userInfo: nil)
        }
    }
    
    func removeItem(at url: URL) throws {
        try self.removeItem(atPath: url.path)
    }
    
    func fileExists(at path: URL) -> Bool {
        var isPathValid = false
        isPathValid = self.fileExists(atPath: path.path)
        return isPathValid
    }
    
    ///Returns the contents of the specified directory, will ignore hidden files, sub directories and package contents.  Response includes .fileSizeKey and .createdDate properties.
    func contentsOfDirectory(at path: URL, withExtension fileExtension: String) -> [URL] {
        let propertyKeys: [URLResourceKey] = [.creationDateKey,
                                              .fileSizeKey]

        let options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants,
                                                                .skipsHiddenFiles,
                                                                .skipsPackageDescendants]
        
        guard let contents = try? contentsOfDirectory(at: path, includingPropertiesForKeys: propertyKeys, options: options) else {
            return []
        }
        
        return contents.filter { $0.pathExtension == fileExtension }
    }
    
    func attributesOfItem(at path: URL) -> [FileAttributeKey : Any]? {
        return try? attributesOfItem(atPath: path.path)
    }
}
