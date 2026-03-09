//
//  ErrorView.swift
//  swift-routing
//
//  Created by Kévin Budain on 11/14/25.
//

import SwiftUI

struct ErrorView<Destination: RouteDestination, Content: View>: View {

  @Environment(\.router) private var router
  let route: AnyRoute
  let destination: Destination.Type
  @ViewBuilder let content: (Destination.R, Destination.Type) -> Content

  private var error: RouterError {
    .routeNotFound(route: route.wrapped, in: destination)
  }

  var body: some View {
    if let route = route.wrapped as? Destination.R {
      content(route, destination)
    } else {
      let _ = router.log(.error(error))
      if router.configuration.shouldCrashOnRouteNotFound {
        fatalError(error.description)
      } else {
        Text(error.description).padding()
      }
    }
  }
}
