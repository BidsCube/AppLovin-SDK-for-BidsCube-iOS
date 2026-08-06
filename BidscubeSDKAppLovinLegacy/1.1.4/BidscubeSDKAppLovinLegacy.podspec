Pod::Spec.new do |spec|
  spec.name         = "BidscubeSDKAppLovinLegacy"
  spec.version      = "1.1.4"
  spec.summary      = "Bidscube iOS SDK with AppLovin MAX adapter for iOS 14+ (AVPlayer VAST, no Google IMA)"
  spec.description  = <<-DESC
                      Legacy integration path for apps that must support iOS 14.
                      Same module name (BidscubeSDK) and MAX adapter (ALBidscubeMediationAdapter) as the modern pod.
                      Video ads use an AVPlayer-based VAST player instead of Google IMA.

                      Install only one of BidscubeSDKAppLovin or BidscubeSDKAppLovinLegacy per target.
                      DESC

  spec.homepage     = "https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Vlad" => "generalisimys20132@gmail.com" }

  spec.platform     = :ios, "14.0"
  spec.ios.deployment_target = "14.0"
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
    "bidscubeSdk/Views/IMAVideoAdHandler.swift",
    "bidscubeSdk/Views/IMAVideoAdHandler.swift.disabled",
    "bidscubeSdk/Views/IMAViewController.swift",
    "bidscubeSdk/Logger/SDKLogger.swift"
  ]

  spec.dependency "AppLovinSDK", "~> 13.6.0"

  spec.frameworks = "UIKit", "WebKit", "AVFoundation", "MediaPlayer"

  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) BIDSCUBE_LEGACY_VIDEO",
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }

  spec.user_target_xcconfig = {
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }
end
