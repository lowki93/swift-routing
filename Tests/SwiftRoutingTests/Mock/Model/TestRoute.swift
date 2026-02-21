import SwiftRouting

enum TestRoute: Route {
  case home
  case details(id: String)
  case settings

  var name: String {
    switch self {
    case .home: "home"
    case .details: "details"
    case .settings: "settings"
    }
  }
}
