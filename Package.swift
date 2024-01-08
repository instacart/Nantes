// swift-tools-version:5.9

import PackageDescription

let package = Package(
    name: "Nantes",
    platforms: [.iOS(.v15)],
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
