//
//  JSONDecoder.swift
//  PaltaLibCore
//
//  Created by Vyacheslav Beltyukov on 20/05/2022.
//

import Foundation

public extension JSONDecoder {
    private static let milisecondsFormatter = ISO8601DateFormatter().do {
        $0.formatOptions.insert(.withFractionalSeconds)
    }
    private static let secondsFormatter = ISO8601DateFormatter()
    
    static let `default` = JSONDecoder().do {
        $0.dateDecodingStrategy = .custom({ decoder in
            let string = try decoder.singleValueContainer().decode(String.self)
            
            if let date = milisecondsFormatter.date(from: string) {
                return date
            } else if let date = secondsFormatter.date(from: string) {
                return date
            } else {
                throw DecodingError.dataCorrupted(
                    .init(codingPath: decoder.codingPath, debugDescription: "Date can't be parsed")
                )
            }
        })
    }
}

extension JSONDecoder: FunctionalExtension {}


