// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "Nantes",
    platforms: [.iOS(.v9)],
    products: [
        .library(name: "Nantes", targets: ["Nantes"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Nantes",
            path: "Source/Classes",
            exclude: ["Nantes.h"]
        )
    ]
)
