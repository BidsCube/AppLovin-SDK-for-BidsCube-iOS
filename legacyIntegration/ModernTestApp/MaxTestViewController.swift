import AppLovinSDK
import BidscubeSDK
import UIKit

/// AppLovin MAX mediation harness — mirrors integration from AppLovin custom SDK network docs.
final class MaxTestViewController: UIViewController {
    private let logTextView = UITextView()
    private let bannerContainer = UIView()
    private let mrecContainer = UIView()

    private var bannerAdView: MAAdView?
    private var mrecAdView: MAAdView?
    private var interstitialAd: MAInterstitialAd?
    private var rewardedAd: MARewardedAd?

    private var interstitialReady = false
    private var rewardedReady = false

    init() {
        super.init(nibName: nil, bundle: nil)
        title = "MAX"
        tabBarItem = UITabBarItem(title: "MAX", image: UIImage(systemName: "bolt.fill"), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupAds()
        logStatus()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BidscubeSDK.setDisplayViewController(self)
    }

    private func logStatus() {
        if TestConfig.isMaxConfigured {
            TestLog.append("[MAX] AppLovin SDK key configured")
            if !TestConfig.isMaxAdsConfigured {
                TestLog.append("[MAX] Add MAX_*_AD_UNIT_ID to load mediated ads")
            }
            TestLog.append("[MAX] Adapter class: ALBidscubeMediationAdapter (BidscubeSDKAppLovin pod)")
        } else {
            TestLog.append("[MAX] Set APPLOVIN_SDK_KEY or AppLovinSdkKey in Info.plist")
        }
    }

    private func setupUI() {
        let hint = UILabel()
        hint.numberOfLines = 0
        hint.font = .preferredFont(forTextStyle: .footnote)
        hint.textColor = .secondaryLabel
        hint.text = """
        Tests Bidscube via AppLovin MAX mediation (same flow as AppLovin custom SDK network).
        In MAX dashboard: Network → Custom SDK → iOS adapter ALBidscubeMediationAdapter, App ID = Bidscube placement ID.
        Native MAX is not supported by the adapter — use the Native SDK tab.
        """

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.backgroundColor = UIColor.secondarySystemBackground
        logTextView.layer.cornerRadius = 8

        bannerContainer.backgroundColor = UIColor.secondarySystemBackground
        bannerContainer.layer.borderWidth = 1
        bannerContainer.layer.borderColor = UIColor.separator.cgColor
        bannerContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([bannerContainer.heightAnchor.constraint(equalToConstant: 60)])

        mrecContainer.backgroundColor = UIColor.secondarySystemBackground
        mrecContainer.layer.borderWidth = 1
        mrecContainer.layer.borderColor = UIColor.separator.cgColor
        mrecContainer.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            mrecContainer.heightAnchor.constraint(equalToConstant: 250),
            mrecContainer.widthAnchor.constraint(equalToConstant: 300)
        ])

        let stack = UIStackView(arrangedSubviews: [
            hint,
            caption("Banner (MAX → Bidscube)"),
            bannerContainer,
            caption("MREC"),
            mrecContainer,
            buttonRow([
                ("Load Banner", #selector(loadBannerTapped)),
                ("Load MREC", #selector(loadMrecTapped))
            ]),
            buttonRow([
                ("Load Interstitial", #selector(loadInterstitialTapped)),
                ("Show Interstitial", #selector(showInterstitialTapped))
            ]),
            buttonRow([
                ("Load Rewarded", #selector(loadRewardedTapped)),
                ("Show Rewarded", #selector(showRewardedTapped))
            ]),
            makeButton("Mediation Debugger", action: #selector(openMediationDebugger)),
            caption("Logs (shared)"),
            logTextView
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        logTextView.translatesAutoresizingMaskIntoConstraints = false
        logTextView.heightAnchor.constraint(equalToConstant: 140).isActive = true

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12)
        ])

        TestLog.onUpdate = { [weak self] text in
            self?.logTextView.text = text
            let end = NSRange(location: max(0, (text as NSString).length - 1), length: 1)
            self?.logTextView.scrollRangeToVisible(end)
        }
        logTextView.text = TestLog.formattedText()
    }

    private func setupAds() {
        guard TestConfig.isMaxAdsConfigured else { return }

        let interstitial = MAInterstitialAd(adUnitIdentifier: TestConfig.interstitialAdUnitId)
        interstitial.delegate = self
        interstitialAd = interstitial

        let rewarded = MARewardedAd.shared(withAdUnitIdentifier: TestConfig.rewardedAdUnitId)
        rewarded.delegate = self
        rewardedAd = rewarded
    }

    private func caption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        button.heightAnchor.constraint(equalToConstant: 44).isActive = true
        return button
    }

    private func buttonRow(_ items: [(String, Selector)]) -> UIStackView {
        let row = UIStackView()
        row.axis = .horizontal
        row.spacing = 8
        row.distribution = .fillEqually
        for (title, action) in items {
            row.addArrangedSubview(makeButton(title, action: action))
        }
        return row
    }

    private func attachAdView(_ adView: MAAdView, to container: UIView, size: CGSize) {
        container.subviews.forEach { $0.removeFromSuperview() }
        adView.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(adView)
        NSLayoutConstraint.activate([
            adView.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            adView.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            adView.widthAnchor.constraint(equalToConstant: size.width),
            adView.heightAnchor.constraint(equalToConstant: size.height)
        ])
    }

    @objc private func loadBannerTapped() {
        guard TestConfig.isMaxAdsConfigured else {
            return log("[MAX] Configure MAX_*_AD_UNIT_ID in Info.plist or scheme env")
        }
        log("[MAX] Loading banner unit=\(TestConfig.bannerAdUnitId)")
        bannerAdView?.removeFromSuperview()
        let adView = MAAdView(adUnitIdentifier: TestConfig.bannerAdUnitId)
        adView.delegate = self
        bannerAdView = adView
        attachAdView(adView, to: bannerContainer, size: CGSize(width: 320, height: 50))
        adView.loadAd()
    }

    @objc private func loadMrecTapped() {
        guard TestConfig.isMaxAdsConfigured else {
            return log("[MAX] Configure MAX_*_AD_UNIT_ID in Info.plist or scheme env")
        }
        log("[MAX] Loading MREC unit=\(TestConfig.mrecAdUnitId)")
        mrecAdView?.removeFromSuperview()
        let adView = MAAdView(adUnitIdentifier: TestConfig.mrecAdUnitId, adFormat: .mrec)
        adView.delegate = self
        mrecAdView = adView
        attachAdView(adView, to: mrecContainer, size: CGSize(width: 300, height: 250))
        adView.loadAd()
    }

    @objc private func loadInterstitialTapped() {
        guard TestConfig.isMaxAdsConfigured else {
            return log("[MAX] Configure MAX_*_AD_UNIT_ID in Info.plist or scheme env")
        }
        guard let interstitialAd else { return log("[MAX] Interstitial not configured") }
        log("[MAX] Loading interstitial unit=\(TestConfig.interstitialAdUnitId)")
        interstitialReady = false
        interstitialAd.load()
    }

    @objc private func showInterstitialTapped() {
        guard let interstitialAd else { return log("[MAX] Interstitial not configured") }
        guard interstitialReady else { return log("[MAX] Interstitial not ready") }
        log("[MAX] Showing interstitial")
        interstitialAd.show()
        interstitialReady = false
    }

    @objc private func loadRewardedTapped() {
        guard TestConfig.isMaxAdsConfigured else {
            return log("[MAX] Configure MAX_*_AD_UNIT_ID in Info.plist or scheme env")
        }
        guard let rewardedAd else { return log("[MAX] Rewarded not configured") }
        log("[MAX] Loading rewarded unit=\(TestConfig.rewardedAdUnitId)")
        rewardedReady = false
        rewardedAd.load()
    }

    @objc private func showRewardedTapped() {
        guard let rewardedAd else { return log("[MAX] Rewarded not configured") }
        guard rewardedReady else { return log("[MAX] Rewarded not ready") }
        log("[MAX] Showing rewarded")
        rewardedAd.show()
        rewardedReady = false
    }

    @objc private func openMediationDebugger() {
        guard TestConfig.isMaxAdsConfigured else {
            return log("[MAX] Configure MAX_*_AD_UNIT_ID in Info.plist or scheme env")
        }
        ALSdk.shared().showMediationDebugger()
    }

    private func log(_ message: String) {
        TestLog.append(message)
    }
}

extension MaxTestViewController: MAAdDelegate {
    func didLoad(_ ad: MAAd) {
        log("[MAX] didLoad \(ad.adUnitIdentifier) network=\(ad.networkName)")
        if ad.adUnitIdentifier == TestConfig.interstitialAdUnitId { interstitialReady = true }
        if ad.adUnitIdentifier == TestConfig.rewardedAdUnitId { rewardedReady = true }
    }

    func didFailToLoadAd(forAdUnitIdentifier adUnitIdentifier: String, withError error: MAError) {
        log("[MAX] didFailToLoadAd \(adUnitIdentifier): \(error.message)")
    }

    func didDisplay(_ ad: MAAd) {
        log("[MAX] didDisplay \(ad.adUnitIdentifier) network=\(ad.networkName)")
    }

    func didClick(_ ad: MAAd) {
        log("[MAX] didClick \(ad.adUnitIdentifier)")
    }

    func didHide(_ ad: MAAd) {
        log("[MAX] didHide \(ad.adUnitIdentifier)")
    }

    func didFail(toDisplay ad: MAAd, withError error: MAError) {
        log("[MAX] didFailToDisplay \(ad.adUnitIdentifier): \(error.message)")
    }
}

extension MaxTestViewController: MAAdViewAdDelegate {
    func didExpand(_ ad: MAAd) { log("[MAX] didExpand \(ad.adUnitIdentifier)") }
    func didCollapse(_ ad: MAAd) { log("[MAX] didCollapse \(ad.adUnitIdentifier)") }
}

extension MaxTestViewController: MARewardedAdDelegate {
    func didRewardUser(for ad: MAAd, with reward: MAReward) {
        log("[MAX] didRewardUser \(reward.label) x\(reward.amount)")
    }
}
