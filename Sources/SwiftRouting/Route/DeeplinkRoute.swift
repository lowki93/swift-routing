//
//  DeeplinkRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 09/02/2025.
//

public struct DeeplinkRoute<R: Route> {
  let type: RoutingType
  let path: [R]
  let route: R

  public init(type: RoutingType, path: [R] = [], route: R) {
    self.type = type
    self.path = path
    self.route = route
  }
}
