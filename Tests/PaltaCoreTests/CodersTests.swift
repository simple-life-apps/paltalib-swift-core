//
//  CodersTests.swift
//  
//
//  Created by Vyacheslav Beltyukov on 28/04/2023.
//

import Foundation
import XCTest
import PaltaCore

final class CodersTests: XCTestCase {
    struct TestStruct: Codable {
        let date: Date
    }
    
    func testDateWithMsec() throws {
        let data = "{\"date\": \"2022-04-27T08:14:56.217000+00:00\"}".data(using: .utf8)!
        let date = try JSONDecoder.default.decode(TestStruct.self, from: data).date
        
        XCTAssertEqual(date, Date(timeIntervalSince1970: 1651047296.217))
    }
    
    func testDateWithoutMsec() throws {
        let data = "{\"date\": \"2022-04-27T08:14:56+00:00\"}".data(using: .utf8)!
        let date = try JSONDecoder.default.decode(TestStruct.self, from: data).date
        
        XCTAssertEqual(date, Date(timeIntervalSince1970: 1651047296))
    }
}
