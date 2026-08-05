import Foundation

enum VastParser {
    static func selectPostVideoCompanion(_ vastXml: String) -> CompanionAd? {
        guard !vastXml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
        let companions = parseCompanionElements(from: vastXml)
        return companions.max(by: { companionPriority($0.resourceType) < companionPriority($1.resourceType) })
    }

    static func hasCompanionPreview(_ vastXml: String) -> Bool {
        guard let companion = selectPostVideoCompanion(vastXml) else { return false }
        return companion.isStaticImage
    }

    static func hasHtmlCompanion(_ vastXml: String) -> Bool {
        guard let companion = selectPostVideoCompanion(vastXml) else { return false }
        return companion.isInteractive
    }

    /// VAST `Linear@skipoffset` in milliseconds, or `-1` when absent / unparsable.
    static func getSkipOffsetMs(_ vastXml: String) -> Int64 {
        guard let linearOpenTag = firstLinearOpenTag(in: vastXml) else { return -1 }
        guard let skipOffset = parseAttribute("skipoffset", in: linearOpenTag)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !skipOffset.isEmpty else {
            return -1
        }

        if skipOffset.hasSuffix("%") {
            let percentText = String(skipOffset.dropLast())
            guard let percent = Double(percentText) else { return -1 }
            let durationMs = getDurationMs(vastXml)
            guard durationMs > 0 else { return -1 }
            return Int64((Double(durationMs) * (percent / 100.0)).rounded())
        }

        return parseTimeToMs(skipOffset)
    }

    /// VAST `Duration` in milliseconds, or `-1` when absent / unparsable.
    static func getDurationMs(_ vastXml: String) -> Int64 {
        guard let duration = firstTagText("Duration", in: vastXml) else { return -1 }
        return parseTimeToMs(duration)
    }

    static func resolveSkipSeconds(vastXml: String?, defaultSeconds: Int = 15) -> Int {
        guard let vastXml, !vastXml.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return defaultSeconds
        }
        let skipMs = getSkipOffsetMs(vastXml)
        if skipMs > 0 {
            return max(1, Int(ceil(Double(skipMs) / 1000.0)))
        }
        return defaultSeconds
    }

    private static func firstLinearOpenTag(in vastXml: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "<Linear\\b[^>]*>",
            options: [.caseInsensitive]
        ),
              let match = regex.firstMatch(
                in: vastXml,
                options: [],
                range: NSRange(vastXml.startIndex..<vastXml.endIndex, in: vastXml)
              ),
              let range = Range(match.range, in: vastXml) else {
            return nil
        }
        return String(vastXml[range])
    }

    private static func parseAttribute(_ name: String, in openTag: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "\(name)\\s*=\\s*\"([^\"]*)\"",
            options: [.caseInsensitive]
        ),
              let match = regex.firstMatch(
                in: openTag,
                options: [],
                range: NSRange(openTag.startIndex..<openTag.endIndex, in: openTag)
              ),
              let range = Range(match.range(at: 1), in: openTag) else {
            return nil
        }
        return String(openTag[range])
    }

    private static func parseTimeToMs(_ raw: String) -> Int64 {
        let parts = raw.trimmingCharacters(in: .whitespacesAndNewlines).split(separator: ":")
        guard parts.count == 3,
              let hours = Int(parts[0]),
              let minutes = Int(parts[1]),
              let seconds = Double(parts[2]) else {
            return -1
        }
        let totalSeconds = (Double(hours) * 3600.0) + (Double(minutes) * 60.0) + seconds
        return Int64((totalSeconds * 1000.0).rounded())
    }

    private static func companionPriority(_ type: CompanionAd.ResourceType) -> Int {
        switch type {
        case .html: return 3
        case .iframe: return 2
        case .static: return 1
        }
    }

    private static func parseCompanionElements(from vastXml: String) -> [CompanionAd] {
        guard let regex = try? NSRegularExpression(
            pattern: "<Companion\\b[^>]*>(.*?)</Companion>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }

        let range = NSRange(vastXml.startIndex..<vastXml.endIndex, in: vastXml)
        let matches = regex.matches(in: vastXml, options: [], range: range)
        return matches.compactMap { match in
            guard let bodyRange = Range(match.range(at: 1), in: vastXml),
                  let openTagRange = Range(match.range, in: vastXml) else {
                return nil
            }
            let openTag = String(vastXml[openTagRange]).components(separatedBy: ">").first ?? ""
            let body = String(vastXml[bodyRange])
            return parseCompanionElement(openTag: openTag, body: body)
        }
    }

    private static func parseCompanionElement(openTag: String, body: String) -> CompanionAd? {
        let html = firstTagText("HTMLResource", in: body)
        let iframe = firstTagText("IFrameResource", in: body)
        let staticUrl = firstStaticResourceUrl(in: body)

        let resourceType: CompanionAd.ResourceType
        let resource: String
        if let html, !html.isEmpty {
            resourceType = .html
            resource = html
        } else if let iframe, !iframe.isEmpty {
            resourceType = .iframe
            resource = iframe
        } else if let staticUrl, !staticUrl.isEmpty {
            resourceType = .static
            resource = staticUrl
        } else {
            return nil
        }

        let width = parseDimensionAttribute("width", in: openTag)
        let height = parseDimensionAttribute("height", in: openTag)
        let clickThrough = firstTagText("CompanionClickThrough", in: body)
        let clickTracking = allTagTexts("CompanionClickTracking", in: body)
        let creativeView = allTagTexts("Tracking", in: firstTagBlock("TrackingEvents", in: body) ?? "")

        return CompanionAd(
            resourceType: resourceType,
            resource: resource,
            width: width,
            height: height,
            clickThroughUrl: clickThrough,
            clickTrackingUrls: clickTracking,
            creativeViewTrackingUrls: creativeView
        )
    }

    private static func firstStaticResourceUrl(in body: String) -> String? {
        guard let block = firstTagBlock("StaticResource", in: body) else { return nil }
        return extractCDATAOrText(from: block)
    }

    private static func firstTagText(_ tag: String, in body: String) -> String? {
        guard let block = firstTagBlock(tag, in: body) else { return nil }
        return extractCDATAOrText(from: block)
    }

    private static func allTagTexts(_ tag: String, in body: String) -> [String] {
        guard let regex = try? NSRegularExpression(
            pattern: "<\(tag)\\b[^>]*>(.*?)</\(tag)>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ) else {
            return []
        }
        let range = NSRange(body.startIndex..<body.endIndex, in: body)
        return regex.matches(in: body, options: [], range: range).compactMap { match in
            guard let textRange = Range(match.range(at: 1), in: body) else { return nil }
            return extractCDATAOrText(from: String(body[textRange]))
        }.filter { !$0.isEmpty }
    }

    private static func firstTagBlock(_ tag: String, in body: String) -> String? {
        guard let regex = try? NSRegularExpression(
            pattern: "<\(tag)\\b[^>]*>.*?</\(tag)>",
            options: [.caseInsensitive, .dotMatchesLineSeparators]
        ),
              let match = regex.firstMatch(in: body, options: [], range: NSRange(body.startIndex..<body.endIndex, in: body)),
              let range = Range(match.range, in: body) else {
            return nil
        }
        return String(body[range])
    }

    private static func extractCDATAOrText(from raw: String) -> String? {
        if let cdataRegex = try? NSRegularExpression(pattern: "<!\\[CDATA\\[(.*?)\\]\\]>", options: [.dotMatchesLineSeparators]),
           let match = cdataRegex.firstMatch(in: raw, options: [], range: NSRange(raw.startIndex..<raw.endIndex, in: raw)),
           let range = Range(match.range(at: 1), in: raw) {
            return String(raw[range]).trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return raw
            .replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func parseDimensionAttribute(_ name: String, in openTag: String) -> Int {
        guard let regex = try? NSRegularExpression(pattern: "\(name)\\s*=\\s*\"?(\\d+)\"?", options: [.caseInsensitive]),
              let match = regex.firstMatch(in: openTag, options: [], range: NSRange(openTag.startIndex..<openTag.endIndex, in: openTag)),
              let range = Range(match.range(at: 1), in: openTag),
              let value = Int(openTag[range]) else {
            return 0
        }
        return value
    }
}
