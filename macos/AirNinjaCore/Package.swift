// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "AirNinjaCore",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "AirNinjaCore", targets: ["AirNinjaCore"])
    ],
    targets: [
        .target(name: "AirNinjaCore"),
        .executableTarget(name: "InteropHarness", dependencies: ["AirNinjaCore"]),
        .executableTarget(name: "SmsSender", dependencies: ["AirNinjaCore"]),
        .testTarget(name: "AirNinjaCoreTests", dependencies: ["AirNinjaCore"])
    ]
)
