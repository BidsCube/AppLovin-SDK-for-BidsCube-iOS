// swift-tools-version:5.9
// iOS-only package: Bidscube runtime + AppLovin MAX adapter.
// CocoaPods (BidscubeSDKAppLovin) is the recommended integration path.
import PackageDescription

let package = Package(
    name: "BidscubeSDKAppLovin",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "BidscubeSDKAppLovin",
            targets: ["BidscubeSDKAppLovin"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
            exact: "3.32.0"
        ),
        .package(
            url: "https://github.com/AppLovin/AppLovin-MAX-Swift-Package.git",
            exact: "13.6.2"
        ),
    ],
    targets: [
        .target(
            name: "BidscubeSDKAppLovin",
            dependencies: [
                .product(
                    name: "GoogleInteractiveMediaAds",
                    package: "swift-package-manager-google-interactive-media-ads-ios"
                ),
                .product(
                    name: "AppLovinSDK",
                    package: "AppLovin-MAX-Swift-Package"
                ),
            ],
            path: "bidscubeSdk",
            exclude: [
                "Tests",
                "Controller",
                "Views/SDKTestView.swift",
                "Views/ContentView.swift",
                "Views/CustomAdRenderView.swift",
                "Views/IMAVideoAdHandler.swift.disabled",
                "Logger/SDKLogger.swift",
                "Video/Legacy",
                "bidscubeSdk.docc",
            ],
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("SWIFT_PACKAGE"),
                .define("TARGET_OS_IPHONE", to: "1"),
                .define("TARGET_OS_IOS", to: "1"),
            ],
            swiftSettings: [
                .define("TARGET_OS_IPHONE"),
                .define("TARGET_OS_IOS"),
            ]
        ),
        .testTarget(
            name: "bidscubeSdkTests",
            dependencies: ["BidscubeSDKAppLovin"],
            path: "bidscubeSdkTests"
        ),
    ]
)
