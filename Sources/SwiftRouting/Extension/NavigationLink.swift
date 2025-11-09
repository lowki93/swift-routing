//
//  NavigationLink.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/11/2025.
//

import SwiftUI

public extension NavigationLink where Destination == Never {
  init(route: some Route, @ViewBuilder label: () -> Label) {
    self.init(value: AnyRoute(wrapped: route), label: label)
  }

  init(_ titleKey: LocalizedStringKey, route: some Route) where Label == Text {
    self.init(titleKey, value: AnyRoute(wrapped: route))
  }

  init(_ titleResource: LocalizedStringResource, route: some Route) where Label == Text {
    self.init(titleResource, value: AnyRoute(wrapped: route))
  }

  init<S>(_ title: S, route: some Route) where Label == Text, S : StringProtocol {
    self.init(title, value: AnyRoute(wrapped: route))
  }
}
