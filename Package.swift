// swift-tools-version:5.1

import PackageDescription

let package = Package(
    name: "ActorProcess",
    platforms: [
        .macOS(.v10_15),
    ],
    products: [
        .library(
            name: "ActorProcess",
            targets: ["ActorProcess"]),
        .executable(
            name: "act",
            targets: ["act"]),
        .executable(
            name: "ExampleHost",
            targets: ["ExampleHost"]),
        .executable(
            name: "ExampleActor",
            targets: ["ExampleActor"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ActorProcess",
            dependencies: ["act"]),
        .target(
            name: "act",
            dependencies: []),
        .target(
            name: "ExampleHost",
            dependencies: ["ActorProcess"]),
        .target(
            name: "ExampleActor",
            dependencies: ["ActorProcess"]),
        .testTarget(
            name: "ActorProcessTests",
            dependencies: ["ActorProcess"]),
    ],
    swiftLanguageVersions: [.v5]
)
