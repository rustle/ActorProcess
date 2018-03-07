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
        .package(url: "https://github.com/rustle/Signals.git", .revision("37445e0039defc57f8914ed521d2c1a0772fe992")),
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
