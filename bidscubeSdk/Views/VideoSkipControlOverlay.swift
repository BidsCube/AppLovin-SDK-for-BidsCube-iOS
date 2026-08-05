import UIKit

/// Top-trailing overlay: "Skip in N" countdown, then a Skip button.
final class VideoSkipControlOverlay {
    protocol Delegate: AnyObject {
        func onSkipRequested()
        func onSkipAvailable()
    }

    private static let defaultSkipSeconds = 15

    private weak var parent: UIView?
    private weak var delegate: Delegate?

    private let countdownLabel = UILabel()
    private let skipButton = UIButton(type: .system)
    private var secondsLeft: Int
    private var tickTimer: Timer?
    private var destroyed = false

    init(vastXml: String?, delegate: Delegate) {
        self.delegate = delegate
        self.secondsLeft = VastParser.resolveSkipSeconds(
            vastXml: vastXml,
            defaultSeconds: Self.defaultSkipSeconds
        )
        configureCountdownLabel()
        configureSkipButton()
    }

    func attach(to parent: UIView) {
        guard !destroyed else { return }
        self.parent = parent

        [countdownLabel, skipButton].forEach { view in
            view.translatesAutoresizingMaskIntoConstraints = false
            parent.addSubview(view)
            NSLayoutConstraint.activate([
                view.topAnchor.constraint(equalTo: parent.safeAreaLayoutGuide.topAnchor, constant: 20),
                view.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -16),
                view.heightAnchor.constraint(greaterThanOrEqualToConstant: 36)
            ])
        }

        skipButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)

        startCountdown()
    }

    func destroy() {
        destroyed = true
        tickTimer?.invalidate()
        tickTimer = nil
        countdownLabel.removeFromSuperview()
        skipButton.removeFromSuperview()
        parent = nil
    }

    private func configureCountdownLabel() {
        styleChip(countdownLabel)
        countdownLabel.font = .systemFont(ofSize: 13, weight: .medium)
        countdownLabel.textColor = .white
        countdownLabel.textAlignment = .center
        countdownLabel.isHidden = false
        countdownLabel.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    private func configureSkipButton() {
        styleChip(skipButton)
        skipButton.setTitle("Skip", for: .normal)
        skipButton.titleLabel?.font = .systemFont(ofSize: 13, weight: .medium)
        skipButton.setTitleColor(.white, for: .normal)
        skipButton.isHidden = true
        skipButton.alpha = 0
        skipButton.addTarget(self, action: #selector(skipTapped), for: .touchUpInside)
    }

    private func styleChip(_ view: UIView) {
        view.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        view.layer.cornerRadius = 18
        view.clipsToBounds = true
        view.layoutMargins = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
    }

    private func startCountdown() {
        tickTimer?.invalidate()
        updateCountdownUI()
        tickTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
            guard let self, !self.destroyed else {
                timer.invalidate()
                return
            }
            if self.secondsLeft > 0 {
                self.secondsLeft -= 1
                self.updateCountdownUI()
                return
            }
            timer.invalidate()
            self.tickTimer = nil
            self.showSkipButton()
        }
    }

    private func updateCountdownUI() {
        countdownLabel.text = "Skip in \(secondsLeft)"
        countdownLabel.isHidden = false
        skipButton.isHidden = true
    }

    private func showSkipButton() {
        countdownLabel.isHidden = true
        skipButton.isHidden = false
        UIView.animate(withDuration: 0.2) {
            self.skipButton.alpha = 0.85
        }
        delegate?.onSkipAvailable()
    }

    @objc private func skipTapped() {
        delegate?.onSkipRequested()
    }
}
