import Foundation

/// SKAdNetwork fidelity types
public enum SKAdNetworkFidelityType: Int, Codable {
    case viewThrough = 0
    case storeKitRendered = 1
}

/// SKAdNetwork fidelity object (v2.16.0+)
public struct SKAdNetworkFidelity: Codable {
    public let fidelity: SKAdNetworkFidelityType
    public let nonce: String
    public let signature: String
    public let timestamp: Int64
    
    public init(fidelity: SKAdNetworkFidelityType, nonce: String, signature: String, timestamp: Int64) {
        self.fidelity = fidelity
        self.nonce = nonce
        self.signature = signature
        self.timestamp = timestamp
    }
}

/// SKAdNetwork response object (v2.15.0 and below)
public struct SKAdNetworkResponseV2_15: Codable {
    public let version: String
    public let network: String
    public let campaign: Int
    public let itunesitem: Int64
    public let nonce: String
    public let sourceapp: Int64
    public let timestamp: Int64
    public let signature: String
    public let fidelityType: SKAdNetworkFidelityType?
    
    private enum CodingKeys: String, CodingKey {
        case version, network, campaign, itunesitem, nonce, sourceapp, timestamp, signature
        case fidelityType = "fidelity-type"
    }
    
    public init(version: String, network: String, campaign: Int, itunesitem: Int64, nonce: String, sourceapp: Int64, timestamp: Int64, signature: String, fidelityType: SKAdNetworkFidelityType? = nil) {
        self.version = version
        self.network = network
        self.campaign = campaign
        self.itunesitem = itunesitem
        self.nonce = nonce
        self.sourceapp = sourceapp
        self.timestamp = timestamp
        self.signature = signature
        self.fidelityType = fidelityType
    }
}

/// SKAdNetwork response object (v2.16.0 and above)
public struct SKAdNetworkResponseV2_16: Codable {
    public let version: String
    public let network: String
    public let campaign: Int
    public let itunesitem: Int64
    public let sourceapp: Int64
    public let fidelities: [SKAdNetworkFidelity]
    
    public init(version: String, network: String, campaign: Int, itunesitem: Int64, sourceapp: Int64, fidelities: [SKAdNetworkFidelity]) {
        self.version = version
        self.network = network
        self.campaign = campaign
        self.itunesitem = itunesitem
        self.sourceapp = sourceapp
        self.fidelities = fidelities
    }
}

/// Unified SKAdNetwork response that can handle both versions
public enum SKAdNetworkResponse {
    case version2_15(SKAdNetworkResponseV2_15)
    case version2_16(SKAdNetworkResponseV2_16)
    
    public var version: String {
        switch self {
        case .version2_15(let response):
            return response.version
        case .version2_16(let response):
            return response.version
        }
    }
    
    public var network: String {
        switch self {
        case .version2_15(let response):
            return response.network
        case .version2_16(let response):
            return response.network
        }
    }
    
    public var campaign: Int {
        switch self {
        case .version2_15(let response):
            return response.campaign
        case .version2_16(let response):
            return response.campaign
        }
    }
    
    public var itunesitem: Int64 {
        switch self {
        case .version2_15(let response):
            return response.itunesitem
        case .version2_16(let response):
            return response.itunesitem
        }
    }
    
    public var sourceapp: Int64 {
        switch self {
        case .version2_15(let response):
            return response.sourceapp
        case .version2_16(let response):
            return response.sourceapp
        }
    }
}

