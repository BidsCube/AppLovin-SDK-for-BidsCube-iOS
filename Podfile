platform :ios, '13.0'
use_frameworks!
project 'bidscubeSdk.xcodeproj'

# Main iOS app target (this one exists in your project)
target 'testApp-ios' do
  pod 'GoogleAds-IMA-iOS-SDK', '~> 3.18.4'
end

# Add pod for SDK target so it can import GoogleInteractiveMediaAds
# This target name must exactly match what is in Xcode ('BidscubeSDK')
target 'BidscubeSDK' do
  pod 'GoogleAds-IMA-iOS-SDK', '~> 3.18.4'
end

# If 'BidscubeSDK' is NOT an Xcode target → REMOVE it
# If you want a Pod for SDK project, add real target name from Xcode
