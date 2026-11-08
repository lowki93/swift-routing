// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import CompilerPluginSupport
import PackageDescription

let package = Package(
  name: "swift-routing",
  platforms: [
    .iOS(.v17),
    .macOS(.v14)
  ],
  products: [
    .library(name: "SwiftRouting", targets: ["SwiftRouting"]),
    .library(name: "SwiftRoutingMacros", targets: ["SwiftRoutingMacros"]),
    .library(name: "SwiftRoutingTestSupport", targets: ["SwiftRoutingTestSupport"]),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.4.5"),
    .package(url: "https://github.com/swiftlang/swift-syntax.git", "600.0.0"..<"700.0.0"),
  ],
  targets: [
    // Targets are the basic building blocks of a package, defining a module or a test suite.
    // Targets can depend on other targets in this package and products from dependencies.
    .target(
      name: "SwiftRouting",
      resources: [.process("SwiftRouting.docc")],
      swiftSettings: [.define("DEBUG", .when(configuration: .debug))]
    ),
    // Opt-in: only adopters of `@Routable`/`@RouteName` build swift-syntax.
    .target(name: "SwiftRoutingMacros", dependencies: ["SwiftRouting", "SwiftRoutingMacrosPlugin"]),
    .macro(
      name: "SwiftRoutingMacrosPlugin",
      dependencies: [
        .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
        .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
      ]
    ),
    .target(name: "SwiftRoutingTestSupport", dependencies: ["SwiftRouting"]),
    .testTarget(name: "SwiftRoutingTests", dependencies: ["SwiftRouting", "SwiftRoutingMacros"]),
    .testTarget(name: "SwiftRoutingTestSupportTests", dependencies: ["SwiftRoutingTestSupport"]),
    .testTarget(
      name: "SwiftRoutingMacrosTests",
      dependencies: [
        "SwiftRoutingMacrosPlugin",
        .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
        .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
      ]
    ),
  ]
)
