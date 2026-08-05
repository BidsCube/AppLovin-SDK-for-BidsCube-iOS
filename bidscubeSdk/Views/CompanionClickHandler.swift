import Foundation
import UIKit

enum CompanionUrlSafety {
    static func isBlockedScheme(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return true }
        return ["javascript", "file", "content", "data"].contains(scheme)
    }

    static func isHttpOrHttps(_ url: URL) -> Bool {
        guard let scheme = url.scheme?.lowercased() else { return false }
        return scheme == "http" || scheme == "https"
    }

    @discardableResult
    static func openExternal(_ url: URL) -> Bool {
        guard isHttpOrHttps(url), !isBlockedScheme(url) else { return false }
        DispatchQueue.main.async {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return true
    }
}

final class CompanionClickHandler {
    private let companionAd: CompanionAd
    private var clickFired = false
    private var creativeViewFired = false

    init(companionAd: CompanionAd) {
        self.companionAd = companionAd
    }

    func fireCreativeViewOnce() {
        guard !creativeViewFired else { return }
        creativeViewFired = true
        TrackerPinger.pingUrls("vast.companion.creativeView", companionAd.creativeViewTrackingUrls)
    }

    func handleClick(placementId: String, callback: AdCallback?) {
        TrackerPinger.pingUrls("vast.companion.clickTracking", companionAd.clickTrackingUrls)
        if let clickThrough = companionAd.clickThroughUrl, let url = URL(string: clickThrough) {
            CompanionUrlSafety.openExternal(url)
        }
        guard !clickFired else { return }
        clickFired = true
        callback?.onAdClicked(placementId)
    }

    func handleExternalNavigation(_ url: URL, placementId: String, callback: AdCallback?) -> Bool {
        guard !CompanionUrlSafety.isBlockedScheme(url) else { return true }
        guard CompanionUrlSafety.openExternal(url) else { return true }
        TrackerPinger.pingUrls("vast.companion.clickTracking", companionAd.clickTrackingUrls)
        guard !clickFired else { return true }
        clickFired = true
        callback?.onAdClicked(placementId)
        return true
    }
}
