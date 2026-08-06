import Foundation

/// Normalizes Bidscube banner/image `adm` payloads for WebView display.
enum BannerAdMarkupNormalizer {
    static func normalize(_ rawAdm: String) -> String {
        var markup = rawAdm.trimmingCharacters(in: .whitespacesAndNewlines)
        if markup.hasPrefix("\u{FEFF}") {
            markup = String(markup.dropFirst())
        }
        guard !markup.isEmpty else { return markup }

        for _ in 0..<4 {
            let next = normalizeOnce(markup)
            if next == markup { break }
            markup = next
        }
        return markup.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// Extracts renderable markup from an SSP HTTP body (JSON `adm` field or wrapped HTML).
    static func extractRenderableMarkup(from body: String) -> String? {
        var trimmed = body.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("\u{FEFF}") {
            trimmed = String(trimmed.dropFirst())
        }
        guard !trimmed.isEmpty else { return nil }

        if let data = trimmed.data(using: .utf8),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let adm = json["adm"] as? String {
            let cleaned = normalize(adm.trimmingCharacters(in: .whitespacesAndNewlines))
            return cleaned.isEmpty ? nil : cleaned
        }

        let normalized = normalize(trimmed)
        guard !normalized.isEmpty else { return nil }
        if normalized.contains("\"adm\"") || normalized.hasPrefix("{") {
            return nil
        }
        return normalized
    }

    private static func normalizeOnce(_ markup: String) -> String {
        var result = unwrapDocumentWrite(markup)
        if shouldExtractNestedQuotedAdm(from: result) {
            result = replaceNestedSpanAdmJSON(in: result)
        } else {
            result = unwrapNestedAdmJsonEnvelope(result)
        }
        return stripTrailingJsonEnvelope(result)
    }

    /// Nested SSP payloads embed JSON text inside HTML (e.g. `<span>{"adm":"..."}</span>`).
    private static func shouldExtractNestedQuotedAdm(from markup: String) -> Bool {
        guard let admRange = markup.range(of: #""adm"\s*:\s*""#, options: .regularExpression) else {
            return false
        }
        return markup[..<admRange.lowerBound].contains("<")
    }

    private static func unwrapDocumentWrite(_ markup: String) -> String {
        guard markup.hasPrefix("document.write(") else { return markup }

        var inner = String(markup.dropFirst("document.write(".count))
        if inner.hasSuffix(");") {
            inner = String(inner.dropLast(2))
        } else if inner.hasSuffix(")") {
            inner = String(inner.dropLast(1))
        }
        return inner.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// SSP banner responses may embed `{ "adm": "<html>..." }` inside `document.write(...)`.
    /// Strip the JSON envelope but keep trailing impression/click scripts.
    private static func unwrapNestedAdmJsonEnvelope(_ markup: String) -> String {
        guard markup.contains("adm") else { return markup }

        let separators = ["\"\n}", "\"\n}\n", "\"\r\n}", "\" }", "\"}", "' }", "'}"]
        for separator in separators {
            let parts = markup.components(separatedBy: separator)
            guard parts.count >= 2, parts[0].contains("adm") else { continue }

            let html = stripAdmJsonPrefix(parts[0])
            let trailing = parts.dropFirst().joined(separator: separator)
            return html + trailing
        }

        return stripAdmJsonPrefix(markup)
    }

    /// Replaces nested `{"adm":"..."}` JSON text inside HTML (e.g. `<span>`) with its inner HTML.
    /// SSP payloads often contain unescaped quotes in the inner HTML, so naive quote parsing fails.
    private static func replaceNestedSpanAdmJSON(in markup: String) -> String {
        guard let match = markup.range(of: #"\{\s*"adm"\s*:\s*""#, options: .regularExpression) else {
            return markup
        }

        let contentStart = match.upperBound
        let remainder = markup[contentStart...]
        let closingPatterns = ["\"\n}", "\"}"]

        for pattern in closingPatterns {
            guard let closeRange = remainder.range(of: pattern, options: .backwards) else {
                continue
            }

            let innerHTML = String(remainder[..<closeRange.lowerBound])
            guard innerHTML.contains("<"), innerHTML.count >= 5 else {
                continue
            }

            let fullRange = match.lowerBound..<closeRange.upperBound
            return markup.replacingCharacters(in: fullRange, with: innerHTML)
        }

        return markup
    }

    private static func stripAdmJsonPrefix(_ markup: String) -> String {
        let patterns = [
            #"^\{\s*"adm"\s*:\s*""#,
            #"^\{\s*'adm'\s*:\s*'"#,
            #"^\{\s*adm\s*:\s*""#
        ]
        for pattern in patterns {
            if let range = markup.range(of: pattern, options: .regularExpression) {
                return String(markup[range.upperBound...]).trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        return markup.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func stripTrailingJsonEnvelope(_ markup: String) -> String {
        var result = markup.trimmingCharacters(in: .whitespacesAndNewlines)
        let suffixes = ["\"};", "\"}", "'};", "'}", "\");", "\"]", "\"", "'"]
        var changed = true
        while changed {
            changed = false
            for suffix in suffixes where result.hasSuffix(suffix) && result.count > suffix.count {
                result = String(result.dropLast(suffix.count)).trimmingCharacters(in: .whitespacesAndNewlines)
                changed = true
                break
            }
            if result.hasSuffix("}") && !result.contains("<") {
                result = String(result.dropLast()).trimmingCharacters(in: .whitespacesAndNewlines)
                changed = true
            }
        }
        return result
    }
}
