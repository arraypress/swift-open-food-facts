// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "OpenFoodFacts",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9), .visionOS(.v1),
    ],
    products: [
        .library(name: "OpenFoodFacts", targets: ["OpenFoodFacts"]),
    ],
    targets: [
        .target(
            name: "OpenFoodFacts",
            swiftSettings: [.enableUpcomingFeature("NonisolatedNonsendingByDefault")]
        ),
        .testTarget(name: "OpenFoodFactsTests", dependencies: ["OpenFoodFacts"], resources: [.copy("Recordings")]),
    ]
)
