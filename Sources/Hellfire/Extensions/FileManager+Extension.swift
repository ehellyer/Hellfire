//
//  FileManager+Extension.swift
//  HellFire
//
//  Created by Ed Hellyer on 11/01/17.
//  Copyright © 2017 Ed Hellyer. All rights reserved.
//

import Foundation

internal extension FileManager {
    
    ///Creates the directory path tree, returns true for success and false for failure.
    func createWithIntermediateDirectories(path: URL) throws {
        try self.createDirectory(atPath: path.path, withIntermediateDirectories: true, attributes: nil)
    }
    
    ///Returns true if the directory or file specified by the url exists else returns false.
    func pathExists(path: URL) -> Bool {
        var isPathValid = false
        isPathValid = self.fileExists(atPath: path.path)
        return isPathValid
    }
    
    func createDirectoryIfNeeded(at url: URL) throws {
        if !self.pathExists(path: url) {
            try self.createWithIntermediateDirectories(path: url)
        }
    }
    
    ///Returns the contents of the specified directory, will ignore hidden files, sub directories and package contents.  Response includes .fileSizeKey and .createdDate properties.
    class func contentsOfDirectory(path: URL, withFileExtension fileExtension: String = "") -> [URL]? {
        var filteredContents: [URL]? = nil
        let propertyKeys: [URLResourceKey] = [.creationDateKey,
                                              .fileSizeKey]
        let options: FileManager.DirectoryEnumerationOptions = [.skipsSubdirectoryDescendants,
                                                                .skipsHiddenFiles,
                                                                .skipsPackageDescendants]
        let directoryContents = try? FileManager.default.contentsOfDirectory(at: path,
                                                                             includingPropertiesForKeys: propertyKeys,
                                                                             options: options)
        filteredContents = fileExtension.isEmpty ? directoryContents : directoryContents?.filter { $0.pathExtension == fileExtension }
        return filteredContents
    }
}
