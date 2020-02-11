// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "Nantes",
    platforms: [.iOS(.v8)],
    products: [
        .library(name: "Nantes", targets: ["Nantes"]),
    ],
    targets: [
      .target(name: "Nantes", path: "Source/Classes", exclude: ["Nantes.h"])
    ],
    swiftLanguageVersions: [.v5]
)
