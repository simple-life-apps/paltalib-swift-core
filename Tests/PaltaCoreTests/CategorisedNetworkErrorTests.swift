//
//  CategorisedNetworkErrorTests.swift
//  
//
//  Created by Vyacheslav Beltyukov on 19/04/2023.
//

import XCTest
import PaltaCore

final class CategorisedNetworkErrorTests: XCTestCase {
    private let allErrors: [CategorisedNetworkError] = [
        .noInternet,
        .timeout,
        .dnsError(.cannotFindHost),
        .sslError(.serverCertificateUntrusted),
        .requiresHttps,
        .cantConnectToHost,
        .otherNetworkError(.unknown),

        // Data/configuration error
        .decodingError,
        .notConfigured,
        .badResponse,
        .badRequest,

        // Based on response codes
        .serverError(500),
        .unauthorised(403),
        .clientError(418),
        
        // Other
        .unknown
    ]
    
    func testCodes() {
        let actualCodes = Dictionary(grouping: allErrors, by: { $0 }).compactMapValues { $0.first?.errorCode }
        
        let expectedCodes: [CategorisedNetworkError: Int] = [
            .noInternet: 1001,
            .timeout: 1002,
            .dnsError(.cannotFindHost): 1003,
            .sslError(.serverCertificateUntrusted): 1004,
            .requiresHttps: 1005,
            .cantConnectToHost: 1006,
            .otherNetworkError(.unknown): 1100,

            // Data/configuration error
            .decodingError: 3001,
            .notConfigured: 4001,
            .badResponse: 1008,
            .badRequest: 1007,

            // Based on response codes
            .serverError(500): 2500,
            .unauthorised(403): 2403,
            .clientError(418): 2418,
            
            // Other
            .unknown: 5001
        ]
        
        XCTAssertEqual(actualCodes, expectedCodes)
    }
    
    func testNoInternet() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.notConnectedToInternet))),
            .noInternet
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.callIsActive))),
            .noInternet
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.dataNotAllowed))),
            .noInternet
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.internationalRoamingOff))),
            .noInternet
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.networkConnectionLost))),
            .noInternet
        )
    }
    
    func testDNSIssues() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.dnsLookupFailed))),
            .dnsError(.dnsLookupFailed)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotFindHost))),
            .dnsError(.cannotFindHost)
        )
    }
    
    func testSSLIssues() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.clientCertificateRequired))),
            .sslError(.clientCertificateRequired)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.clientCertificateRejected))),
            .sslError(.clientCertificateRejected)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.serverCertificateUntrusted))),
            .sslError(.serverCertificateUntrusted)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.serverCertificateHasBadDate))),
            .sslError(.serverCertificateHasBadDate)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.serverCertificateNotYetValid))),
            .sslError(.serverCertificateNotYetValid)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.serverCertificateHasUnknownRoot))),
            .sslError(.serverCertificateHasUnknownRoot)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.secureConnectionFailed))),
            .sslError(.secureConnectionFailed)
        )
    }
    
    func testBadRequest() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.badURL))),
            .badRequest
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.badRequest),
            .badRequest
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.unsupportedURL))),
            .badRequest
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.badRequest),
            .badRequest
        )
    }
    
    func testDecodingError() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.badServerResponse))),
            .badResponse
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotDecodeRawData))),
            .badResponse
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotDecodeContentData))),
            .badResponse
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.zeroByteResource))),
            .badResponse
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.dataLengthExceedsMaximum))),
            .badResponse
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotParseResponse))),
            .badResponse
        )
    }
    
    func testOtherNetworkErrors() {
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.timedOut))),
            .timeout
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.appTransportSecurityRequiresSecureConnection))),
            .requiresHttps
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotConnectToHost))),
            .cantConnectToHost
        )
        XCTAssertEqual(
            CategorisedNetworkError(.urlError(URLError(URLError.Code.cannotCreateFile))),
            .otherNetworkError(.cannotCreateFile)
        )
    }
    
    func testHTTPCodeErrors() {
        XCTAssertEqual(
            CategorisedNetworkError(.invalidStatusCode(501, nil)),
            .serverError(501)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.invalidStatusCode(422, nil)),
            .clientError(422)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.invalidStatusCode(401, nil)),
            .unauthorised(401)
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.invalidStatusCode(403, nil)),
            .unauthorised(403)
        )
    }
    
    func testOtherErrors() {
        XCTAssertEqual(
            CategorisedNetworkError(.decodingError(nil)),
            .decodingError
        )
        
        XCTAssertEqual(
            CategorisedNetworkError(.other(NSError(domain: "", code: 888))),
            .unknown
        )
    }
}
