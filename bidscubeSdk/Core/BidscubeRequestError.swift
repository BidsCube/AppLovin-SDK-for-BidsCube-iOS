import Foundation

/// Structured failure for ad HTTP / parsing paths.
public struct BidscubeRequestError: Error, LocalizedError {
    public let errorCode: Int
    public let httpStatus: Int
    public let message: String

    public init(errorCode: Int, message: String) {
        self.errorCode = errorCode
        self.httpStatus = 0
        self.message = message
    }

    public init(errorCode: Int, httpStatus: Int, message: String) {
        self.errorCode = errorCode
        self.httpStatus = httpStatus
        self.message = message
    }

    public var errorDescription: String? { message }
}
