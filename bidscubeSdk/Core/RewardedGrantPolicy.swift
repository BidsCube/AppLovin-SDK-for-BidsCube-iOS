import Foundation

enum RewardedGrantPolicy {
    static func shouldGrantReward(videoCompleted: Bool, alwaysRewardUser: Bool) -> Bool {
        videoCompleted || alwaysRewardUser
    }
}
