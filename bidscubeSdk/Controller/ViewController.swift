import UIKit
import bidscubeSdk

final class ViewController: UIViewController, AdCallback, ConsentCallback {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let imageView = BidscubeSDK.getImageAdView("20212", self)
        imageView.translatesAutoresizingMaskIntoConstraints = false

        let videoView = BidscubeSDK.getVideoAdView("20213", self)
        videoView.translatesAutoresizingMaskIntoConstraints = false

        let nativeView = BidscubeSDK.getNativeAdView("20214", self)
        nativeView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(imageView)
        view.addSubview(videoView)
        view.addSubview(nativeView)

        NSLayoutConstraint.activate([
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            imageView.heightAnchor.constraint(equalToConstant: 180),

            videoView.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 16),
            videoView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            videoView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            videoView.heightAnchor.constraint(equalToConstant: 200),

            nativeView.topAnchor.constraint(equalTo: videoView.bottomAnchor, constant: 16),
            nativeView.leadingAnchor.constraint(equalTo: imageView.leadingAnchor),
            nativeView.trailingAnchor.constraint(equalTo: imageView.trailingAnchor),
            nativeView.heightAnchor.constraint(equalToConstant: 120),
        ])
    }

    func onAdLoading(_ placementId: String) {}
    func onAdLoaded(_ placementId: String) {}
    func onAdDisplayed(_ placementId: String) {}
    func onAdClicked(_ placementId: String) {
        print("🎯 Ad clicked for placement: \(placementId)")
    }
    func onAdClosed(_ placementId: String) {}
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}

    func onVideoAdStarted(_ placementId: String) {}
    func onVideoAdCompleted(_ placementId: String) {}
    func onVideoAdSkipped(_ placementId: String) {}
    func onVideoAdSkippable(_ placementId: String) {}
    func onInstallButtonClicked(_ placementId: String, buttonText: String) {}

    func onConsentInfoUpdated() {}
    func onConsentInfoUpdateFailed(_ error: Error) {}
    func onConsentFormShown() {}
    func onConsentFormError(_ error: Error) {}
    func onConsentGranted() {}
    func onConsentDenied() {}
    func onConsentNotRequired() {}
    func onConsentStatusChanged(_ hasConsent: Bool) {}
}
