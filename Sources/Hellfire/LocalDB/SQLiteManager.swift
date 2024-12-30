//
//  SQLiteManager.swift
//  Hellfire
//
//  Created by Ed Hellyer on 12/27/24.
//

import Foundation
import SQLite3

internal enum SQLiteError: Error {
    case openDatabase(message: String)
    case prepareStatement(message: String)
    case execution(message: String)
    case bind(message: String)
    case createTable(message: String)
    case databaseNotOpen
}

internal class SQLiteManager {
    
    //MARK: - SQLiteManager lifecycle
    
    deinit {
        self.closeDatabase()
    }
    
    init() {
        let appName = ProcessInfo.processInfo.processName
        let rootPath = FileManager.default.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first!.absoluteURL.appendingPathComponent(appName)
        
        var path = rootPath.appendingPathComponent("HellfireMetaData")
        path.appendPathExtension("sqlite")
        do {
            try self.fileManager.createDirectoryIfNeeded(at: rootPath)
            try self.openDatabase(at: path)
            try self.initializeDataBase()
        } catch {
            fatalError("Unable to create Hellfire metadata database: \(error)")
        }
    }

    //MARK: - Private API
    
    private var dbHandle: OpaquePointer?
    private let requestItemTableName = "RequestItem"
    private let requestItemColumnNames: [String] = ["requestIdentifier", "taskIdentifier", "streamBodyURL", "requestDate"]
    private var fileManager: FileManager = FileManager.default
    private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
    
    /// Creates the schema if not exists
    private func initializeDataBase() throws {
        guard self.dbHandle != nil else {
            throw SQLiteError.databaseNotOpen
        }
        
        let createTableSQL = """
            CREATE TABLE IF NOT EXISTS \(requestItemTableName) (
                \(requestItemColumnNames[0]) TEXT PRIMARY KEY,
                \(requestItemColumnNames[1]) INTEGER NOT NULL,
                \(requestItemColumnNames[2]) TEXT,
                \(requestItemColumnNames[3]) REAL
            );
        """
        
        do {
            try self.execute(sqlStatement: createTableSQL)
        } catch {
            throw SQLiteError.createTable(message: "Failed to create table [\(requestItemTableName)]: \(error)")
        }
    }
    
    /// Retrieves the last error message from the SQLite database.
    private var errorMessage: String {
        if let db = self.dbHandle, let errorPointer = sqlite3_errmsg(db) {
            return String(cString: errorPointer)
        } else {
            return "No error message available."
        }
    }


    /// Opens (or creates) an SQLite database at the specified path.
    /// - Parameter path: File path to the database.
    private func openDatabase(at fileURL: URL) throws {
        if sqlite3_open(fileURL.path, &self.dbHandle) != SQLITE_OK {
            defer { sqlite3_close(self.dbHandle) }
            throw SQLiteError.openDatabase(message: errorMessage)
        }
        //print("Successfully opened connection to database at \(fileURL.path).")
    }
    
    /// Executes a SQL statement.
    /// - Parameter sqlStatement: The SQL statement to execute.
    private func execute(sqlStatement: String) throws {
        guard let db = self.dbHandle else {
            throw SQLiteError.databaseNotOpen
        }
        
        var _stmtHandle: OpaquePointer?
        if sqlite3_prepare_v2(db, sqlStatement, -1, &_stmtHandle, nil) != SQLITE_OK {
            throw SQLiteError.prepareStatement(message: errorMessage)
        }
        defer { sqlite3_finalize(_stmtHandle) }
        
        if sqlite3_step(_stmtHandle) != SQLITE_DONE {
            throw SQLiteError.execution(message: errorMessage)
        }
        //print("Successfully executed statement: \(sqlStatement)")
    }
    
    /// Closes the database connection.
    private func closeDatabase() {
        if let _db = self.dbHandle {
            sqlite3_close(_db)
            self.dbHandle = nil
            //print("Database connection closed.")
        }
    }

    private func parameterize(for parameter: String) -> String {
        var modifiedParameter = parameter
        if !modifiedParameter.hasPrefix(":") {
            modifiedParameter =  ":\(modifiedParameter)"
        }
        return modifiedParameter
    }
    
    private func index(for parameter: String, stmtHandle: OpaquePointer?) throws -> Int32 {
        let modifiedParameter = self.parameterize(for: parameter)
        let idx = sqlite3_bind_parameter_index(stmtHandle, modifiedParameter)
        guard idx > 0 else {
            throw SQLiteError.bind(message: "Parameter \(modifiedParameter) not found.")
        }
        return idx
    }
    
    private func bind(_ value: Binding?, paramIdx: Int32, stmtHandle: OpaquePointer?) throws {
        switch value {
            case .none:
                sqlite3_bind_null(stmtHandle, paramIdx)
            case let value as Blob where value.bytes.count == 0:
                sqlite3_bind_zeroblob(stmtHandle, paramIdx, 0)
            case let value as Blob:
                sqlite3_bind_blob(stmtHandle, paramIdx, value.bytes, Int32(value.bytes.count), SQLITE_TRANSIENT)
            case let value as Double:
                sqlite3_bind_double(stmtHandle, paramIdx, value)
            case let value as Int64:
                sqlite3_bind_int64(stmtHandle, paramIdx, value)
            case let value as String:
                sqlite3_bind_text(stmtHandle, paramIdx, value, -1, SQLITE_TRANSIENT)
            case let value as Int:
                try self.bind(value.datatypeValue, paramIdx: paramIdx, stmtHandle: stmtHandle)
            case let value as Bool:
                try self.bind(value.datatypeValue, paramIdx: paramIdx, stmtHandle: stmtHandle)
            case .some(let value):
                throw SQLiteError.bind(message: "Failed to bind \(value)")
        }
    }
    
    func getSQLString(from statement: OpaquePointer?) -> String? {
        guard let statement = statement else {
            return nil
        }
        
        // Get the expanded SQL string
        if let cString = sqlite3_expanded_sql(statement) {
            let sqlString = String(cString: cString)
            sqlite3_free(cString) // Free the memory allocated by sqlite3_expanded_sql
            return sqlString
        }
        
        return nil
    }
    
    //MARK: - Internal API
    
    func insert(requestItem: RequestItem) throws {
        guard let db = self.dbHandle else {
            throw SQLiteError.databaseNotOpen
        }
        
        let insertSQL = """
        INSERT INTO \(requestItemTableName) (
        \(requestItemColumnNames[0]), 
        \(requestItemColumnNames[1]), 
        \(requestItemColumnNames[2]), 
        \(requestItemColumnNames[3])
        )
        VALUES (
        \(self.parameterize(for: requestItemColumnNames[0])),
        \(self.parameterize(for: requestItemColumnNames[1])), 
        \(self.parameterize(for: requestItemColumnNames[2])), 
        \(self.parameterize(for: requestItemColumnNames[3]))
        );
        """
        
        // Prepare the statement
        var stmtHandle: OpaquePointer?
        guard sqlite3_prepare_v2(db, insertSQL, -1, &stmtHandle, nil) == SQLITE_OK else {
            throw SQLiteError.prepareStatement(message: errorMessage)
        }
        
        defer { sqlite3_finalize(stmtHandle) }
        
        // Bind parameters
        var idx = try self.index(for: requestItemColumnNames[0], stmtHandle: stmtHandle)
        try self.bind(requestItem.requestIdentifier.uuidString, paramIdx: idx, stmtHandle: stmtHandle)
        idx = try self.index(for: requestItemColumnNames[1], stmtHandle: stmtHandle)
        try self.bind(requestItem.taskIdentifier, paramIdx: idx, stmtHandle: stmtHandle)
        idx = try self.index(for: requestItemColumnNames[2], stmtHandle: stmtHandle)
        try self.bind(requestItem.streamBodyURL?.absoluteString, paramIdx: idx, stmtHandle: stmtHandle)
        idx = try self.index(for: requestItemColumnNames[3], stmtHandle: stmtHandle)
        try self.bind(Date.now.timeIntervalSince1970, paramIdx: idx, stmtHandle: stmtHandle)
        
        //print(getSQLString(from: stmtHandle) ?? "No statement")
        
        // Execute the query
        guard sqlite3_step(stmtHandle) == SQLITE_DONE else {
            throw SQLiteError.execution(message: errorMessage)
        }
        //print("Inserted into \(requestItemTableName)")
    }
    
    func fetchRequestItem(byId requestIdentifier: RequestTaskIdentifier) throws -> RequestItem? {
        guard let db = self.dbHandle else {
            throw SQLiteError.databaseNotOpen
        }
        
        let querySQL = """
        SELECT \(requestItemColumnNames[0]), \(requestItemColumnNames[1]), \(requestItemColumnNames[2]), \(requestItemColumnNames[3]) 
        FROM \(requestItemTableName) 
        WHERE \(requestItemColumnNames[0]) = \(self.parameterize(for: requestItemColumnNames[0]));
        """

        var stmtHandle: OpaquePointer?
        if sqlite3_prepare_v2(db, querySQL, -1, &stmtHandle, nil) != SQLITE_OK {
            throw SQLiteError.prepareStatement(message: errorMessage)
        }
        defer { sqlite3_finalize(stmtHandle) }
        
        // Bind the requestIdentifier parameter
        let idx = try self.index(for: requestItemColumnNames[0], stmtHandle: stmtHandle)
        try self.bind(requestIdentifier.uuidString, paramIdx: idx, stmtHandle: stmtHandle)
        
        //print(getSQLString(from: stmtHandle) ?? "No statement")
        
        // Execute the query and map to RequestItem
        guard sqlite3_step(stmtHandle) == SQLITE_ROW else {
            return nil  // No record found
        }
        
        let idString = String(cString: sqlite3_column_text(stmtHandle, 0))
        let taskIdentifier = sqlite3_column_int(stmtHandle, 1)
        let streamBodyURLString = sqlite3_column_text(stmtHandle, 2)
        let streamBodyURL = streamBodyURLString != nil ? URL(string: String(cString: streamBodyURLString!)) : nil
        let requestDateSince1970 = sqlite3_column_double(stmtHandle, 3)
        let requestDate = Date(timeIntervalSince1970: requestDateSince1970)
        
        return RequestItem(requestIdentifier: UUID(uuidString: idString)!,
                           taskIdentifier: Int(taskIdentifier),
                           streamBodyURL: streamBodyURL,
                           requestDate: requestDate)
    }
    
    func deleteRequestItem(byId requestIdentifier: RequestTaskIdentifier) throws {
        guard let db = self.dbHandle else {
            throw SQLiteError.databaseNotOpen
        }
        
        let deleteSQL = """
        DELETE FROM \(requestItemTableName) 
        WHERE \(requestItemColumnNames[0]) = \(self.parameterize(for: requestItemColumnNames[0]));
        """
        
        var stmtHandle: OpaquePointer?
        if sqlite3_prepare_v2(db, deleteSQL, -1, &stmtHandle, nil) != SQLITE_OK {
            throw SQLiteError.prepareStatement(message: errorMessage)
        }
        defer { sqlite3_finalize(stmtHandle) }
        
        // Bind the requestIdentifier
        let idx = try self.index(for: requestItemColumnNames[0], stmtHandle: stmtHandle)
        try self.bind(requestIdentifier.uuidString, paramIdx: idx, stmtHandle: stmtHandle)
        
        //print(getSQLString(from: stmtHandle) ?? "No statement")

        // Execute the query
        guard sqlite3_step(stmtHandle) == SQLITE_DONE else {
            throw SQLiteError.execution(message: errorMessage)
        }
        //print("RequestItem deleted.")
    }
}
