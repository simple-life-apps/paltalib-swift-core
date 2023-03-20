//
//  SQLiteClientTests.swift
//  
//
//  Created by Vyacheslav Beltyukov on 20/03/2023.
//

import Foundation
import XCTest
import PaltaCore

final class SQLiteClientTests: XCTestCase {
    private var fileManager: FileManager!
    private var testURL: URL!
    
    private var client: SQLiteClient!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        
        fileManager = FileManager()
        testURL = fileManager.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        
        try fileManager.createDirectory(at: testURL, withIntermediateDirectories: true)
        
        try reinitClient()
    }
    
    override func tearDown() async throws {
        try fileManager.removeItem(at: testURL)
    }
    
    func testCreateTable() throws {
        try client.executeStatement("CREATE TABLE atable (rowA BLOB PRIMARY KEY, rowB BLOB);")
        
        let expectation = expectation(description: "Statetment executed")
        
        try client.executeStatement("SELECT * FROM atable") { executor in
            XCTAssertNil(executor.getRow())
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testInsertSelect() throws {
        let dataA = UUID().data
        let dataB = UUID().data
        let row = RowData(column1: dataA, column2: dataB)
        
        try client.executeStatement("CREATE TABLE atable (rowA BLOB PRIMARY KEY, rowB BLOB);")
        
        try client.executeStatement("INSERT INTO atable (rowA, rowB) VALUES (?, ?)") { executor in
            executor.setRow(row)
            try executor.runStep()
        }
        
        try reinitClient()
        
        let expectation = expectation(description: "Statetment executed")
        
        try client.executeStatement("SELECT rowA, rowB FROM atable") { executor in
            executor.runQuery()
            XCTAssertEqual(executor.getRow(), row)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testCreateTableIfNotExists() throws {
        let dataA = UUID().data
        let dataB = UUID().data
        let row = RowData(column1: dataA, column2: dataB)
        
        try client.executeStatement("CREATE TABLE atable (rowA BLOB PRIMARY KEY, rowB BLOB);")
        
        try client.executeStatement("INSERT INTO atable (rowA, rowB) VALUES (?, ?)") { executor in
            executor.setRow(row)
            try executor.runStep()
        }
        
        try reinitClient()
        
        try client.executeStatement("CREATE TABLE IF NOT EXISTS atable (rowA BLOB PRIMARY KEY, rowB BLOB);")
        
        try reinitClient()
        
        let expectation = expectation(description: "Statetment executed")
        
        try client.executeStatement("SELECT rowA, rowB FROM atable") { executor in
            executor.runQuery()
            XCTAssertNotNil(executor.getRow())
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 0.1)
    }
    
    func testDelete() throws {
        let dataA = UUID().data
        let dataB = UUID().data
        let row = RowData(column1: dataA, column2: dataB)
        
        try client.executeStatement("CREATE TABLE atable (rowA BLOB PRIMARY KEY, rowB BLOB);")
        
        try client.executeStatement("INSERT INTO atable (rowA, rowB) VALUES (?, ?)") { executor in
            executor.setRow(row)
            try executor.runStep()
        }
        
        try reinitClient()
        
        let expectation1 = expectation(description: "Statetment 1 executed")
        
        try client.executeStatement("SELECT rowA, rowB FROM atable") { executor in
            executor.runQuery()
            XCTAssertNotNil(executor.getRow())
            expectation1.fulfill()
        }
        
        wait(for: [expectation1], timeout: 0.1)
        
        try client.executeStatement("DELETE FROM atable WHERE rowA = ?") { executor in
            executor.setValue(dataA)
            try executor.runStep()
        }
        
        try reinitClient()
        
        let expectation2 = expectation(description: "Statetment 2 executed")
        
        try client.executeStatement("SELECT rowA, rowB FROM atable") { executor in
            executor.runQuery()
            XCTAssertNil(executor.getRow())
            expectation2.fulfill()
        }
        
        wait(for: [expectation2], timeout: 0.1)
    }
    
    private func reinitClient() throws {
        client = try SQLiteClient(folderURL: testURL)
    }
}
