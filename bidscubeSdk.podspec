Pod::Spec.new do |spec|
  spec.name         = "BidscubeSDK"
  spec.version      = "1.0.5"
  spec.summary      = "[Deprecated] Use BidscubeSDKAppLovin for AppLovin MAX integration"
  spec.description  = <<-DESC
                      DEPRECATED: This pod excludes the AppLovin MAX adapter.
                      For mediation, use pod 'BidscubeSDKAppLovin' instead.
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

  spec.source_files = "bidscubeSdk/**/*.{swift,h,m}"
  spec.exclude_files = [
    "bidscubeSdk/AppLovin/**/*",
    "bidscubeSdk/Tests/**/*",
    "bidscubeSdk/Controller/**/*",
    "bidscubeSdk/Views/SDKTestView.swift",
    "bidscubeSdk/Views/ContentView.swift",
    "bidscubeSdk/Views/CustomAdRenderView.swift",
    "bidscubeSdk/Views/IMAVideoAdHandler.swift.disabled",
    "bidscubeSdk/Logger/SDKLogger.swift"
  ]
  spec.public_header_files = "bidscubeSdk/bidscubeSdk.h"

  spec.dependency "GoogleAds-IMA-iOS-SDK", "~> 3.19"

  spec.frameworks = "UIKit", "WebKit", "AVFoundation", "MediaPlayer"

  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }

  spec.user_target_xcconfig = {
    "SWIFT_STRICT_CONCURRENCY" => "off"
  }
end
