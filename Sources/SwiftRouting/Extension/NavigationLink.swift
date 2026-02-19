//
//  NavigationLink.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/11/2025.
//

import SwiftUI

/// Convenience initializers for `NavigationLink` that work directly with `Route` types.
///
/// These extensions allow you to create navigation links using your `Route` enums
/// instead of manually wrapping them in `AnyRoute`.
///
/// ## Example
/// ```swift
/// // Using a custom label
/// NavigationLink(route: HomeRoute.page2(10)) {
///   Text("Go to Page 2")
/// }
///
/// // Using a localized string key
/// NavigationLink("Go to Page 2", route: HomeRoute.page2(10))
///
/// // Using a string
/// NavigationLink("Details", route: HomeRoute.page3("item"))
/// ```
///
/// ## Behavior
/// These initializers use `NavigationLink(value:)` under the hood, so they always
/// perform stack-based push navigation.
///
/// If you need modal presentation (`sheet`/`cover`), use `router.present(...)`
/// or `router.cover(...)` instead of `NavigationLink`.
///
/// > Note: These links work within a `RoutingView` that has the appropriate
/// > `navigationDestination` configured for your route type.
public extension NavigationLink where Destination == Never {

  /// Creates a navigation link that presents a destination route with a custom label.
  ///
  /// - Parameters:
  ///   - route: The `Route` to navigate to when the link is activated.
  ///   - label: A view builder that produces the label for the link.
  init(route: some Route, @ViewBuilder label: () -> Label) {
    self.init(value: AnyRoute(wrapped: route), label: label)
  }

  /// Creates a navigation link that presents a destination route with a localized text label.
  ///
  /// - Parameters:
  ///   - titleKey: The localized string key for the link's label.
  ///   - route: The `Route` to navigate to when the link is activated.
  init(_ titleKey: LocalizedStringKey, route: some Route) where Label == Text {
    self.init(titleKey, value: AnyRoute(wrapped: route))
  }

  /// Creates a navigation link that presents a destination route with a localized string resource label.
  ///
  /// - Parameters:
  ///   - titleResource: The localized string resource for the link's label.
  ///   - route: The `Route` to navigate to when the link is activated.
  init(_ titleResource: LocalizedStringResource, route: some Route) where Label == Text {
    self.init(titleResource, value: AnyRoute(wrapped: route))
  }

  /// Creates a navigation link that presents a destination route with a string label.
  ///
  /// - Parameters:
  ///   - title: The string for the link's label.
  ///   - route: The `Route` to navigate to when the link is activated.
  init<S>(_ title: S, route: some Route) where Label == Text, S : StringProtocol {
    self.init(title, value: AnyRoute(wrapped: route))
  }
}
