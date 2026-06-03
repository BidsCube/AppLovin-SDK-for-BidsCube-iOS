import Foundation

/// Stable error codes returned via `AdCallback.onAdFailed`.
/// Messages are English and intended for logs / mediation adapters.
public enum AdErrorCode {
    /// Unknown or unclassified failure.
    public static let unknown = -1
    /// SSP returned HTTP 204 — no ad available for this request.
    public static let noFill = 204
    /// Non-2xx HTTP response from the ad server (except 204).
    public static let httpError = 1001
    /// Response body could not be parsed into a Bidscube ad payload.
    public static let invalidResponse = 1002
    /// Ad markup (ADM) was empty after a successful HTTP response.
    public static let emptyAdm = 1003
    /// A view controller is required but none was bound before show.
    public static let noViewController = 1004
    /// Network I/O failure (timeout, connection error, etc.).
    public static let networkError = 1005
    /// Unexpected error while building or displaying the ad UI.
    public static let displayError = 1006

    public static func from(_ error: Error) -> Int {
        if let request = error as? BidscubeRequestError {
            return request.errorCode
        }
        if let network = error as? NetworkError {
            return network.adErrorCode
        }
        let message = (error as NSError).localizedDescription
        if message.contains("HTTP error: 204") || message.contains("HTTP 204") {
            return noFill
        }
        if message.hasPrefix("HTTP error:") {
            return httpError
        }
        if message.contains("Failed to parse") {
            return invalidResponse
        }
        if message.contains("view controller") || message.contains("View controller") {
            return noViewController
        }
        return unknown
    }

    public static func message(for error: Error) -> String {
        if let request = error as? BidscubeRequestError {
            return request.message
        }
        if let network = error as? NetworkError, let msg = network.adErrorMessage {
            return msg
        }
        let text = (error as NSError).localizedDescription
        return text.isEmpty ? "Unknown ad request error" : text
    }

    public static func describe(_ errorCode: Int) -> String {
        switch errorCode {
        case noFill:
            return "No ad fill (HTTP 204)"
        case httpError:
            return "Ad server HTTP error"
        case invalidResponse:
            return "Invalid ad server response"
        case emptyAdm:
            return "Empty ad markup"
        case noViewController:
            return "View controller required"
        case networkError:
            return "Network error"
        case displayError:
            return "Ad display error"
        case unknown:
            return "Unknown error"
        default:
            return "Unknown error"
        }
    }
}
