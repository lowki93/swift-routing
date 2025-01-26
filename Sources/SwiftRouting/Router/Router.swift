//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Observation
import SwiftUI

@Observable
public class Router: @unchecked Sendable {
  internal static let defaultRouter: Router = Router()

  let id: UUID = UUID()
  weak var parent: Router?

  public var path = NavigationPath()
  public var sheet: AnyRouteDestination?
  public var cover: AnyRouteDestination?

  public init() {
    log("Router root: \(id)")
  }

  public init(parent: Router) {
    self.parent = parent
    log("Router init: \(id), from parent: \(parent.id)")
  }

  deinit {
    log("Router deinit: \(id)")
  }
}

public extension Router {
  func push(_ destination: some RouteDestination) {
    route(to: destination, type: .push)
  }

  func present(_ destination: some RouteDestination) {
    route(to: destination, type: .sheet)
  }

  func cover(_ destination: some RouteDestination) {
    route(to: destination, type: .cover)
  }
}

public extension Router {
  func dimiss() {
    sheet = nil
    cover = nil
  }
}

private extension Router {
  func route(to destination: some RouteDestination, type: RoutingType) {
    log("Router \(id.uuidString) is navigating to: \(destination), type: \(type)")

    switch type {
    case .push:
      path.append(destination)
    case .sheet:
      sheet = AnyRouteDestination(wrapped: destination)
    case .cover:
      cover = AnyRouteDestination(wrapped: destination)
    }
  }
}

private extension Router {
  func log(_ message: String) {
    print(message)
  }
}
