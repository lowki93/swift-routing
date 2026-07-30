import SwiftRouting

enum FixtureTab: TabRoute {
  case home
  case profile

  var name: String {
    switch self {
    case .home: "home"
    case .profile: "profile"
    }
  }
}
