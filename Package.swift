// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "IsMarketOpen",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .executable(name: "IsMarketOpen", targets: ["IsMarketOpen"]),
    ],
    targets: [
        .executableTarget(
            name: "IsMarketOpen",
            path: "Sources/IsMarketOpen"
        ),
        .testTarget(
            name: "IsMarketOpenTests",
            dependencies: ["IsMarketOpen"],
            path: "Tests/IsMarketOpenTests"
        ),
    ]
)
