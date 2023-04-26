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
    
    public func setRow<First: Equatable & SQLiteBindable, Second: Equatable & SQLiteBindable>(_ row: RowDataGeneric<First, Second>) {
        row.column1.bind(to: statement, for: 1)
        row.column2.bind(to: statement, for: 2)
    }
    
    public func setValue(_ value: Data) {
        sqlite3_bind_blob(statement, 1, value.withUnsafeBytes { $0.baseAddress }, Int32(value.count), SQLITE_TRANSIENT)
    }
    
    public func getRow<First: Equatable & SQLiteBindable, Second: Equatable & SQLiteBindable>() -> RowDataGeneric<First, Second>? {
        guard
            let column1 = First(from: statement, at: 0),
            let column2 = Second(from: statement, at: 1)
        else {
            return nil
        }
        
        return RowDataGeneric(column1: column1, column2: column2)
    }
}

extension StatementExecutor {
    public func getDataRow() -> RowData? {
        getRow()
    }
    
    public func getIntRow() -> RowDataInteger? {
        getRow()
    }
}

public typealias RowData = RowDataGeneric<Data, Data>
public typealias RowDataInteger = RowDataGeneric<Data, Int>

public struct RowDataGeneric<First: Equatable & SQLiteBindable, Second: Equatable & SQLiteBindable>: Equatable {
    public let column1: First
    public let column2: Second
    
    public init(column1: First, column2: Second) {
        self.column1 = column1
        self.column2 = column2
    }
}

public protocol SQLiteBindable {
    init?(from statement: OpaquePointer, at columnIndex: Int32)
    func bind(to statement: OpaquePointer, for columnIndex: Int32)
}

extension Data: SQLiteBindable {
    public init?(from statement: OpaquePointer, at columnIndex: Int32) {
        guard let pointer = sqlite3_column_blob(statement, columnIndex) else {
            return nil
        }
        
        let length = sqlite3_column_bytes(statement, columnIndex)
        
        self.init(bytes: pointer, count: Int(length))
    }
    
    public func bind(to statement: OpaquePointer, for columnIndex: Int32) {
        sqlite3_bind_blob(statement, columnIndex, withUnsafeBytes { $0.baseAddress }, Int32(count), SQLITE_TRANSIENT)
    }
}

extension Int: SQLiteBindable {
    public init?(from statement: OpaquePointer, at columnIndex: Int32) {
        self.init(sqlite3_column_int64(statement, columnIndex))
    }
    
    public func bind(to statement: OpaquePointer, for columnIndex: Int32) {
        sqlite3_bind_int64(statement, columnIndex, Int64(self))
    }
}

private let SQLITE_TRANSIENT = unsafeBitCast(-1, to: sqlite3_destructor_type.self)
