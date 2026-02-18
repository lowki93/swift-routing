// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "swift-routing",
  platforms: [
    .iOS(.v17),
    .macOS(.v13)
  ],
  products: [
    .library(name: "SwiftRouting", targets: ["SwiftRouting"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(name: "SwiftRouting", resources: [.process("SwiftRouting.docc")]),
    .testTarget(name: "SwiftRoutingTests", dependencies: ["SwiftRouting"]),
  ]
)
