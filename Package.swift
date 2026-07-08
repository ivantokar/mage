// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "mage",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
        .package(url: "https://github.com/stencilproject/Stencil", from: "0.15.0"),
        .package(url: "https://github.com/jpsim/Yams", from: "5.0.0"),
        .package(url: "https://github.com/ivantokar/prompt.git", from: "1.0.0"),
        .package(url: "https://github.com/ivantokar/swift-stencil-kit.git", from: "2.0.1"),
    ],
    targets: [
        .executableTarget(
            name: "Mage",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "Yams", package: "Yams"),
                .product(name: "Prompt", package: "prompt"),
                .product(name: "SwiftStencilKit", package: "swift-stencil-kit"),
            ],
            path: "Sources/Mage",
            resources: [
                .copy("Templates")
            ]
        ),
        .testTarget(
            name: "MageTests",
            dependencies: ["Mage"],
            path: "Tests/MageTests"
        ),
    ]
)
