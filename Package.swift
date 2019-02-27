// swift-tools-version:4.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Nantes",
    dependencies: [
        .package(
            url: "https://github.com/Realm/SwiftLint",
            from: "0.30.1"
        ),
    ],
    // Note: SPM requires 1 target to build the package
    targets: [
        .target(
            name: "Nantes",
            dependencies: ["swiftlint"],
            path: "Source/Classes",
            sources: ["NantesLabel.swift"]
        )
    ]
)

