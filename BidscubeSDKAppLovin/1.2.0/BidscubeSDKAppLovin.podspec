Pod::Spec.new do |spec|
  spec.name         = "BidscubeSDKAppLovin"
  spec.version      = "1.2.0"
  spec.summary      = "Bidscube iOS SDK with embedded AppLovin MAX adapter (single dependency for mediation)"
  spec.description  = <<-DESC
                      All Bidscube runtime sources plus the AppLovin MAX mediation adapter in one pod.
                      Add this pod for AppLovin MAX — no separate BidscubeSDK pod is required.

                      Adapter class for MAX dashboard: ALBidscubeMediationAdapter

                      Supported formats: Banner, MREC, Interstitial (video), Rewarded
                      Video ads use Google IMA by default.
                      Native MAX is not supported in this release.
                      DESC

  spec.homepage     = "https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Vlad" => "generalisimys20132@gmail.com" }

  spec.platform     = :ios, "15.0"
  spec.ios.deployment_target = "15.0"
  spec.swift_versions = ["5.9"]

  spec.documentation_url = "https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS"

  spec.source       = {
    :git => "https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git",
    :tag => "v#{spec.version}"
  }

  spec.module_name = "BidscubeSDK"

  spec.source_files = "bidscubeSdk/**/*.{swift,h,m}"
  spec.public_header_files = "bidscubeSdk/bidscubeSdk.h"
  spec.exclude_files = [
    "bidscubeSdk/Tests/**/*",
    "bidscubeSdk/Controller/**/*",
    "bidscubeSdk/Views/SDKTestView.swift",
    "bidscubeSdk/Views/ContentView.swift",
    "bidscubeSdk/Views/CustomAdRenderView.swift",
    "bidscubeSdk/Views/IMAVideoAdHandler.swift.disabled",
    "bidscubeSdk/Logger/SDKLogger.swift"
  ]

  spec.dependency "GoogleAds-IMA-iOS-SDK", "~> 3.19"
  spec.dependency "AppLovinSDK", ">= 13.0.0", "< 14.0"

  spec.frameworks = "UIKit", "WebKit", "AVFoundation", "MediaPlayer"

  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }

  spec.user_target_xcconfig = {
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }
end
