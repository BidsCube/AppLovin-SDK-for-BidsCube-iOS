import Foundation

/// Network manager for handling all HTTP requests in the BidsCube SDK
public class NetworkManager {
    
    // MARK: - Properties
    
    private let session: URLSession
    private let timeout: TimeInterval
    
    // MARK: - Initialization
    
    public init(timeout: TimeInterval = 30.0) {
        self.timeout = timeout
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = timeout
        config.timeoutIntervalForResource = timeout
        self.session = URLSession(configuration: config)
    }
    
    // MARK: - Public Methods
    
    /// Performs a GET request to the specified URL
    /// - Parameters:
    ///   - url: The URL to request
    ///   - completion: Completion handler with result
    public func get(url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceInfo.userAgent, forHTTPHeaderField: "User-Agent")
        
        performRequest(request, completion: completion)
    }
    
    /// Performs a POST request to the specified URL with JSON data
    /// - Parameters:
    ///   - url: The URL to request
    ///   - data: The data to send
    ///   - completion: Completion handler with result
    public func post(url: URL, data: Data, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue(DeviceInfo.userAgent, forHTTPHeaderField: "User-Agent")
        request.httpBody = data
        
        performRequest(request, completion: completion)
    }
    
    /// Performs a POST request to the specified URL with JSON object
    /// - Parameters:
    ///   - url: The URL to request
    ///   - jsonObject: The JSON object to send
    ///   - completion: Completion handler with result
    public func post(url: URL, jsonObject: [String: Any], completion: @escaping (Result<Data, NetworkError>) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject, options: [])
            
            // Print request body for debugging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                Logger.info("📤 POST Request Body:")
                Logger.info("URL: \(url.absoluteString)")
                Logger.info("Body: \(jsonString)")
                Logger.info("---")
            }
            
            post(url: url, data: jsonData, completion: completion)
        } catch {
            completion(.failure(.unknown(error)))
        }
    }
    
    /// Performs a POST request to the specified URL with JSON array
    /// - Parameters:
    ///   - url: The URL to request
    ///   - jsonArray: The JSON array to send
    ///   - completion: Completion handler with result
    public func post(url: URL, jsonArray: [String], completion: @escaping (Result<Data, NetworkError>) -> Void) {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: [])
            
            // Print request body for debugging
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                Logger.info("📤 POST Request Body:")
                Logger.info("URL: \(url.absoluteString)")
                Logger.info("Body: \(jsonString)")
                Logger.info("---")
            }
            
            post(url: url, data: jsonData, completion: completion)
        } catch {
            completion(.failure(.unknown(error)))
        }
    }
    
    // MARK: - Private Methods
    
    private func performRequest(_ request: URLRequest, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    let networkError = NetworkError.from(error: error)
                    completion(.failure(networkError))
                    return
                }
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    completion(.failure(.invalidResponse))
                    return
                }
                
                if httpResponse.statusCode == 204 {
                    completion(.failure(.noFill))
                    return
                }

                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data, !data.isEmpty else {
                    completion(.failure(.noData))
                    return
                }
                
                completion(.success(data))
            }
        }.resume()
    }
}

// MARK: - Network Error

/// Network-related errors
public enum NetworkError: Error, LocalizedError {
    case invalidURL
    case noData
    case invalidResponse
    case noFill
    case httpError(Int)
    case timeout
    case networkUnavailable
    case unknown(Error)
    
    public var errorDescription: String? {
        adErrorMessage
    }

    /// Message aligned with `AdErrorCode` for mediation / logging.
    public var adErrorMessage: String? {
        switch self {
        case .invalidURL:
            return Constants.ErrorMessages.failedToBuildURL
        case .noData, .invalidResponse:
            return "Invalid ad server response"
        case .noFill:
            return "No ad fill: ad server returned HTTP 204 (No Content)"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .timeout:
            return "Network error: Request timed out"
        case .networkUnavailable:
            return "Network error: Network unavailable"
        case .unknown(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
    
    public var adErrorCode: Int {
        switch self {
        case .invalidURL:
            return AdErrorCode.unknown
        case .noData, .invalidResponse:
            return AdErrorCode.invalidResponse
        case .noFill:
            return AdErrorCode.noFill
        case .httpError:
            return AdErrorCode.httpError
        case .timeout, .networkUnavailable, .unknown:
            return AdErrorCode.networkError
        }
    }

    public var errorCode: Int {
        adErrorCode
    }
    
    static func from(error: Error) -> NetworkError {
        if let urlError = error as? URLError {
            switch urlError.code {
            case .timedOut:
                return .timeout
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            default:
                return .unknown(error)
            }
        }
        return .unknown(error)
    }
}

// MARK: - Singleton

extension NetworkManager {
    /// Shared instance for common network operations
    public static let shared = NetworkManager()
}







