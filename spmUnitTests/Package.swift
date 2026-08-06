// swift-tools-version:5.9
// Thin test runner package so `xcodebuild test` does not pick up bidscubeSdk.xcodeproj.
import PackageDescription

let package = Package(
    name: "BidscubeSDKUnitTests",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        .package(name: "BidscubeSDKAppLovin", path: "..")
    ],
    targets: [
        .testTarget(
            name: "bidscubeSdkTests",
            dependencies: [
                .product(name: "BidscubeSDKAppLovin", package: "BidscubeSDKAppLovin")
            ],
            path: "bidscubeSdkTests"
        )
    ]
)
