import UIKit

public enum BidscubeVideoPlayerType: String {
    case ima
    case custom
}

public protocol BidscubeCustomVideoPlayer: AnyObject {
    func setPlacementInfo(_ placementId: String, callback: AdCallback?)
    func setParentViewController(_ viewController: UIViewController?)
    func loadVAST(source: String, isURL: Bool, clickURL: String?)
    func cleanup()
}

public protocol BidscubeCustomVideoPlayerFactory: AnyObject {
    func makeVideoPlayer() -> (UIView & BidscubeCustomVideoPlayer)
}
