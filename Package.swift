// swift-tools-version:6.0
// This package is iOS-only and requires iOS 13.0+
import PackageDescription

let package = Package(
    name: "BidscubeSDK",
    platforms: [
        .iOS(.v13)
    ],
    products: [
        .library(
            name: "BidscubeSDK",
            targets: ["BidscubeSDK"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/googleads/swift-package-manager-google-interactive-media-ads-ios.git",
            from: "3.19.0"
        )
    ],
    targets: [
        .target(
            name: "BidscubeSDK",
            dependencies: [
                .product(
                    name: "GoogleInteractiveMediaAds",
                    package: "swift-package-manager-google-interactive-media-ads-ios"
                )
            ],
            path: "bidscubeSdk",
            publicHeadersPath: "include",
            cSettings: [
                .headerSearchPath("include"),
                .define("SWIFT_PACKAGE"),
                .define("TARGET_OS_IPHONE", to: "1"),
                .define("TARGET_OS_IOS", to: "1")
            ],
           swiftSettings: [
               .define("TARGET_OS_IPHONE"),
               .define("TARGET_OS_IOS")
           ]
        ),
        .testTarget(
            name: "bidscubeSdkTests",
            dependencies: ["BidscubeSDK"],
            path: "Tests/bidscubeSdkTests"
        )
    ],
    swiftLanguageModes: [.v6]
)
