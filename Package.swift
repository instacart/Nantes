// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Nantes",
    products: [
        .library(name: "Nantes", targets: ["Nantes"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Nantes",
            platforms: [.iOS(.v8)],
            path: "Source/Classes",
            exclude: ["Nantes.h"]
        )
    ]
)
