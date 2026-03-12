import Foundation

public enum AdType: String {
    case image
    case video
    case native

    var pathSegment: String {
        switch self {
        case .image: return "image"
        case .video: return "video"
        case .native: return "native"
        }
    }
}




