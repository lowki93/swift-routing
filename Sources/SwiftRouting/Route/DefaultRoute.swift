//
//  DefaultRoute.swift
//  swift-routing
//
//  Created by Kévin Budain on 10/10/25.
//

/// Default route used to initialize the routing library.
///
/// Provides a main route and a custom route for special routing cases.
public enum DefaultRoute: Route {
  /// The main default route, typically used for initialization.
  case main
  /// Generates a custom route for handling special cases.
  case custom(String)

  public var name: String {
    switch self {
    case .main: "main"
    case let .custom(name): name
    }
  }
}
