// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CleanMac",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "CleanMac", targets: ["CleanMac"]),
        .library(name: "CleanMacCore", targets: ["CleanMacCore"])
    ],
    targets: [
        .executableTarget(
            name: "CleanMac",
            dependencies: ["CleanMacCore"],
            path: "Sources/CleanMac"
        ),
        .target(
            name: "CleanMacCore",
            path: "Sources/CleanMacCore"
        ),
        .testTarget(
            name: "CleanMacCoreTests",
            dependencies: ["CleanMacCore"],
            path: "Tests/CleanMacCoreTests"
        )
    ]
)
