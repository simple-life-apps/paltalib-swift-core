//
//  SQLiteClient.swift
//  
//
//  Created by Vyacheslav Beltyukov on 20/03/2023.
//

import Foundation
import SQLite3

public enum SQliteError: Error {
    case databaseCantBeOpen
    case statementPreparationFailed
    case stepExecutionFailed
    case dataExctractionFailed
    case queryFailed
}

public class SQLiteClient {
    static func openDatabase(at url: URL) throws -> OpaquePointer {
        var pointer: OpaquePointer?
        
        var result: Int32 = -999
        
        url.path.withCString {
            result = sqlite3_open_v2(
                $0,
                &pointer,
                SQLITE_OPEN_FULLMUTEX | SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE,
                UnsafePointer(nil as UnsafePointer<Int>?)
            )
        }
        
        
        guard result == SQLITE_OK, let pointer = pointer else {
            throw SQliteError.databaseCantBeOpen
        }
        
        return pointer
    }
    
    private let db: OpaquePointer
    
    public init(databaseURL: URL) throws {
        self.db = try Self.openDatabase(at: databaseURL)
    }
    
    public func executeStatement(_ statementString: String) throws {
        try executeStatement(statementString) { executor in
            try executor.runStep()
        }
    }
    
    public func executeStatement<T>(_ statementString: String, _ execution: (StatementExecutor) throws -> T) throws -> T {
        var statement: OpaquePointer?
        
        guard
            sqlite3_prepare_v2(db, statementString, -1, &statement, nil) ==
                SQLITE_OK,
            let statement = statement
        else {
            throw SQliteError.statementPreparationFailed
        }
        
        defer {
            sqlite3_finalize(statement)
        }
        
        let result = try execution(StatementExecutor(statement: statement))
        
        return result
    }
}

public struct StatementExecutor {
    let statement: OpaquePointer
    
    public init(statement: OpaquePointer) {
        self.statement = statement
    }
    
    public func runStep() throws {
        let result = sqlite3_step(statement)
        guard result == SQLITE_DONE else {
            throw SQliteError.stepExecutionFailed
        }
    }
    
    @discardableResult
    public func runQuery() -> Bool {
        sqlite3_step(statement) == SQLITE_ROW
    }
    
    public func setRow(_ row: RowData) {
        sqlite3_bind_blob(statement, 1, row.column1.withUnsafeBytes { $0.baseAddress }, Int32(row.column1.count), SQLITE_TRANSIENT)
        sqlite3_bind_blob(statement, 2, row.column2.withUnsafeBytes { $0.baseAddress }, Int32(row.column2.count), SQLITE_TRANSIENT)
    }
    
    public func setValue(_ value: Data) {
        sqlite3_bind_blob(statement, 1, value.withUnsafeBytes { $0.baseAddress }, Int32(value.count), SQLITE_TRANSIENT)
    }
    
    public func getRow() -> RowData? {
        let pointer1 = sqlite3_column_blob(statement, 0)
        let length1 = sqlite3_column_bytes(statement, 0)
        
        let pointer2 = sqlite3_column_blob(statement, 1)
        let length2 = sqlite3_column_bytes(statement, 1)
        
        guard
            let pointer1 = pointer1,
            let pointer2 = pointer2
        else {
            return nil
        }
        
        let data1 = Data(bytes: pointer1, count: Int(length1))
        let data2 = Data(bytes: pointer2, count: Int(length2))
        
        return RowData(column1: data1, column2: data2)
    }
}

public struct RowData: Equatable {
    public let column1: Data
    public let column2: Data
    
    public init(column1: Data, column2: Data) {
        self.column1 = column1
        self.column2 = column2
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
