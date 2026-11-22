// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Lest",
    platforms: [.macOS(.v14)],
    targets: [
        .target(name: "LestCore"),
        .executableTarget(name: "Lest", dependencies: ["LestCore"]),
        .testTarget(name: "LestCoreTests", dependencies: ["LestCore"]),
        .testTarget(name: "LestTests", dependencies: ["Lest", "LestCore"]),
    ]
)
