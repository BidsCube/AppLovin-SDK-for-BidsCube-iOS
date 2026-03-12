import UIKit
import bidscubeSdk

final class WindowedAdTestViewController: UIViewController, AdCallback, ConsentCallback {
    private var currentAdView: UIView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Windowed Ad Test"
        view.backgroundColor = .systemBackground

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.translatesAutoresizingMaskIntoConstraints = false

        let positions: [bidscubeSdk.AdPosition] = [.unknown, .aboveTheFold, .dependOnScreenSize, .belowTheFold, .header, .footer, .sidebar, .fullScreen]
        for p in positions {
            let b = UIButton(type: .system)
            b.setTitle("Position: \(p)", for: .normal)
            b.addAction(UIAction { [weak self] _ in self?.testPosition(p) }, for: .touchUpInside)
            b.backgroundColor = .tertiarySystemFill
            b.layer.cornerRadius = 8
            b.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
            stack.addArrangedSubview(b)
        }

        let createImage = makeActionButton("Create Image Ad", #selector(createImageAd))
        let createVideo = makeActionButton("Create Video Ad", #selector(createVideoAd))
        let createNative = makeActionButton("Create Native Ad", #selector(createNativeAd))

        let adHost = UIView()
        adHost.translatesAutoresizingMaskIntoConstraints = false
        adHost.backgroundColor = .secondarySystemBackground
        adHost.layer.cornerRadius = 8

        view.addSubview(stack)
        view.addSubview(createImage)
        view.addSubview(createVideo)
        view.addSubview(createNative)
        view.addSubview(adHost)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),

            createImage.topAnchor.constraint(equalTo: stack.bottomAnchor, constant: 12),
            createImage.leadingAnchor.constraint(equalTo: stack.leadingAnchor),

            createVideo.topAnchor.constraint(equalTo: createImage.bottomAnchor, constant: 8),
            createVideo.leadingAnchor.constraint(equalTo: createImage.leadingAnchor),

            createNative.topAnchor.constraint(equalTo: createVideo.bottomAnchor, constant: 8),
            createNative.leadingAnchor.constraint(equalTo: createImage.leadingAnchor),

            adHost.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 100),
            adHost.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            adHost.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12),
            adHost.widthAnchor.constraint(equalToConstant: 320)
        ])

        self.adHost = adHost
    }

    private var adHost: UIView!

    private func makeActionButton(_ title: String, _ action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.backgroundColor = .systemBlue
        b.setTitleColor(.white, for: .normal)
        b.layer.cornerRadius = 8
        b.contentEdgeInsets = UIEdgeInsets(top: 10, left: 14, bottom: 10, right: 14)
        b.addTarget(self, action: action, for: .touchUpInside)
        b.translatesAutoresizingMaskIntoConstraints = false
        return b
    }

    @objc private func createImageAd() { attach(BidscubeSDK.getImageAdView("20212", self)) }
    @objc private func createVideoAd() { attach(BidscubeSDK.getVideoAdView("20213", self)) }
    @objc private func createNativeAd() { attach(BidscubeSDK.getNativeAdView("20214", self)) }

    private func attach(_ viewToAdd: UIView) {
        currentAdView?.removeFromSuperview()
        viewToAdd.translatesAutoresizingMaskIntoConstraints = false
        adHost.addSubview(viewToAdd)
        NSLayoutConstraint.activate([
            viewToAdd.centerXAnchor.constraint(equalTo: adHost.centerXAnchor),
            viewToAdd.centerYAnchor.constraint(equalTo: adHost.centerYAnchor),
            viewToAdd.widthAnchor.constraint(lessThanOrEqualTo: adHost.widthAnchor, constant: -24),
            viewToAdd.heightAnchor.constraint(lessThanOrEqualTo: adHost.heightAnchor, constant: -24)
        ])
        currentAdView = viewToAdd
    }

    private func testPosition(_ position: bidscubeSdk.AdPosition) {
        BidscubeSDK.setAdPosition(position)
    }

    func onAdLoading(_ placementId: String) {}
    func onAdLoaded(_ placementId: String) {}
    func onAdDisplayed(_ placementId: String) {}
    func onAdClicked(_ placementId: String) {}
    func onAdClosed(_ placementId: String) {}
    func onAdFailed(_ placementId: String, errorCode: Int, errorMessage: String) {}

    func onConsentInfoUpdated() {}
    func onConsentInfoUpdateFailed(_ error: Error) {}
    func onConsentFormShown() {}
    func onConsentFormError(_ error: Error) {}
    func onConsentGranted() {}
    func onConsentDenied() {}
    func onConsentNotRequired() {}
    func onConsentStatusChanged(_ hasConsent: Bool) {}
}



