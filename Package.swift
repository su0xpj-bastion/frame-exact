// swift-tools-version:5.4
import PackageDescription

let package = Package(
    name: "frame-exact",
    platforms: [.macOS(.v11)],
    products: [
        .library(name: "FrameExact", targets: ["FrameExact"]),
        .executable(name: "fe", targets: ["fe"]),
    ],
    targets: [
        .target(name: "FrameExact"),
        .target(name: "FrameExactChecks", dependencies: ["FrameExact"]),
        .executableTarget(name: "fe", dependencies: ["FrameExact", "FrameExactChecks"]),
        .testTarget(name: "FrameExactTests", dependencies: ["FrameExact", "FrameExactChecks"]),
    ]
)
