// swift-tools-version: 6.0
import PackageDescription

let package = Package(
  name: "CommonBrowser",
  platforms: [.macOS(.v14)],
  targets: [
    .target(name: "CommonApp"),
    .executableTarget(name: "CommonBrowser", dependencies: ["CommonApp"]),
    .testTarget(name: "CommonAppTests", dependencies: ["CommonApp"]),
  ]
)
