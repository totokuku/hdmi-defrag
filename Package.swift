// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HDMIDefrag",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HDMIDefragCore", targets: ["HDMIDefragCore"])
    ],
    targets: [
        .target(
            name: "HDMIDefragCore",
            path: "Sources/HDMIDefragCore"
        ),
        .executableTarget(
            name: "HDMIDefrag",
            dependencies: ["HDMIDefragCore"],
            path: "Sources/HDMIDefrag"
        )
    ]
)
