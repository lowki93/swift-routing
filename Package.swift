// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-routing",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(name: "SwiftRouting", targets: ["SwiftRouting"]),
    .library(name: "SwiftRoutingTestSupport", targets: ["SwiftRoutingTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftRouting",
      resources: [.process("SwiftRouting.docc")],
      swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
    ),
    .target(name: "SwiftRoutingTestSupport", dependencies: ["SwiftRouting"]),
    .testTarget(name: "SwiftRoutingTests", dependencies: ["SwiftRouting"]),
    .testTarget(name: "SwiftRoutingTestSupportTests", dependencies: ["SwiftRoutingTestSupport"]),
  ]
)
