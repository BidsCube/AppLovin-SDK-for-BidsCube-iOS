import Testing
@testable import BidscubeSDK

struct FullscreenVideoSessionControllerTests {
    private let vastNoCompanion = """
    <?xml version="1.0"?><VAST version="3.0"><Ad><InLine><Creatives>
    <Creative><Linear><Duration>00:00:15</Duration><MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4">https://example.com/v.mp4</MediaFile>
    </MediaFiles></Linear></Creative></Creatives></InLine></Ad></VAST>
    """

    private let vastStatic = """
    <?xml version="1.0"?><VAST version="3.0"><Ad><InLine><Creatives>
    <Creative><Linear><Duration>00:00:15</Duration><MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4">https://example.com/v.mp4</MediaFile>
    </MediaFiles></Linear><CompanionAds><Companion width="300" height="250">
    <StaticResource creativeType="image/jpeg">https://example.com/end.jpg</StaticResource>
    </Companion></CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    private let vastHtml = """
    <?xml version="1.0"?><VAST version="3.0"><Ad><InLine><Creatives>
    <Creative><Linear><Duration>00:00:15</Duration><MediaFiles>
    <MediaFile delivery="progressive" type="video/mp4">https://example.com/v.mp4</MediaFile>
    </MediaFiles></Linear><CompanionAds><Companion width="300" height="250">
    <HTMLResource><![CDATA[<html><body>Play</body></html>]]></HTMLResource>
    </Companion></CompanionAds></Creative></Creatives></InLine></Ad></VAST>
    """

    @Test func defaultAutoCloseIsFalse() {
        #expect(SDKConfig.Builder().build().autoClose == false)
    }

    @Test func explicitAutoCloseTrueAndFalse() {
        #expect(SDKConfig.Builder().autoClose(true).build().autoClose == true)
        #expect(SDKConfig.Builder().autoClose(false).build().autoClose == false)
    }

    @Test func autoCloseTrueDismissesWithoutCompanion() {
        let session = FullscreenVideoSessionController(autoClose: true, playerManagesPostVideo: false, vastXml: vastNoCompanion)
        #expect(session.shouldFireLinearCompleted())
        let action = session.onLinearCompleted()
        #expect(action.dismissDialog)
        #expect(action.fireAdClosed)
        #expect(action.releasePlayer)
        #expect(!action.showStaticCompanionEndCard)
    }

    @Test func autoCloseTrueAlsoDismissesWithCompanion() {
        let session = FullscreenVideoSessionController(autoClose: true, playerManagesPostVideo: false, vastXml: vastStatic)
        let action = session.onLinearCompleted()
        #expect(action.dismissDialog)
        #expect(action.fireAdClosed)
        #expect(!action.showStaticCompanionEndCard)
    }

    @Test func autoCloseFalseWithoutCompanionKeepsOpenWithCloseButton() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastNoCompanion)
        #expect(session.shouldFireLinearCompleted())
        let action = session.onLinearCompleted()
        #expect(!action.dismissDialog)
        #expect(!action.fireAdClosed)
        #expect(action.showManualCloseButton)
        #expect(action.keepPlayerVisible)
        #expect(!action.releasePlayer)
    }

    @Test func autoCloseFalseWithStaticCompanionShowsEndCardOnLinearComplete() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastStatic)
        let action = session.onLinearCompleted()
        #expect(action.showStaticCompanionEndCard)
        #expect(!action.showManualCloseButton)
        #expect(!action.dismissDialog)
        #expect(action.releasePlayer)
    }

    @Test func imaLinearCompleteKeepsPlayerForPostVideoExperience() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastNoCompanion)
        let action = session.onLinearCompleted()
        #expect(action.keepPlayerVisible)
        #expect(!action.releasePlayer)
        #expect(action.showManualCloseButton)
        #expect(!action.dismissDialog)
    }

    @Test func imaAllAdsCompletedWithHtmlCompanionReleasesPlayerAndShowsHtml() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastHtml)
        session.onLinearCompleted()
        let action = session.onAdSessionCompleted()
        #expect(action.releasePlayer)
        #expect(action.hidePlayer)
        #expect(action.showHtmlCompanionEndCard)
        #expect(!action.showStaticCompanionEndCard)
        #expect(!action.dismissDialog)
    }

    @Test func imaAllAdsCompletedWithStaticCompanionReleasesPlayerAndShowsStatic() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastStatic)
        session.onLinearCompleted()
        let action = session.onAdSessionCompleted()
        #expect(action.releasePlayer)
        #expect(action.showStaticCompanionEndCard)
        #expect(!action.showHtmlCompanionEndCard)
    }

    @Test func imaAllAdsCompletedWithoutCompanionDoesNotReleasePlayer() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastNoCompanion)
        session.onLinearCompleted()
        let action = session.onAdSessionCompleted()
        #expect(action.isNoop)
    }

    @Test func nonImaCompanionLinearThenSessionSecondActionIsNoop() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastStatic)
        let linear = session.onLinearCompleted()
        #expect(linear.showStaticCompanionEndCard)
        let sessionAction = session.onAdSessionCompleted()
        #expect(sessionAction.isNoop)
    }

    @Test func skipManualModeDoesNotShowCompanion() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastStatic)
        let action = session.onSkipped()
        #expect(action.releasePlayer)
        #expect(action.hidePlayer)
        #expect(action.showManualCloseButton)
        #expect(!action.showStaticCompanionEndCard)
        #expect(!action.showHtmlCompanionEndCard)
        #expect(!action.dismissDialog)
    }

    @Test func duplicateCompletedDoesNotDuplicateCallbacks() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastNoCompanion)
        #expect(session.shouldFireLinearCompleted())
        #expect(!session.shouldFireLinearCompleted())
        let first = session.onLinearCompleted()
        let second = session.onLinearCompleted()
        #expect(first.showManualCloseButton)
        #expect(second.isNoop)
    }

    @Test func duplicateAllAdsCompletedDoesNotDuplicateOverlay() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastHtml)
        session.onLinearCompleted()
        let first = session.onAdSessionCompleted()
        let second = session.onAdSessionCompleted()
        #expect(first.showHtmlCompanionEndCard)
        #expect(second.isNoop)
    }

    @Test func userCloseFiresOnce() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: true, vastXml: vastNoCompanion)
        session.onLinearCompleted()
        let first = session.onUserClose()
        let second = session.onUserClose()
        #expect(first.fireAdClosed)
        #expect(second.isNoop)
    }

    @Test func skipDoesNotFireLinearCompletedAfterSkip() {
        let session = FullscreenVideoSessionController(autoClose: false, playerManagesPostVideo: false, vastXml: vastNoCompanion)
        #expect(session.shouldFireSkipped())
        #expect(!session.shouldFireLinearCompleted())
    }
}
