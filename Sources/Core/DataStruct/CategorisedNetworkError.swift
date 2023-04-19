//
//  CategorisedNetworkError.swift
//  
//
//  Created by Vyacheslav Beltyukov on 18/04/2023.
//

import Foundation

public enum CategorisedNetworkError: Error, Hashable {
    // Networking
    case noInternet
    case timeout
    case dnsError(URLError.Code)
    case sslError(URLError.Code)
    case requiresHttps
    case cantConnectToHost
    case otherNetworkError(URLError.Code)
    
    // Data/configuration error
    case decodingError
    case notConfigured
    case badResponse
    case badRequest
    
    // Based on response codes
    case serverError(Int)
    case unauthorised(Int)
    case clientError(Int)
    
    // Other
    case unknown
}

public extension CategorisedNetworkError {
    var errorCode: Int {
        switch self {
        case .noInternet:
            return 1001
        case .timeout:
            return 1002
        case .dnsError:
            return 1003
        case .sslError:
            return 1004
        case .requiresHttps:
            return 1005
        case .cantConnectToHost:
            return 1006
        case .otherNetworkError:
            return 1100
        case .decodingError:
            return 3001
        case .notConfigured:
            return 4001
        case .badResponse:
            return 1008
        case .badRequest:
            return 1007
        case .serverError(let code):
            return 2000 + code
        case .unauthorised(let code):
            return 2000 + code
        case .clientError(let code):
            return 2000 + code
        case .unknown:
            return 5001
        }
    }
}

public extension CategorisedNetworkError {
    init(_ networkError: NetworkErrorWithoutResponse) {
        switch networkError {
        case .badRequest:
            self = .badRequest
        case .decodingError:
            self = .decodingError
        case .invalidStatusCode(let code, _):
            self.init(statusCode: code)
        case .noData:
            self = .badResponse
        case .urlError(let error):
            self.init(error)
        case .other:
            self = .unknown
        }
    }
}

private extension CategorisedNetworkError {
    init(statusCode: Int) {
        if (500...599).contains(statusCode) {
            self = .serverError(statusCode)
        } else if [401, 403].contains(statusCode) {
            self = .unauthorised(statusCode)
        } else if (400...499).contains(statusCode) {
            self = .clientError(statusCode)
        } else {
            assertionFailure()
            self = .unknown
        }
    }
    
    init(_ urlError: URLError) {
        switch urlError.code {
        case .badServerResponse, .cannotDecodeContentData, .cannotDecodeRawData, .cannotParseResponse, .dataLengthExceedsMaximum,
            .downloadDecodingFailedMidStream, .downloadDecodingFailedToComplete, .zeroByteResource:
            self = .badResponse
        case .badURL, .unsupportedURL:
            self = .badRequest
        case .appTransportSecurityRequiresSecureConnection:
            self = .requiresHttps
        case .callIsActive, .dataNotAllowed, .internationalRoamingOff, .networkConnectionLost, .notConnectedToInternet:
            self = .noInternet
        case .cannotConnectToHost:
            self = .cantConnectToHost
        case .cannotFindHost, .dnsLookupFailed:
            self = .dnsError(urlError.code)
        case .clientCertificateRejected, .clientCertificateRequired, .secureConnectionFailed, .serverCertificateUntrusted,
                .serverCertificateHasBadDate, .serverCertificateNotYetValid, .serverCertificateHasUnknownRoot:
            self = .sslError(urlError.code)
        case .timedOut:
            self = .timeout
        case .backgroundSessionInUseByAnotherProcess, .backgroundSessionRequiresSharedContainer, .backgroundSessionWasDisconnected,
                .cancelled, .cannotCloseFile, .cannotCreateFile, .cannotLoadFromNetwork, .cannotMoveFile, .cannotOpenFile,
                .cannotRemoveFile, .cannotWriteToFile, .fileDoesNotExist, .fileIsDirectory, .httpTooManyRedirects, .noPermissionsToReadFile,
                .resourceUnavailable, .requestBodyStreamExhausted, .redirectToNonExistentLocation, .unknown, .userAuthenticationRequired,
                .userCancelledAuthentication:
            self = .otherNetworkError(urlError.code)
        default:
            self = .otherNetworkError(urlError.code)
        }
    }
}
