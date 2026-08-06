import Foundation

struct VastTrackingContext {
    var playheadSeconds: Double = 0
    var assetURI: String = ""
}

enum VastTrackingMacroReplacer {
    static func replace(
        _ url: String,
        context: VastTrackingContext,
        errorCode: Int? = nil
    ) -> String {
        var result = VastParser.decodeXMLEntities(url)
        let cacheBuster = String(Int.random(in: 10_000_000...99_999_999))
        let errorValue = errorCode.map { String($0) } ?? "900"
        let encodedAsset = context.assetURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? context.assetURI

        result = result.replacingOccurrences(of: "[ERRORCODE]", with: errorValue, options: .caseInsensitive)
        result = result.replacingOccurrences(of: "[CACHEBUSTING]", with: cacheBuster, options: .caseInsensitive)
        result = result.replacingOccurrences(of: "[CACHEBUSTER]", with: cacheBuster, options: .caseInsensitive)
        result = result.replacingOccurrences(of: "[RANDOM]", with: cacheBuster, options: .caseInsensitive)
        result = result.replacingOccurrences(
            of: "[CONTENTPLAYHEAD]",
            with: formatPlayhead(context.playheadSeconds),
            options: .caseInsensitive
        )
        result = result.replacingOccurrences(of: "[ASSETURI]", with: encodedAsset, options: .caseInsensitive)
        return result
    }

    static func formatPlayhead(_ seconds: Double) -> String {
        let total = max(0, seconds)
        let hours = Int(total) / 3600
        let minutes = (Int(total) % 3600) / 60
        let secs = total.truncatingRemainder(dividingBy: 60)
        return String(format: "%02d:%02d:%06.3f", hours, minutes, secs)
    }
}
