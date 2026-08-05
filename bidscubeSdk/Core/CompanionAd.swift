import Foundation

/// Parsed VAST `Companion` selected for post-video display.
public struct CompanionAd: Equatable {
    public enum ResourceType: Equatable {
        case html
        case iframe
        case `static`
    }

    public let resourceType: ResourceType
    public let resource: String
    public let width: Int
    public let height: Int
    public let clickThroughUrl: String?
    public let clickTrackingUrls: [String]
    public let creativeViewTrackingUrls: [String]

    public var isInteractive: Bool {
        resourceType == .html || resourceType == .iframe
    }

    public var isStaticImage: Bool {
        resourceType == .static
    }
}
