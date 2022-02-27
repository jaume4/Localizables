// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocalizablesTools",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .executable(name: "LocalizablesCLI", targets: ["LocalizablesCLI"]),
        .library(name: "LocalizablesCore", targets: ["LocalizablesCore"]),
    ],

    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0"),
        .package(url: "https://github.com/pointfreeco/swift-parsing.git", from: "0.7.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "LocalizablesCore",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
            ]
        ),
        .executableTarget(
            name: "LocalizablesCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Parsing", package: "swift-parsing"),
                "LocalizablesCore",
            ]
        ),
        .testTarget(
            name: "localizablesTests",
            dependencies: ["LocalizablesCore"]
        ),
    ]
)
