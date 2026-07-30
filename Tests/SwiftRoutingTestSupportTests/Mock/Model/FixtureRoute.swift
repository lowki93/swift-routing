import SwiftRouting

enum FixtureRoute: Route {
  case home
  case details(id: String)

  var name: String {
    switch self {
    case .home: "home"
    case .details: "details"
    }
  }
}
