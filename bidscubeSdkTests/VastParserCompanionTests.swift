import Testing
@testable import BidscubeSDK

struct VastParserCompanionTests {
    private let vastStatic = """
    <VAST><Ad><InLine><Creatives><Creative><CompanionAds>
    <Companion width="300" height="250">
    <StaticResource creativeType="image/jpeg"><![CDATA[https://example.com/static.jpg]]></StaticResource>
    <CompanionClickThrough>https://click.example/static</CompanionClickThrough>
    <CompanionClickTracking>https://track.example/click1</CompanionClickTracking>
    </Companion></CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    private let vastHtml = """
    <VAST><Ad><InLine><Creatives><Creative><CompanionAds>
    <Companion width="320" height="480">
    <HTMLResource><![CDATA[<a href='x'>html</a>]]></HTMLResource>
    <CompanionClickThrough>https://click.example/html</CompanionClickThrough>
    </Companion></CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    private let vastIframe = """
    <VAST><Ad><InLine><Creatives><Creative><CompanionAds>
    <Companion width="320" height="480">
    <IFrameResource><![CDATA[https://example.com/frame.html]]></IFrameResource>
    </Companion></CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    private let vastMultiple = """
    <VAST><Ad><InLine><Creatives><Creative><CompanionAds>
    <Companion width="300" height="250">
    <StaticResource creativeType="image/jpeg"><![CDATA[https://example.com/static.jpg]]></StaticResource>
    </Companion>
    <Companion width="320" height="480">
    <HTMLResource><![CDATA[<div>win</div>]]></HTMLResource>
    </Companion>
    </CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    @Test func staticCompanionParsesResourceAndClick() {
        let companion = VastParser.selectPostVideoCompanion(vastStatic)
        #expect(companion?.resourceType == .static)
        #expect(companion?.resource == "https://example.com/static.jpg")
        #expect(companion?.clickThroughUrl == "https://click.example/static")
        #expect(companion?.clickTrackingUrls.count == 1)
        #expect(VastParser.hasCompanionPreview(vastStatic))
    }

    @Test func htmlCompanionParsesHtmlResource() {
        let companion = VastParser.selectPostVideoCompanion(vastHtml)
        #expect(companion?.resourceType == .html)
        #expect(companion?.resource.contains("html") == true)
        #expect(VastParser.hasHtmlCompanion(vastHtml))
    }

    @Test func iframeCompanionParsesIframeResource() {
        let companion = VastParser.selectPostVideoCompanion(vastIframe)
        #expect(companion?.resourceType == .iframe)
        #expect(companion?.resource == "https://example.com/frame.html")
    }

    @Test func htmlPreferredOverStaticWhenMultipleCompanions() {
        let companion = VastParser.selectPostVideoCompanion(vastMultiple)
        #expect(companion?.resourceType == .html)
    }

    @Test func skipOffsetParsesFromVastLinearAttribute() {
        let vast = """
        <VAST><Ad><InLine><Creatives><Creative><Linear skipoffset="00:00:10"><Duration>00:00:30</Duration></Linear></Creative></Creatives></InLine></Ad></VAST>
        """
        #expect(VastParser.getSkipOffsetMs(vast) == 10_000)
        #expect(VastParser.resolveSkipSeconds(vastXml: vast) == 10)
    }

    @Test func skipOffsetDefaultsToFifteenSecondsWhenMissing() {
        let vast = """
        <VAST><Ad><InLine><Creatives><Creative><Linear><Duration>00:00:30</Duration></Linear></Creative></Creatives></InLine></Ad></VAST>
        """
        #expect(VastParser.getSkipOffsetMs(vast) == -1)
        #expect(VastParser.resolveSkipSeconds(vastXml: vast) == 15)
        #expect(VastParser.resolveSkipSeconds(vastXml: nil) == 15)
    }

    @Test func skipOffsetPercentUsesDuration() {
        let vast = """
        <VAST><Ad><InLine><Creatives><Creative><Linear skipoffset="50%"><Duration>00:00:20</Duration></Linear></Creative></Creatives></InLine></Ad></VAST>
        """
        #expect(VastParser.getSkipOffsetMs(vast) == 10_000)
        #expect(VastParser.resolveSkipSeconds(vastXml: vast) == 10)
    }
}
