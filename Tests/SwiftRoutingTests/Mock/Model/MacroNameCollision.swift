// Guards against a user type named like a marker: module-scope types called `Sheet` / `Cover`
// (a common SwiftUI idiom) must not break `@Sheet` / `@Cover` resolution on cases in this module.
enum Sheet: Hashable, Sendable {
  case a
}

enum Cover: Hashable, Sendable {
  case a
}
