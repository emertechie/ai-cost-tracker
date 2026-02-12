// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AICostTracker",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "AICostTracker",
            path: "Sources"
        ),
    ]
)
