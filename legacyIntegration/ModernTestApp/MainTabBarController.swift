import UIKit

final class MainTabBarController: UITabBarController {
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            UINavigationController(rootViewController: SdkAdTestViewController(format: .banner)),
            UINavigationController(rootViewController: SdkAdTestViewController(format: .video)),
            UINavigationController(rootViewController: SdkAdTestViewController(format: .native)),
            UINavigationController(rootViewController: MaxTestViewController())
        ]
    }
}
