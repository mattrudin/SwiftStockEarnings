// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftStockEarnings",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "SwiftStockEarnings",
            targets: ["SwiftStockEarnings"]),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.1"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "SwiftStockEarnings",
            dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "SwiftStockEarningsTests",
            dependencies: ["SwiftStockEarnings"]
        ),
    ],
    version: "0.1.0"
)
