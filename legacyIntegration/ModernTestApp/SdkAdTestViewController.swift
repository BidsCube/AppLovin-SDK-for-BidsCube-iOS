import BidscubeSDK
import UIKit

enum SdkAdFormat: Equatable {
    case banner
    case video
    case native

    var title: String {
        switch self {
        case .banner: return "Banner"
        case .video: return "Video"
        case .native: return "Native"
        }
    }

    var tabIcon: String {
        switch self {
        case .banner: return "rectangle.bottomthird.inset.filled"
        case .video: return "play.rectangle.fill"
        case .native: return "square.grid.2x2.fill"
        }
    }

    func defaultPlacementId() -> String {
        switch self {
        case .banner: return TestConfig.bannerPlacementId
        case .video: return TestConfig.videoPlacementId
        case .native: return TestConfig.nativePlacementId
        }
    }

    var containerHeight: CGFloat {
        switch self {
        case .banner: return 60
        case .video: return 220
        case .native: return 280
        }
    }

    var primaryActionTitle: String {
        switch self {
        case .banner: return "Load inline"
        case .video: return "Play fullscreen video"
        case .native: return "Load inline"
        }
    }

    var secondaryActionTitle: String? {
        switch self {
        case .banner: return nil
        case .video: return "Load inline preview"
        case .native: return "Show fullscreen"
        }
    }

    var usesPrimaryActionForFullscreen: Bool {
        self == .video
    }
}

final class SdkAdTestViewController: UIViewController {
    private let format: SdkAdFormat
    private let delegate: TestAdDelegate
    private let placementField = UITextField()
    private let adContainer = UIView()
    private let logTextView = UITextView()
    private var embeddedAdView: UIView?
    private var didAutoLoad = false

    init(format: SdkAdFormat) {
        self.format = format
        self.delegate = TestAdDelegate(label: format.title)
        super.init(nibName: nil, bundle: nil)
        title = format.title
        tabBarItem = UITabBarItem(title: format.title, image: UIImage(systemName: format.tabIcon), tag: 0)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        TestLog.onUpdate = { [weak self] text in
            self?.logTextView.text = text
            self?.scrollLogToEnd()
        }
        logTextView.text = TestLog.formattedText()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        BidscubeSDK.setDisplayViewController(self)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didAutoLoad else { return }
        didAutoLoad = true
        if format == .video {
            TestLog.append("[Video] Open this tab for video QA. Use the blue button for fullscreen playback.")
        } else {
            loadInlineTapped()
        }
    }

    private func setupUI() {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        let descriptionLabel = UILabel()
        descriptionLabel.numberOfLines = 0
        descriptionLabel.font = .preferredFont(forTextStyle: .footnote)
        descriptionLabel.textColor = .secondaryLabel
        descriptionLabel.text = formatDescription()

        placementField.borderStyle = .roundedRect
        placementField.placeholder = "Placement ID"
        placementField.text = format.defaultPlacementId()
        placementField.autocapitalizationType = .none
        placementField.autocorrectionType = .no

        adContainer.backgroundColor = UIColor.secondarySystemBackground
        adContainer.layer.borderWidth = 1
        adContainer.layer.borderColor = UIColor.separator.cgColor
        adContainer.layer.cornerRadius = 8
        adContainer.clipsToBounds = true

        logTextView.isEditable = false
        logTextView.font = .monospacedSystemFont(ofSize: 11, weight: .regular)
        logTextView.backgroundColor = UIColor.secondarySystemBackground
        logTextView.layer.cornerRadius = 8

        let clearButton = makeButton("Clear ad", action: #selector(clearAdTapped))
        let clearLogsButton = makeButton("Clear logs", action: #selector(clearLogsTapped))

        var actionButtons: [UIButton] = []
        if format.usesPrimaryActionForFullscreen {
            let primary = makePrimaryButton(format.primaryActionTitle, action: #selector(primaryActionTapped))
            actionButtons.append(primary)
            if let secondaryTitle = format.secondaryActionTitle {
                actionButtons.append(makeButton(secondaryTitle, action: #selector(loadInlineTapped)))
            }
        } else {
            actionButtons.append(makeButton(format.primaryActionTitle, action: #selector(loadInlineTapped)))
            if let secondaryTitle = format.secondaryActionTitle {
                actionButtons.append(makeButton(secondaryTitle, action: #selector(showFullscreenTapped)))
            }
        }
        actionButtons.append(clearButton)

        let actionStack = UIStackView(arrangedSubviews: actionButtons)
        actionStack.axis = .vertical
        actionStack.spacing = 10

        let stack = UIStackView(arrangedSubviews: [
            descriptionLabel,
            placementField,
            makeCaption("Ad preview"),
            adContainer,
            actionStack,
            clearLogsButton,
            makeCaption("Logs (shared)"),
            logTextView
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(stack)

        adContainer.translatesAutoresizingMaskIntoConstraints = false
        logTextView.translatesAutoresizingMaskIntoConstraints = false
        placementField.heightAnchor.constraint(equalToConstant: 40).isActive = true
        adContainer.heightAnchor.constraint(equalToConstant: format.containerHeight).isActive = true
        logTextView.heightAnchor.constraint(equalToConstant: 160).isActive = true
        clearLogsButton.heightAnchor.constraint(equalToConstant: 40).isActive = true
        for button in actionButtons {
            button.heightAnchor.constraint(equalToConstant: 48).isActive = true
        }

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            stack.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            stack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            stack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -12)
        ])
    }

    private func makePrimaryButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.filled()
        config.title = title
        config.baseBackgroundColor = .systemBlue
        config.baseForegroundColor = .white
        config.cornerStyle = .medium
        button.configuration = config
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    @objc private func primaryActionTapped() {
        showFullscreenTapped()
    }

    private func formatDescription() -> String {
        switch format {
        case .banner:
            return "Inline banner via BidscubeSDK.getBannerAdView (320×50)."
        case .video:
            return """
            Fullscreen interstitial: tap the blue “Play fullscreen video” button (BidscubeSDK.showVideoAd).
            Inline preview loads VAST into the box above via getVideoAdView.
            Default placement: \(TestConfig.videoPlacementId). If SSP returns code=204, there is no video fill for this placement.
            """
        case .native:
            return "Inline native card (320×250) or fullscreen native ad."
        }
    }

    private func makeCaption(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = .preferredFont(forTextStyle: .subheadline)
        return label
    }

    private func makeButton(_ title: String, action: Selector) -> UIButton {
        let button = UIButton(type: .system)
        button.setTitle(title, for: .normal)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func placementId() -> String {
        placementField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    @objc private func loadInlineTapped() {
        let placement = placementId()
        guard !placement.isEmpty else {
            TestLog.append("[\(format.title)] Enter a placement ID")
            return
        }
        clearEmbeddedAd()
        TestLog.append("[\(format.title)] Loading inline placement=\(placement)")

        BidscubeSDK.setDisplayViewController(self)

        let adView: UIView
        switch format {
        case .banner:
            let banner = BidscubeSDK.getBannerAdView(placement, position: .footer, callback: delegate)
            banner.setBannerDimensions(width: 320, height: 50)
            adView = banner
        case .video:
            let video = BidscubeSDK.getVideoAdView(placement, delegate)
            if let videoAdView = video as? VideoAdView {
                videoAdView.setParentViewController(self)
            }
            adView = video
        case .native:
            adView = BidscubeSDK.getNativeAdView(placement, width: 320, height: 250, delegate)
            if let nativeAdView = adView as? NativeAdView {
                nativeAdView.setLayoutMode(.full)
            }
        }

        embed(adView)

        if let videoAdView = adView as? VideoAdView {
            videoAdView.setParentViewController(self)
            videoAdView.refreshIMASetup()
        }
    }

    @objc private func showFullscreenTapped() {
        let placement = placementId()
        guard !placement.isEmpty else {
            TestLog.append("[\(format.title)] Enter a placement ID")
            return
        }
        TestLog.append("[\(format.title)] Showing fullscreen placement=\(placement)")
        switch format {
        case .banner:
            break
        case .video:
            BidscubeSDK.showVideoAd(from: self, placementId: placement, callback: delegate)
        case .native:
            BidscubeSDK.showNativeAd(from: self, placementId: placement, width: 320, height: 480, callback: delegate)
        }
    }

    @objc private func clearAdTapped() {
        clearEmbeddedAd()
        TestLog.append("[\(format.title)] Cleared inline ad")
    }

    @objc private func clearLogsTapped() {
        TestLog.clear()
    }

    private func embed(_ adView: UIView) {
        embeddedAdView = adView
        adView.translatesAutoresizingMaskIntoConstraints = false
        adContainer.addSubview(adView)

        var constraints: [NSLayoutConstraint] = [
            adView.centerXAnchor.constraint(equalTo: adContainer.centerXAnchor),
            adView.centerYAnchor.constraint(equalTo: adContainer.centerYAnchor)
        ]

        switch format {
        case .banner:
            constraints += [
                adView.widthAnchor.constraint(equalToConstant: 320),
                adView.heightAnchor.constraint(equalToConstant: 50)
            ]
        case .video:
            constraints = [
                adView.leadingAnchor.constraint(equalTo: adContainer.leadingAnchor),
                adView.trailingAnchor.constraint(equalTo: adContainer.trailingAnchor),
                adView.topAnchor.constraint(equalTo: adContainer.topAnchor),
                adView.bottomAnchor.constraint(equalTo: adContainer.bottomAnchor)
            ]
        case .native:
            constraints += [
                adView.widthAnchor.constraint(equalToConstant: 320),
                adView.heightAnchor.constraint(equalToConstant: 250)
            ]
        }

        NSLayoutConstraint.activate(constraints)
    }

    private func clearEmbeddedAd() {
        embeddedAdView?.removeFromSuperview()
        embeddedAdView = nil
        adContainer.subviews.forEach { $0.removeFromSuperview() }
    }

    private func scrollLogToEnd() {
        let end = NSRange(location: max(0, logTextView.text.count - 1), length: 1)
        logTextView.scrollRangeToVisible(end)
    }
}
