//
//  Route.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import Foundation

/// Defines route types used to navigate between views.
///
/// The `Route` type is an enumeration that represents all available views.
///
/// ## Defining a Route
/// Routes are defined as an enumeration with associated values when needed.
/// ```swift
/// enum HomeRoute {
///   case page1
///   case page2(Int)
///   case page3(String)
/// }
/// ```
///
/// ## Associating a Route with a View
/// Use the `RouteDestination` protocol to map a route to a specific view.
/// ```swift
/// extension HomeRoute: @retroactive RouteDestination {
///   public static func view(for route: HomeRoute) -> some View {
///     switch route {
///       case .page1: Page1View()
///       case let .page2(value): Page2View(value: value)
///       case let .page3(value): Page3View(value: value)
///     }
///   }
/// }
/// ```
///
/// ## Using a Route for Navigation
/// You can trigger navigation using a router instance:
/// ```swift
/// Button("Go to Page 1") {
///   router.push(HomeRoute.page1)
/// }
/// ```
public protocol Route: Hashable, Sendable {
  /// `Name` of your route
  var name: String { get }
}

@dynamicMemberLookup
public struct AnyRoute: Identifiable, Equatable {
  public var id: Int { wrapped.hashValue }
  var wrapped: any Route

  public subscript<T>(dynamicMember keyPath: KeyPath<any Route, T>) -> T {
    wrapped[keyPath: keyPath]
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}
