// swift-tools-version: 5.10

import PackageDescription

let package = Package(
    name: "XProjParser",
    platforms: [
        .macOS(.v13),
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "XProjParser",
            targets: ["XProjParser"]),
    ],
    dependencies: [
        .package(url: "https://github.com/anconaesselmann/ParenthesesParser", from: "0.0.2")
    ],
    targets: [
        .target(
            name: "XProjParser",
            dependencies: ["ParenthesesParser"]
        ),
        .testTarget(
            name: "XProjParserTests",
            dependencies: ["XProjParser"],
            resources: [
                .copy("Resources/01_project.pbxproj")
            ]
        ),
    ]
)
