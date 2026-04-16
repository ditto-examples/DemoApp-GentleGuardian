// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GentleGuardian",
    platforms: [
        .iOS(.v26),
        .macOS(.v26)
    ],
    dependencies: [
        .package(
            url: "https://github.com/getditto/DittoSwiftPackage",
            from: "5.0.0-rc.2"
        )
    ],
    targets: [
        .executableTarget(
            name: "GentleGuardian",
            dependencies: [
                .product(name: "DittoSwift", package: "DittoSwiftPackage")
            ],
            path: "GentleGuardian",
            resources: [
                .process("Resources")
            ],
            swiftSettings: [
                // Ditto SDK uses [String: Any?] dictionaries which are not Sendable.
                // Use targeted concurrency until the SDK adopts typed Sendable parameters.
                .swiftLanguageMode(.v5)
            ]
        ),
        .testTarget(
            name: "GentleGuardianTests",
            dependencies: ["GentleGuardian"],
            path: "GentleGuardianTests",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
