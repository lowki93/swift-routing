import SwiftRouting

/// A minimal `Codable` route, used by the navigation restoration tests.
enum CodableTestRoute: Route, Codable {
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

/// Stands for `CodableTestRoute` after an app update renamed or removed its cases:
/// a payload saved by the old type no longer decodes into it.
enum RenamedCodableTestRoute: Route, Codable {
  case landing

  var name: String {
    "landing"
  }
}
