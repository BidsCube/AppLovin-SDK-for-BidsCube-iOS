platform :ios, '15.0'
use_frameworks!
project 'bidscubeSdk.xcodeproj'

source 'https://github.com/BidsCube/AppLovin-SDK-for-BidsCube-iOS.git'
source 'https://cdn.cocoapods.org/'

target 'testApp-ios' do
  pod 'AppLovinSDK', '~> 13.6.0'
  # Local sources for CI/dev; published integrators use the CocoaPods spec repo tag.
  pod 'BidscubeSDKAppLovin', :path => '.'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      deployment = config.build_settings['IPHONEOS_DEPLOYMENT_TARGET']
      next if deployment.nil?
      if deployment.to_f < 15.0
        config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
      end
    end
  end
end
