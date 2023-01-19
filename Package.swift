// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PaltaSDKCore",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        .library(
            name: "PaltaCore",
            targets: ["PaltaCore"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "PaltaCore",
            dependencies: [],
            path: "Sources/Core"
        ),
        .testTarget(
            name: "PaltaCoreTests",
            dependencies: ["PaltaCore"]
        ),
    ]
)
