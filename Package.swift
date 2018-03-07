// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "Signals",
    products: [
        .library(
            name: "Signals",
            targets: ["Signals"]),
    ],
    dependencies: [
        
    ],
    targets: [
        .target(
            name: "Signals",
            dependencies: []),
        .testTarget(
            name: "SignalsTests",
            dependencies: ["Signals"]),
    ],
    swiftLanguageVersions: [4]
)
