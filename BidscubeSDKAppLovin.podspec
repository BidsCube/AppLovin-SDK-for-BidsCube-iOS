Pod::Spec.new do |spec|
  spec.name         = "BidscubeSDKAppLovin"
  spec.version      = "1.0.1"
  spec.summary      = "Bidscube iOS SDK with embedded AppLovin MAX adapter (single dependency for mediation)"
  spec.description  = <<-DESC
                      All Bidscube runtime sources plus the AppLovin MAX mediation adapter in one pod.
                      You only add this pod and AppLovin MAX — no separate BidscubeSDK pod.

                      Adapter class for MAX dashboard: ALBidscubeMediationAdapter

                      Features:
                      - Interstitial, rewarded, banner/MREC/leader, native
                      - Image, video, and native ads via Bidscube runtime
                      - IMA for video where applicable
                      DESC

  spec.homepage     = "https://github.com/bidscube/bidscube-sdk-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Vlad" => "generalisimys20132@gmail.com" }

  spec.platform     = :ios, "13.0"
  spec.ios.deployment_target = "13.0"
  spec.swift_versions = ["5.9"]

  spec.documentation_url = "https://github.com/bidscube/bidscube-sdk-ios"

  spec.source       = { :git => "https://github.com/bidscube/bidscube-sdk-ios.git", :tag => "v#{spec.version}" }

  spec.source_files = "bidscubeSdk/**/*.{swift,h}"
  spec.public_header_files = "bidscubeSdk/bidscubeSdk.h"

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
