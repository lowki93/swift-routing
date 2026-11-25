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

/// A route whose encoding always fails, to exercise the save failure path.
enum ThrowingEncodeRoute: Route, Codable {
  case broken

  var name: String {
    "broken"
  }

  func encode(to encoder: any Encoder) throws {
    throw EncodingError.invalidValue(self, .init(codingPath: [], debugDescription: "cannot encode"))
  }

  init(from decoder: any Decoder) throws {
    self = .broken
  }

  init() {
    self = .broken
  }
}
