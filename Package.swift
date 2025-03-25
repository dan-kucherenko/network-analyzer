// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "network-analyzer",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "network-analyzer", targets: ["network-analyzer"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-docc-symbolkit.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", from: "600.0.1"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0")
    ],
    targets: [
        .executableTarget(
            name: "network-analyzer",
            dependencies: [
                .product(name: "SymbolKit", package: "swift-docc-symbolkit"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftParser", package: "swift-syntax"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
