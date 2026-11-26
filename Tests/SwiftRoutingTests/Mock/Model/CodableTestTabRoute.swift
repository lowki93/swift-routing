import SwiftRouting

/// A minimal `Codable` tab, used by the navigation restoration tests.
enum CodableTestTabRoute: TabRoute, Codable {
  case a
  case b
  case c

  var name: String {
    switch self {
    case .a: "a"
    case .b: "b"
    case .c: "c"
    }
  }
}

/// Stands for `CodableTestTabRoute` after an app update renamed the type: the saved node of the old
/// type no longer matches any container.
enum RenamedCodableTestTabRoute: TabRoute, Codable {
  case main

  var name: String { "main" }
}
