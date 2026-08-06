import Testing
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

struct VastParserInlineTests {
    private let vastInlineMP4 = """
    <VAST version="3.0"><Ad><InLine>
    <Impression><![CDATA[https://track.example/impression]]></Impression>
    <Error><![CDATA[https://track.example/error]]></Error>
    <Creatives><Creative><Linear>
    <TrackingEvents>
    <Tracking event="start"><![CDATA[https://track.example/start]]></Tracking>
    <Tracking event="firstQuartile"><![CDATA[https://track.example/q1]]></Tracking>
    </TrackingEvents>
    <VideoClicks>
    <ClickThrough><![CDATA[https://click.example/through]]></ClickThrough>
    <ClickTracking><![CDATA[https://track.example/click]]></ClickTracking>
    </VideoClicks>
    <MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4"><![CDATA[https://cdn.example/video.mp4]]></MediaFile>
    </MediaFiles>
    </Linear></Creative></Creatives>
    </InLine></Ad></VAST>
    """

    private let vastWrapper = """
    <VAST version="3.0"><Ad><Wrapper>
    <VASTAdTagURI><![CDATA[https://ssp.example/vast/inline]]></VASTAdTagURI>
    </Wrapper></Ad></VAST>
    """

    @Test func parseInlineAdExtractsMP4AndTracking() {
        let inline = VastParser.parseInlineAd(from: vastInlineMP4)
        #expect(inline != nil)
        #expect(inline?.mediaURL.absoluteString == "https://cdn.example/video.mp4")
        #expect(inline?.impressionUrls == ["https://track.example/impression"])
        #expect(inline?.clickThroughUrl == "https://click.example/through")
        #expect(inline?.clickTrackingUrls == ["https://track.example/click"])
        #expect(inline?.trackingEvents["start"] == ["https://track.example/start"])
        #expect(inline?.trackingEvents["firstquartile"] == ["https://track.example/q1"])
        #expect(inline?.errorUrls == ["https://track.example/error"])
    }

    @Test func wrapperTagURIParses() {
        #expect(VastParser.wrapperTagURI(in: vastWrapper) == "https://ssp.example/vast/inline")
        #expect(VastParser.parseInlineAd(from: vastWrapper) == nil)
    }
}
