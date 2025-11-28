// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MenuBarScroller",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MenuBarScroller", targets: ["MenuBarScroller"])
    ],
    targets: [
        .executableTarget(
            name: "MenuBarScroller",
            path: "Sources"
        )
    ]
)
