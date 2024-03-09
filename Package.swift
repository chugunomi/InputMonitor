// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "InputMonitor",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "InputMonitor",
            type: .static,
            targets: ["InputMonitor"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Quick/Nimble.git", from: "12.0.0"),
        .package(url: "https://github.com/Quick/Quick.git", from: "7.0.0"),
    ],
    targets: [
        .target(
            name: "InputMonitor",
            path: "Sources/InputMonitor"
        ),
        .testTarget(
            name: "InputMonitorTests",
            dependencies: [
                "InputMonitor",
                "Nimble",
                "Quick",
            ]
        ),
    ]
)
