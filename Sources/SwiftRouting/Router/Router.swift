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

  internal let id: UUID = UUID()
  internal let name: String?
  internal weak var parent: Router?

  internal var children: [UUID: WeakContainer<Router>] = [:]

  public var path = NavigationPath()
  public var sheet: AnyRouteDestination?
  public var cover: AnyRouteDestination?

  public init() {
    self.name = "Root"
    log("init")
  }

  public init(name: String?, parent: Router) {
    self.name = name
    self.parent = parent
    parent.addChild(self)
    log("init from parent: \(parent.id)")
  }

  deinit {
    parent?.removeChild(self)
    log("deinit")
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

internal extension Router {
  internal func addChild(_ child: Router) {
    children[child.id] = WeakContainer(value: child)
  }

  internal func removeChild(_ child: Router) {
    children.removeValue(forKey: child.id)
  }

}

private extension Router {
  func route(to destination: some RouteDestination, type: RoutingType) {
    log("navigating to: \(destination), type: \(type)")

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
    let base = "Router \(name ?? "") (\(id)) - "
    print(base + message)
  }
}

struct WeakContainer<T: AnyObject> {
  weak var value: T?
}
