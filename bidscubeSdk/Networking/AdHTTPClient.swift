import Foundation

/// Ad-server GET requests with stable error mapping (including HTTP 204 no-fill).
enum AdHTTPClient {
    private static let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 30
        return URLSession(configuration: config)
    }()

    static func fetchBody(
        url: URL,
        completion: @escaping (Result<String, BidscubeRequestError>) -> Void
    ) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceInfo.userAgent, forHTTPHeaderField: "User-Agent")

        Logger.network("Sending GET request to: \(url.absoluteString)")

        session.dataTask(with: request) { data, response, error in
            let result = parseResponse(data: data, response: response, error: error)
            DispatchQueue.main.async {
                completion(result)
            }
        }.resume()
    }

    private static func parseResponse(
        data: Data?,
        response: URLResponse?,
        error: Error?
    ) -> Result<String, BidscubeRequestError> {
        if let error {
            if let urlError = error as? URLError, urlError.code == .timedOut {
                return .failure(BidscubeRequestError(
                    errorCode: AdErrorCode.networkError,
                    message: "Network error: Request timed out"
                ))
            }
            return .failure(BidscubeRequestError(
                errorCode: AdErrorCode.networkError,
                message: "Network error: \(error.localizedDescription)"
            ))
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            return .failure(BidscubeRequestError(
                errorCode: AdErrorCode.invalidResponse,
                message: "Invalid ad server response"
            ))
        }

        let status = httpResponse.statusCode
        Logger.network("Response code: \(status)")

        if status == 204 {
            Logger.network("No ad fill (HTTP 204)")
            return .failure(BidscubeRequestError(
                errorCode: AdErrorCode.noFill,
                httpStatus: 204,
                message: "No ad fill: ad server returned HTTP 204 (No Content)"
            ))
        }

        guard (200...299).contains(status) else {
            let bodySnippet = truncateBody(data)
            let suffix = bodySnippet.isEmpty ? "" : " — \(bodySnippet)"
            return .failure(BidscubeRequestError(
                errorCode: AdErrorCode.httpError,
                httpStatus: status,
                message: "HTTP error: \(status)\(suffix)"
            ))
        }

        guard let data, !data.isEmpty,
              let body = String(data: data, encoding: .utf8),
              !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .failure(BidscubeRequestError(
                errorCode: AdErrorCode.invalidResponse,
                message: "Invalid ad server response"
            ))
        }

        return .success(body)
    }

    private static func truncateBody(_ data: Data?, maxLength: Int = 200) -> String {
        guard let data,
              let text = String(data: data, encoding: .utf8),
              !text.isEmpty else { return "" }
        if text.count <= maxLength { return text }
        return String(text.prefix(maxLength)) + "..."
    }
}
