// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SpaceLauncher",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "SpaceLauncher", targets: ["SpaceLauncher"])
    ],
    dependencies: [
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.0.6")
    ],
    targets: [
        .executableTarget(
            name: "SpaceLauncher",
            dependencies: ["Yams"],
            path: "Sources/SpaceLauncher"
        )
    ]
)