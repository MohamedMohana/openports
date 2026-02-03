// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "OpenPorts",
    platforms: [.macOS(.v14)],
    products: [
        .executable(
            name: "OpenPorts",
            targets: ["OpenPorts"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-log.git", from: "1.6.0"),
        .package(url: "https://github.com/sparkle-project/Sparkle.git", from: "2.8.1")
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
                "OpenPortsCore",
                .product(name: "Sparkle", package: "Sparkle")
            ]
        ),
        .testTarget(
            name: "OpenPortsCoreTests",
            dependencies: ["OpenPortsCore"]
        )
    ]
)
