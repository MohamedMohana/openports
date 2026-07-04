// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "OpenPorts",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "OpenPorts",
            targets: ["OpenPorts"]
        ),
        .executable(
            name: "openports-cli",
            targets: ["OpenPortsCLI"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0")
    ],
    targets: [
        .target(
            name: "OpenPortsCore",
            dependencies: [
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .executableTarget(
            name: "OpenPorts",
            dependencies: [
                "OpenPortsCore"
            ]
        ),
        .executableTarget(
            name: "OpenPortsCLI",
            dependencies: [
                "OpenPortsCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Logging", package: "swift-log")
            ]
        ),
        .testTarget(
            name: "OpenPortsCoreTests",
            dependencies: ["OpenPortsCore"]
        ),
        .testTarget(
            name: "OpenPortsCLITests",
            dependencies: ["OpenPortsCLI"]
        )
    ]
)
