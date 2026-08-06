import Foundation
import Testing
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

@Suite(.serialized)
struct VastResolverTests {
    private let inlineVAST = """
    <VAST version="3.0"><Ad><InLine>
    <Impression><![CDATA[https://inline.example/impression]]></Impression>
    <Error><![CDATA[https://inline.example/error?code=[ERRORCODE]]]></Error>
    <Creatives><Creative><Linear>
    <TrackingEvents>
    <Tracking event="start"><![CDATA[https://inline.example/start]]></Tracking>
    </TrackingEvents>
    <VideoClicks>
    <ClickThrough><![CDATA[https://inline.example/click]]></ClickThrough>
    <ClickTracking><![CDATA[https://inline.example/clicktrack]]></ClickTracking>
    </VideoClicks>
    <MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4"><![CDATA[https://cdn.example/video.mp4]]></MediaFile>
    </MediaFiles>
    </Linear></Creative></Creatives>
    </InLine></Ad></VAST>
    """

    private let inlineCompanionVAST = """
    <VAST version="3.0"><Ad><InLine>
    <Creatives><Creative>
    <Linear>
    <MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4"><![CDATA[https://cdn.example/video.mp4]]></MediaFile>
    </MediaFiles>
    </Linear>
    <CompanionAds><Companion width="300" height="250">
    <StaticResource creativeType="image/jpeg"><![CDATA[https://inline.example/end.jpg]]></StaticResource>
    <CompanionClickThrough><![CDATA[https://inline.example/companion-click]]></CompanionClickThrough>
    </Companion></CompanionAds>
    </Creative></Creatives>
    </InLine></Ad></VAST>
    """

    private let wrapperVAST = { (tagURI: String) in """
    <VAST version="3.0"><Ad><Wrapper>
    <Impression><![CDATA[https://wrapper.example/impression]]></Impression>
    <Error><![CDATA[https://wrapper.example/error]]></Error>
    <VASTAdTagURI><![CDATA[\(tagURI)]]></VASTAdTagURI>
    <Creatives><Creative><Linear>
    <TrackingEvents>
    <Tracking event='start'><![CDATA[https://wrapper.example/start]]></Tracking>
    </TrackingEvents>
    <VideoClicks><ClickTracking><![CDATA[https://wrapper.example/clicktrack]]></ClickTracking></VideoClicks>
    <CompanionAds><Companion width="300" height="250">
    <StaticResource creativeType="image/jpeg"><![CDATA[https://wrapper.example/end.jpg]]></StaticResource>
    </Companion></CompanionAds>
    </Linear></Creative></Creatives>
    </Wrapper></Ad></VAST>
    """ }

    @Test func inlineWithoutWrapper() async {
        let resolved = await resolve(source: inlineVAST, isURL: false)
        #expect(resolved?.mergedImpressionURLs == ["https://inline.example/impression"])
        #expect(resolved?.mergedClickTrackingURLs == ["https://inline.example/clicktrack"])
        #expect(resolved?.mergedTrackingEvents["start"] == ["https://inline.example/start"])
        #expect(resolved?.inlineAd.mediaURL.absoluteString == "https://cdn.example/video.mp4")
    }

    @Test func singleWrapperMergesTracking() async {
        let fetchMap = [
            "https://wrapper.example/next": inlineVAST
        ]
        let resolved = await resolve(
            source: wrapperVAST("https://wrapper.example/next"),
            isURL: false,
            fetchMap: fetchMap
        )
        #expect(resolved?.mergedImpressionURLs == [
            "https://wrapper.example/impression",
            "https://inline.example/impression"
        ])
        #expect(resolved?.mergedTrackingEvents["start"] == [
            "https://wrapper.example/start",
            "https://inline.example/start"
        ])
        #expect(resolved?.mergedClickTrackingURLs == [
            "https://wrapper.example/clicktrack",
            "https://inline.example/clicktrack"
        ])
    }

    @Test func multipleWrappersMergeAllLayers() async {
        let innerWrapper = wrapperVAST("https://wrapper.example/inline")
        let fetchMap = [
            "https://wrapper.example/middle": innerWrapper,
            "https://wrapper.example/inline": inlineVAST
        ]
        let outer = """
        <VAST><Ad><Wrapper>
        <Impression><![CDATA[https://outer.example/impression]]></Impression>
        <VASTAdTagURI><![CDATA[https://wrapper.example/middle]]></VASTAdTagURI>
        </Wrapper></Ad></VAST>
        """
        let resolved = await resolve(source: outer, isURL: false, fetchMap: fetchMap)
        #expect(resolved?.mergedImpressionURLs == [
            "https://outer.example/impression",
            "https://wrapper.example/impression",
            "https://inline.example/impression"
        ])
    }

    @Test func cyclicWrapperFails() async {
        let cyclic = wrapperVAST("https://wrapper.example/loop")
        let fetchMap = ["https://wrapper.example/loop": cyclic]
        let failure = await resolveFailure(source: cyclic, isURL: false, fetchMap: fetchMap)
        #expect(failure?.requestError.message.contains("Cyclic") == true)
        #expect(failure?.vastErrorCode == 302)
    }

    @Test func redirectLimitFails() async {
        var fetchMap: [String: String] = [:]
        for index in 0..<6 {
            fetchMap["https://wrapper.example/step\(index)"] = wrapperVAST("https://wrapper.example/step\(index + 1)")
        }
        let failure = await resolveFailure(
            source: wrapperVAST("https://wrapper.example/step0"),
            isURL: false,
            fetchMap: fetchMap
        )
        #expect(failure?.requestError.message.contains("redirect limit") == true)
        #expect(failure?.vastErrorCode == 302)
    }

    @Test func missingWrapperURLFails() async {
        let vast = "<VAST><Ad><Wrapper></Wrapper></Ad></VAST>"
        let failure = await resolveFailure(source: vast, isURL: false)
        #expect(failure?.requestError.message.contains("VASTAdTagURI") == true)
        #expect(failure?.vastErrorCode == 303)
    }

    @Test func wrapperChainWithoutInlineFails() async {
        let onlyWrapper = wrapperVAST("https://wrapper.example/missing")
        let failure = await resolveFailure(source: onlyWrapper, isURL: false, fetchMap: [:])
        #expect(failure != nil)
        #expect(failure?.vastErrorCode == 301)
        #expect(failure?.collectedErrorURLs.contains("https://wrapper.example/error") == true)
    }

    @Test func inlineWithoutSupportedMp4FailsWith403() async {
        let vast = """
        <VAST><Ad><InLine><Creatives><Creative><Linear>
        <MediaFiles>
        <MediaFile delivery="progressive" type="video/webm"><![CDATA[https://cdn.example/video.webm]]></MediaFile>
        </MediaFiles>
        </Linear></Creative></Creatives></InLine></Ad></VAST>
        """
        let failure = await resolveFailure(source: vast, isURL: false)
        #expect(failure?.vastErrorCode == 403)
    }

    @Test func unavailableWrapperURLFailsWithCollectedErrorURLs() async {
        let failure = await resolveFailure(
            source: wrapperVAST("https://wrapper.example/missing"),
            isURL: false,
            fetchMap: [:]
        )
        #expect(failure?.vastErrorCode == 301)
        #expect(failure?.collectedErrorURLs == ["https://wrapper.example/error"])
    }

    @Test func wrapperURLDecodesXMLEntities() async {
        let encoded = wrapperVAST("https://wrapper.example/next?a=1&amp;b=2")
        let fetchMap = ["https://wrapper.example/next?a=1&b=2": inlineVAST]
        let resolved = await resolve(source: encoded, isURL: false, fetchMap: fetchMap)
        #expect(resolved?.inlineAd.mediaURL.absoluteString == "https://cdn.example/video.mp4")
    }

    @Test func inlineCompanionPreferredOverWrapperCompanion() async {
        let fetchMap = ["https://wrapper.example/next": inlineCompanionVAST]
        let resolved = await resolve(
            source: wrapperVAST("https://wrapper.example/next"),
            isURL: false,
            fetchMap: fetchMap
        )
        #expect(resolved?.companion?.resource == "https://inline.example/end.jpg")
        #expect(resolved?.companion?.clickThroughUrl == "https://inline.example/companion-click")
    }

    @Test func wrapperCompanionFallbackWhenInlineMissing() async {
        let fetchMap = ["https://wrapper.example/next": inlineVAST]
        let resolved = await resolve(
            source: wrapperVAST("https://wrapper.example/next"),
            isURL: false,
            fetchMap: fetchMap
        )
        #expect(resolved?.companion?.resource == "https://wrapper.example/end.jpg")
    }

    @Test func mergeUniqueDeduplicatesURLs() {
        let merged = VastResolver.mergeUnique([
            ["https://a.example/ping", "https://b.example/ping"],
            ["https://a.example/ping", "https://c.example/ping"]
        ])
        #expect(merged == [
            "https://a.example/ping",
            "https://b.example/ping",
            "https://c.example/ping"
        ])
    }

    private func withMockFetch<T>(
        _ fetchMap: [String: String],
        _ operation: () async -> T
    ) async -> T {
        let previous = VastResolver.fetchHandler
        defer { VastResolver.fetchHandler = previous }
        VastResolver.fetchHandler = { urlString, completion in
            let normalized = VastParser.decodeXMLEntities(urlString.trimmingCharacters(in: .whitespacesAndNewlines))
            if let body = fetchMap[normalized] {
                completion(.success(body))
            } else {
                completion(.failure(BidscubeRequestError(
                    errorCode: AdErrorCode.networkError,
                    message: "Mock fetch failed for \(normalized)"
                )))
            }
        }
        return await operation()
    }

    private func resolve(
        source: String,
        isURL: Bool,
        fetchMap: [String: String] = [:]
    ) async -> ResolvedVastAd? {
        await withMockFetch(fetchMap) {
            await withCheckedContinuation { continuation in
                VastResolver.resolve(source: source, isURL: isURL) { result in
                    continuation.resume(returning: try? result.get())
                }
            }
        }
    }

    private func resolveFailure(
        source: String,
        isURL: Bool,
        fetchMap: [String: String] = [:]
    ) async -> VastResolutionFailure? {
        await withMockFetch(fetchMap) {
            await withCheckedContinuation { continuation in
                VastResolver.resolve(source: source, isURL: isURL) { result in
                    switch result {
                    case .failure(let failure):
                        continuation.resume(returning: failure)
                    case .success:
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
}

struct VastTrackingMacroTests {
    @Test func replacesKnownMacros() {
        let context = VastTrackingContext(playheadSeconds: 65.5, assetURI: "https://cdn.example/video.mp4")
        let url = "https://track.example/ping?e=[ERRORCODE]&cb=[CACHEBUSTING]&buster=[CACHEBUSTER]&rnd=[RANDOM]&ph=[CONTENTPLAYHEAD]&asset=[ASSETURI]"
        let replaced = VastTrackingMacroReplacer.replace(url, context: context, errorCode: 403)
        #expect(replaced.contains("e=403"))
        #expect(!replaced.contains("[ERRORCODE]"))
        #expect(!replaced.contains("[CACHEBUSTING]"))
        #expect(!replaced.contains("[CACHEBUSTER]"))
        #expect(!replaced.contains("[RANDOM]"))
        #expect(replaced.contains("ph=00:01:05.500"))
        #expect(replaced.contains("asset=https"))
    }
}

#if canImport(SwiftUI)
import SwiftUI

@Suite(.serialized)
struct SwiftUIAPIAvailabilityTests {
    @Test(.disabled("Validated by sample/legacy integration builds; runtime construction can perturb parallel unit tests"))
    func adViewControllerViewCompiles() {
        _ = BidscubeSDK.getAdViewControllerView("placement", adType: .video, nil)
    }

    #if !BIDSCUBE_LEGACY_VIDEO
    @Test(.disabled("Validated by modern sample builds; runtime construction can perturb parallel unit tests"))
    func imaVideoAdViewCompilesInModernBuild() {
        _ = BidscubeSDK.getIMAVideoAdView("placement", nil)
    }
    #endif
}
#endif
