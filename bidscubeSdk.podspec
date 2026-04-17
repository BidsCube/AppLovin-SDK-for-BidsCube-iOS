Pod::Spec.new do |spec|
  spec.name         = "BidscubeSDK"
  spec.version      = "1.0.3.1"
  spec.summary      = "BidsCube iOS SDK for displaying ads (no AppLovin adapter; use BidscubeSDKAppLovin for MAX)"
  spec.description  = <<-DESC
                      BidsCube iOS SDK provides a comprehensive solution for displaying image, video, and native ads in iOS applications.
                      This pod excludes the AppLovin MAX adapter sources. For mediation use pod BidscubeSDKAppLovin instead.

                      Features:
                      - Image, Video, and Native ad support
                      - Multiple ad positions (header, footer, sidebar, fullscreen)
                      - VAST video ad support with IMA SDK integration
                      - Banner ad management
                      - Gesture-based navigation controls
                      - Error handling and timeout management
                      DESC

  spec.homepage     = "https://github.com/bidscube/bidscube-sdk-ios"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "Vlad" => "generalisimys20132@gmail.com" }

  spec.platform     = :ios, "13.0"
  spec.ios.deployment_target = '13.0'
  spec.swift_versions = ['5.9']

  spec.documentation_url = "https://github.com/bidscube/bidscube-sdk-ios"

  spec.source       = { :git => "https://github.com/bidscube/bidscube-sdk-ios.git", :tag => "v#{spec.version}" }

  spec.source_files = "bidscubeSdk/**/*.{swift,h}"
  spec.exclude_files = "bidscubeSdk/AppLovin/**/*"
  spec.public_header_files = "bidscubeSdk/bidscubeSdk.h"

  spec.dependency 'GoogleAds-IMA-iOS-SDK', '~> 3.19'

  spec.frameworks = 'UIKit', 'WebKit', 'AVFoundation', 'MediaPlayer'

  spec.requires_arc = true

  spec.pod_target_xcconfig = {
    'SWIFT_STRICT_CONCURRENCY' => 'off'
  }

  spec.user_target_xcconfig = {
    'SWIFT_STRICT_CONCURRENCY' => 'off'
  }

end
