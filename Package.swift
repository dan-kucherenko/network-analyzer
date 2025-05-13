// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network-analyzer",
    platforms: [
        .macOS(.v15),
        .iOS(.v13)
    ],
    products: [
        .executable(
            name: "network-analyzer",
            targets: ["network-analyzer"]
        ),
        .plugin(
            name: "NetworkAnalyzerPlugin",
            targets: ["NetworkAnalyzerPlugin"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "network-analyzer",
            dependencies: [
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
        .plugin(
            name: "NetworkAnalyzerPlugin",
            capability: .buildTool(),
            dependencies: [
                .target(name: "network-analyzer")
            ]
        )
    ]
)
