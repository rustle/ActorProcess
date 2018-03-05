// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "ActorProcess",
    products: [
        .library(
            name: "ActorProcess",
            targets: ["ActorProcess"]),
        .executable(
            name: "act",
            targets: ["act"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rustle/Signals.git", from: "5.0.0+"),
    ],
    targets: [
        .target(
            name: "ActorProcess",
            dependencies: ["Signals", "act"]),
        .target(
            name: "act",
            dependencies: []),
        .testTarget(
            name: "ActorProcessTests",
            dependencies: ["ActorProcess"]),
    ],
    swiftLanguageVersions: [4]
)
