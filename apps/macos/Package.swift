// swift-tools-version: 6.0
import PackageDescription

// Generated/ holds common-core's Swift bindings and static library. scripts/task builds it before
// SwiftPM runs, because SwiftPM cannot drive cargo itself.
let generated = "\(Context.packageDirectory)/Generated"

let package = Package(
  name: "CommonBrowser",
  platforms: [.macOS(.v14)],
  targets: [
    .systemLibrary(name: "CommonCoreFFI", path: "Generated/CommonCoreFFI"),
    .target(
      name: "CommonCore",
      dependencies: ["CommonCoreFFI"],
      path: "Generated/CommonCore",
      linkerSettings: [
        .unsafeFlags(["-L", "\(generated)/lib"]),
        .linkedLibrary("common_ffi"),
      ]
    ),
    .target(name: "CommonApp", dependencies: ["CommonCore"]),
    .executableTarget(name: "CommonBrowser", dependencies: ["CommonApp", "CommonCore"]),
    .testTarget(name: "CommonAppTests", dependencies: ["CommonApp"]),
  ]
)
