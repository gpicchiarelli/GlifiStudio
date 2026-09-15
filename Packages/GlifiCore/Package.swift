// swift-tools-version: 6.0
// SPDX-License-Identifier: BSD-3-Clause

import PackageDescription

let package = Package(
    name: "GlifiCore",
    platforms: [
        .macOS("27.0"),
        .iOS("27.0"),
    ],
    products: [
        .library(name: "GlifiCore", targets: ["GlifiCore"]),
        .library(name: "GlifiKit", targets: ["GlifiKit"]),
        .executable(name: "GlifiCLI", targets: ["GlifiCLI"]),
    ],
    targets: [
        .target(name: "GlifiCore"),
        .target(name: "GlifiKit", dependencies: ["GlifiCore"]),
        .executableTarget(name: "GlifiCLI", dependencies: ["GlifiKit"]),
        .testTarget(name: "GlifiCoreTests", dependencies: ["GlifiCore"]),
        .testTarget(name: "GlifiKitTests", dependencies: ["GlifiKit"]),
    ],
    swiftLanguageModes: [.v6]
)
