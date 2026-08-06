import Foundation

struct VastInlineAd {
    let vastXml: String
    let mediaURL: URL
    let impressionUrls: [String]
    let trackingEvents: [String: [String]]
    let clickThroughUrl: String?
    let clickTrackingUrls: [String]
    let errorUrls: [String]
}

struct VastWrapperMetadata {
    let impressionUrls: [String]
    let errorUrls: [String]
    let trackingEvents: [String: [String]]
    let clickTrackingUrls: [String]
    let companionCreativeViewUrls: [String]
    let companion: CompanionAd?
}

struct ResolvedVastAd {
    let inlineAd: VastInlineAd
    let mergedImpressionURLs: [String]
    let mergedErrorURLs: [String]
    let mergedTrackingEvents: [String: [String]]
    let mergedClickTrackingURLs: [String]
    let companionCreativeViewURLs: [String]
    let companion: CompanionAd?
    let vastXml: String
}

struct VastResolutionFailure: Error {
    let requestError: BidscubeRequestError
    let vastErrorCode: Int
    let collectedErrorURLs: [String]
}

enum VastResolver {
    static let maxRedirects = 5

    private final class VisitTracker {
        var visited = Set<String>()
    }

    typealias FetchHandler = (
        _ urlString: String,
        _ completion: @escaping (Result<String, BidscubeRequestError>) -> Void
    ) -> Void

    /// Injectable for unit tests (URLProtocol-backed mocks).
    static var fetchHandler: FetchHandler = { urlString, completion in
        let trimmed = VastParser.decodeXMLEntities(urlString.trimmingCharacters(in: .whitespacesAndNewlines))
        guard let url = URL(string: trimmed) else {
            completion(.failure(BidscubeRequestError(
                errorCode: AdErrorCode.invalidResponse,
                message: "Invalid VAST URL"
            )))
            return
        }
        AdHTTPClient.fetchBody(url: url, completion: completion)
    }

    static func resolve(
        source: String,
        isURL: Bool,
        completion: @escaping (Result<ResolvedVastAd, VastResolutionFailure>) -> Void
    ) {
        let tracker = VisitTracker()
        if isURL {
            let normalized = VastParser.decodeXMLEntities(source.trimmingCharacters(in: .whitespacesAndNewlines))
            fetchChain(
                urlString: normalized,
                redirectsRemaining: maxRedirects,
                wrapperLayers: [],
                tracker: tracker,
                completion: completion
            )
        } else {
            resolveDocument(
                vastXml: source,
                redirectsRemaining: maxRedirects,
                wrapperLayers: [],
                tracker: tracker,
                completion: completion
            )
        }
    }

    private static func fetchChain(
        urlString: String,
        redirectsRemaining: Int,
        wrapperLayers: [VastWrapperMetadata],
        tracker: VisitTracker,
        completion: @escaping (Result<ResolvedVastAd, VastResolutionFailure>) -> Void
    ) {
        let normalized = urlString.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        if tracker.visited.contains(normalized) {
            completion(.failure(makeFailure(
                code: AdErrorCode.invalidResponse,
                message: "Cyclic VAST wrapper redirect detected",
                vastErrorCode: 302,
                wrapperLayers: wrapperLayers
            )))
            return
        }
        tracker.visited.insert(normalized)

        fetchHandler(urlString) { result in
            switch result {
            case .failure(let error):
                completion(.failure(makeFailure(
                    requestError: error,
                    vastErrorCode: 301,
                    wrapperLayers: wrapperLayers
                )))
            case .success(let body):
                resolveDocument(
                    vastXml: body,
                    redirectsRemaining: redirectsRemaining,
                    wrapperLayers: wrapperLayers,
                    tracker: tracker,
                    completion: completion
                )
            }
        }
    }

    private static func resolveDocument(
        vastXml: String,
        redirectsRemaining: Int,
        wrapperLayers: [VastWrapperMetadata],
        tracker: VisitTracker,
        completion: @escaping (Result<ResolvedVastAd, VastResolutionFailure>) -> Void
    ) {
        if let inline = VastParser.parseInlineAd(from: vastXml) {
            completion(.success(buildResolvedAd(inline: inline, wrapperLayers: wrapperLayers)))
            return
        }

        if VastParser.isInlineVAST(vastXml) {
            completion(.failure(makeFailure(
                code: AdErrorCode.invalidResponse,
                message: "Unsupported or missing progressive MP4 media file",
                vastErrorCode: 403,
                wrapperLayers: wrapperLayers
            )))
            return
        }

        guard VastParser.isWrapperVAST(vastXml) else {
            completion(.failure(makeFailure(
                code: AdErrorCode.invalidResponse,
                message: "Unable to resolve VAST inline ad",
                vastErrorCode: 303,
                wrapperLayers: wrapperLayers
            )))
            return
        }

        guard redirectsRemaining > 0 else {
            completion(.failure(makeFailure(
                code: AdErrorCode.invalidResponse,
                message: "VAST wrapper redirect limit exceeded",
                vastErrorCode: 302,
                wrapperLayers: wrapperLayers
            )))
            return
        }

        guard let wrapperURL = VastParser.wrapperTagURI(in: vastXml) else {
            completion(.failure(makeFailure(
                code: AdErrorCode.invalidResponse,
                message: "VAST wrapper missing VASTAdTagURI",
                vastErrorCode: 303,
                wrapperLayers: wrapperLayers
            )))
            return
        }

        var layers = wrapperLayers
        layers.append(VastParser.parseWrapperMetadata(from: vastXml))

        fetchChain(
            urlString: wrapperURL,
            redirectsRemaining: redirectsRemaining - 1,
            wrapperLayers: layers,
            tracker: tracker,
            completion: completion
        )
    }

    private static func buildResolvedAd(
        inline: VastInlineAd,
        wrapperLayers: [VastWrapperMetadata]
    ) -> ResolvedVastAd {
        var impressionURLs: [[String]] = wrapperLayers.map(\.impressionUrls)
        impressionURLs.append(inline.impressionUrls)

        var errorURLs: [[String]] = wrapperLayers.map(\.errorUrls)
        errorURLs.append(inline.errorUrls)

        var clickTrackingURLs: [[String]] = wrapperLayers.map(\.clickTrackingUrls)
        clickTrackingURLs.append(inline.clickTrackingUrls)

        var trackingLayers: [[String: [String]]] = wrapperLayers.map(\.trackingEvents)
        trackingLayers.append(inline.trackingEvents)

        let wrapperCompanions = wrapperLayers.compactMap(\.companion)
        let inlineCompanion = VastParser.selectPostVideoCompanion(inline.vastXml)
        let selectedCompanion = VastParser.selectBestCompanion(
            inlineCompanion: inlineCompanion,
            wrapperCompanions: wrapperCompanions
        )

        var creativeViewURLs: [String] = wrapperLayers.flatMap(\.companionCreativeViewUrls)
        if let selectedCompanion {
            creativeViewURLs.append(contentsOf: selectedCompanion.creativeViewTrackingUrls)
        }

        return ResolvedVastAd(
            inlineAd: inline,
            mergedImpressionURLs: mergeUnique(impressionURLs),
            mergedErrorURLs: mergeUnique(errorURLs),
            mergedTrackingEvents: mergeTrackingEvents(trackingLayers),
            mergedClickTrackingURLs: mergeUnique(clickTrackingURLs),
            companionCreativeViewURLs: mergeUnique([creativeViewURLs]),
            companion: selectedCompanion,
            vastXml: inline.vastXml
        )
    }

    static func collectedErrorURLs(from layers: [VastWrapperMetadata]) -> [String] {
        mergeUnique(layers.map(\.errorUrls))
    }

    private static func makeFailure(
        code: Int,
        message: String,
        vastErrorCode: Int,
        wrapperLayers: [VastWrapperMetadata]
    ) -> VastResolutionFailure {
        makeFailure(
            requestError: BidscubeRequestError(errorCode: code, message: message),
            vastErrorCode: vastErrorCode,
            wrapperLayers: wrapperLayers
        )
    }

    private static func makeFailure(
        requestError: BidscubeRequestError,
        vastErrorCode: Int,
        wrapperLayers: [VastWrapperMetadata]
    ) -> VastResolutionFailure {
        VastResolutionFailure(
            requestError: requestError,
            vastErrorCode: vastErrorCode,
            collectedErrorURLs: collectedErrorURLs(from: wrapperLayers)
        )
    }

    static func mergeUnique(_ layers: [[String]]) -> [String] {
        var seen = Set<String>()
        var result: [String] = []
        for layer in layers {
            for raw in layer {
                let url = VastParser.decodeXMLEntities(raw.trimmingCharacters(in: .whitespacesAndNewlines))
                guard !url.isEmpty, !seen.contains(url) else { continue }
                seen.insert(url)
                result.append(url)
            }
        }
        return result
    }

    static func mergeTrackingEvents(_ layers: [[String: [String]]]) -> [String: [String]] {
        var merged: [String: [String]] = [:]
        for layer in layers {
            for (event, urls) in layer {
                let key = event.lowercased()
                merged[key, default: []].append(contentsOf: urls)
            }
        }
        return merged.mapValues { mergeUnique([$0]) }
    }
}
