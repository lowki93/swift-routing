// Guards against a user type named like a marker: module-scope types called `Sheet` / `Cover`
// (a common SwiftUI idiom) must not break `@Sheet` / `@Cover` resolution on cases in this module.
enum Sheet: Hashable, Sendable {
  case a
}

enum Cover: Hashable, Sendable {
  case a
}

// Same for `@HideTabBarOnPush`: a module-scope type with that name must not break the marker.
enum HideTabBarOnPush: Hashable, Sendable {
  case a
}
