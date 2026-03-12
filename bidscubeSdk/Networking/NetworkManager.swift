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
                
                guard 200...299 ~= httpResponse.statusCode else {
                    completion(.failure(.httpError(httpResponse.statusCode)))
                    return
                }
                
                guard let data = data else {
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
    case httpError(Int)
    case timeout
    case networkUnavailable
    case unknown(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .noData:
            return "No data received"
        case .invalidResponse:
            return "Invalid response"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .timeout:
            return "Request timeout"
        case .networkUnavailable:
            return "Network unavailable"
        case .unknown(let error):
            return error.localizedDescription
        }
    }
    
    public var errorCode: Int {
        switch self {
        case .invalidURL:
            return Constants.ErrorCodes.invalidURL
        case .noData:
            return Constants.ErrorCodes.invalidResponse
        case .invalidResponse:
            return Constants.ErrorCodes.invalidResponse
        case .httpError(let code):
            return code
        case .timeout:
            return Constants.ErrorCodes.timeoutError
        case .networkUnavailable:
            return Constants.ErrorCodes.networkError
        case .unknown:
            return Constants.ErrorCodes.networkError
        }
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







