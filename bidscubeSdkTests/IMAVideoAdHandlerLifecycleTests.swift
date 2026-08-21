import Foundation
import Testing
import UIKit
#if SWIFT_PACKAGE
@testable import BidscubeSDKAppLovin
#else
@testable import BidscubeSDK
#endif

@Suite(.serialized)
@MainActor
struct IMAVideoAdHandlerLifecycleTests {
    private final class HostViewController: UIViewController {
        let handler: IMAVideoAdHandler

        init(handler: IMAVideoAdHandler) {
            self.handler = handler
            super.init(nibName: nil, bundle: nil)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            handler.frame = view.bounds
            handler.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            view.addSubview(handler)
        }
    }

    private func makeAttachedHandler() -> (UIKitTestHost, IMAVideoAdHandler, HostViewController) {
        let host = UIKitTestHost()
        let handler = IMAVideoAdHandler(vastXML: "<VAST version=\"3.0\"></VAST>")
        handler.setPlacementInfo("ima-test", callback: nil)
        let hostVC = HostViewController(handler: handler)
        host.navigationController.pushViewController(hostVC, animated: false)
        handler.setParentViewController(hostVC)
        return (host, handler, hostVC)
    }

    @Test func refreshIMASetupTwiceBeforeRequestCreatesOneContainer() async {
        let (host, handler, _) = makeAttachedHandler()
        defer { host.tearDown() }
        _ = await host.waitUntil { handler.window != nil }

        handler.refreshIMASetup()
        handler.refreshIMASetup()

        #expect(handler.bidscubeTesting_containerCreatedCount == 1)
        #expect(handler.bidscubeTesting_adDisplayContainer != nil)
    }

    @Test func loadAdTwiceRejectsDuplicateRequest() async {
        let (host, handler, _) = makeAttachedHandler()
        defer { host.tearDown() }
        _ = await host.waitUntil { handler.window != nil }

        handler.loadAd()
        let firstCount = handler.bidscubeTesting_requestAdsCount
        handler.loadAd()
        #expect(firstCount == 1)
        #expect(handler.bidscubeTesting_requestAdsCount == 1)
        #expect(handler.bidscubeTesting_hasRequestedAds)
    }

    @Test func refreshAfterRequestIsBlocked() async {
        let (host, handler, _) = makeAttachedHandler()
        defer { host.tearDown() }
        _ = await host.waitUntil { handler.window != nil }

        handler.loadAd()
        let containerBefore = handler.bidscubeTesting_activeContainerId
        handler.refreshIMASetup()
        #expect(handler.bidscubeTesting_activeContainerId == containerBefore)
        #expect(handler.bidscubeTesting_containerCreatedCount == 1)
    }

    @Test func cleanupClearsReferences() async {
        let (host, handler, _) = makeAttachedHandler()
        defer { host.tearDown() }
        _ = await host.waitUntil { handler.window != nil }

        handler.refreshIMASetup()
        handler.cleanup()

        #expect(handler.bidscubeTesting_adDisplayContainer == nil)
        #expect(handler.bidscubeTesting_adsLoader == nil)
        #expect(handler.bidscubeTesting_playerLayer == nil)
        #expect(handler.bidscubeTesting_activeContainerId == nil)
        #expect(!handler.bidscubeTesting_hasRequestedAds)
    }

    @Test func missingStablePresenterDoesNotCreateContainer() async {
        let handler = IMAVideoAdHandler(vastXML: "<VAST version=\"3.0\"></VAST>")
        handler.setPlacementInfo("ima-detached", callback: nil)
        handler.refreshIMASetup()
        #expect(handler.bidscubeTesting_containerCreatedCount == 0)
        #expect(handler.bidscubeTesting_adDisplayContainer == nil)
    }
}
