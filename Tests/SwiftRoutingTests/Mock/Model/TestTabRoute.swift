import SwiftRouting

enum TestTabRoute: TabRoute {
  case home
  case settings

  var name: String {
    switch self {
    case .home: "home"
    case .settings: "settings"
    }
  }
}

enum OtherTestTabRoute: TabRoute {
  case main

  var name: String { "main" }
}
