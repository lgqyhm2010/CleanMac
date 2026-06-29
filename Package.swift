// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "CleanMac",
    defaultLocalization: "en",
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
            path: "Sources/CleanMac",
            resources: [
                .process("Resources")
            ]
        ),
        .target(
            name: "CleanMacCore",
            path: "Sources/CleanMacCore",
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "CleanMacCoreTests",
            dependencies: ["CleanMacCore"],
            path: "Tests/CleanMacCoreTests"
        ),
        .testTarget(
            name: "CleanMacUITests",
            dependencies: ["CleanMac", "CleanMacCore"],
            path: "Tests/CleanMacUITests"
        )
    ]
)
