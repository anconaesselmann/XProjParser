// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XProjParser",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "XProjParser",
            targets: ["XProjParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/anconaesselmann/ParenthesesParser", from: "0.0.1")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "XProjParser",
            dependencies: ["ParenthesesParser"]
        ),
        .testTarget(
            name: "XProjParserTests",
            dependencies: ["XProjParser"]),
    ]
)
