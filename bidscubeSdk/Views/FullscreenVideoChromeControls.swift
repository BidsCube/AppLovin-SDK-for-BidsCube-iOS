import UIKit

/// Top chrome for fullscreen video: labeled back control (leading) and close control (trailing).
@MainActor
final class FullscreenVideoChromeControls {
    let backButton: UIButton
    let closeButton: UIButton

    init(target: Any, backAction: Selector, closeAction: Selector) {
        backButton = UIButton(type: .system)
        backButton.setTitle("← Back", for: .normal)
        backButton.setTitleColor(.white, for: .normal)
        backButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        backButton.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        backButton.layer.cornerRadius = 20
        backButton.contentEdgeInsets = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 12)
        backButton.layer.shadowColor = UIColor.black.cgColor
        backButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        backButton.layer.shadowRadius = 4
        backButton.layer.shadowOpacity = 0.3
        backButton.addTarget(target, action: backAction, for: .touchUpInside)
        backButton.isHidden = true

        closeButton = UIButton(type: .system)
        closeButton.setTitle("✕", for: .normal)
        closeButton.setTitleColor(.white, for: .normal)
        closeButton.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        closeButton.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        closeButton.layer.cornerRadius = 20
        closeButton.layer.borderWidth = 2
        closeButton.layer.borderColor = UIColor.white.cgColor
        closeButton.addTarget(target, action: closeAction, for: .touchUpInside)
        closeButton.isHidden = true
    }

    func install(in host: UIView) {
        [backButton, closeButton].forEach { button in
            button.translatesAutoresizingMaskIntoConstraints = false
            host.addSubview(button)
        }

        NSLayoutConstraint.activate([
            backButton.topAnchor.constraint(equalTo: host.safeAreaLayoutGuide.topAnchor, constant: 16),
            backButton.leadingAnchor.constraint(equalTo: host.leadingAnchor, constant: 16),

            closeButton.topAnchor.constraint(equalTo: backButton.topAnchor),
            closeButton.trailingAnchor.constraint(equalTo: host.trailingAnchor, constant: -16),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalToConstant: 40)
        ])
    }

    func show(animated: Bool = true, delay: TimeInterval = 0.5) {
        backButton.isHidden = false
        closeButton.isHidden = false
        guard animated else {
            backButton.alpha = 1
            closeButton.alpha = 1
            return
        }
        backButton.alpha = 0
        closeButton.alpha = 0
        UIView.animate(withDuration: 0.3, delay: delay, options: .curveEaseInOut) {
            self.backButton.alpha = 1
            self.closeButton.alpha = 1
        }
    }

    func hide(animated: Bool = false) {
        guard animated else {
            backButton.isHidden = true
            closeButton.isHidden = true
            backButton.alpha = 1
            closeButton.alpha = 1
            return
        }
        UIView.animate(withDuration: 0.2) {
            self.backButton.alpha = 0
            self.closeButton.alpha = 0
        } completion: { _ in
            self.backButton.isHidden = true
            self.closeButton.isHidden = true
            self.backButton.alpha = 1
            self.closeButton.alpha = 1
        }
    }

    func bringToFront(in host: UIView) {
        host.bringSubviewToFront(backButton)
        host.bringSubviewToFront(closeButton)
    }
}
