// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Droptable",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "DroptableKit"),
        .executableTarget(name: "Droptable", dependencies: ["DroptableKit"]),
        .testTarget(name: "DroptableKitTests", dependencies: ["DroptableKit"]),
    ]
)
