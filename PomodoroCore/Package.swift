// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "PomodoroCore",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "PomodoroCore", targets: ["PomodoroCore"]),
    ],
    targets: [
        .target(name: "PomodoroCore"),
        .testTarget(name: "PomodoroCoreTests", dependencies: ["PomodoroCore"]),
    ]
)
