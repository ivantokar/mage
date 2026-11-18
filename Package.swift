// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "mage",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "mage", targets: ["mage"]),
        .library(name: "MageCore", targets: ["MageCore"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    ],
    targets: [
        // Framework-independent core: project/architecture models, generation plans,
        // filesystem and rendering boundaries, diagnostics. It must not import
        // Vapor, Fluent or any other concrete adapter (enforced by a test).
        .target(name: "MageCore"),

        // CLI presentation layer: argument parsing and console output.
        .target(
            name: "MageCLI",
            dependencies: [
                "MageCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),

        // Thin executable entry point.
        .executableTarget(name: "mage", dependencies: ["MageCLI"]),

        .testTarget(name: "MageCoreTests", dependencies: ["MageCore"]),
        .testTarget(name: "MageCLITests", dependencies: ["MageCLI", "MageCore"]),
    ]
)
