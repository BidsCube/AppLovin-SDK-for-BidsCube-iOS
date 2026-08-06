import AppLovinSDK
import SwiftUI
import UIKit

struct MAAdViewContainer: UIViewRepresentable {
    let adView: MAAdView

    func makeUIView(context: Context) -> MAAdView {
        adView.backgroundColor = .clear
        return adView
    }

    func updateUIView(_ uiView: MAAdView, context: Context) {
        uiView.layoutIfNeeded()
    }
}

struct NativeAdContainer: UIViewRepresentable {
    let nativeView: UIView?

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = UIColor.secondarySystemBackground
        container.layer.cornerRadius = 8
        if let nativeView {
            embed(nativeView, in: container)
        }
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }
        if let nativeView {
            embed(nativeView, in: uiView)
        }
    }

    private func embed(_ child: UIView, in container: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            child.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
        ])
    }
}
