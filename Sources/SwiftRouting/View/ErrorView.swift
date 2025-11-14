//
//  ErrorView.swift
//  swift-routing
//
//  Created by Kévin Budain on 11/14/25.
//

import SwiftUI

struct ErrorView<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var router
  private var message: String {
    "Route '\(type(of: route.wrapped))' are not define in '\(String(describing: destination.self))'"
  }
  let route: AnyRoute
  let destination: Destination.Type
  @ViewBuilder let content: (Destination.R, Destination.Type) -> Content

  var body: some View {
    if let route = route.wrapped as? Destination.R {
      content(route, destination)
    } else if router.configuration.shouldCrashOnRouteNotFound {
      fatalError(message)
    } else {
      Text(message).padding()
    }
  }
}
