import SwiftUI
import UIKit

struct BidscubeBannerContainer: UIViewRepresentable {
    let bannerView: UIView

    func makeUIView(context: Context) -> UIView {
        let container = UIView()
        container.backgroundColor = .clear
        embed(bannerView, in: container)
        return container
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        uiView.subviews.forEach { $0.removeFromSuperview() }
        embed(bannerView, in: uiView)
    }

    private func embed(_ child: UIView, in container: UIView) {
        child.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(child)
        NSLayoutConstraint.activate([
            child.centerXAnchor.constraint(equalTo: container.centerXAnchor),
            child.topAnchor.constraint(equalTo: container.topAnchor),
            child.bottomAnchor.constraint(equalTo: container.bottomAnchor),
            child.widthAnchor.constraint(equalToConstant: 320),
            child.heightAnchor.constraint(equalToConstant: 50),
        ])
    }
}
