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
        .executable(
            name: "ExampleHost",
            targets: ["ExampleHost"]),
        .executable(
            name: "ExampleActor",
            targets: ["ExampleActor"]),
    ],
    dependencies: [
        .package(url: "https://github.com/rustle/Signals.git", .revision("dd050c5aaa8f576e21c4631457e61fde80170cd0")),
    ],
    targets: [
        .target(
            name: "ActorProcess",
            dependencies: ["Signals", "act"]),
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
    swiftLanguageVersions: [4]
)
