//
//  RouterError.swift
//  swift-routing
//
//  Created by Kévin Budain on 09/03/26.
//

import Foundation

/// Errors that can occur during route resolution.
enum RouterError: Error, CustomStringConvertible {

  /// A route could not be matched to a destination.
  case routeNotFound(route: AnyRoute, in: String)

  var description: String {
    switch self {
    case .routeNotFound(let route, let destination):
      return "Route '\(type(of: route.wrapped))' are not define in '\(destination)'"
    }
  }
}
