//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Observation
import SwiftUI

struct WeakContainer<T: AnyObject> {
  weak var value: T?
}

@Observable
public class Router: ObservableObject, Identifiable, @unchecked Sendable {

  internal static let defaultRouter: Router = Router(type: .root)

  public let id: UUID = UUID()

  internal var path = NavigationPath()
  internal var sheet: AnyRoute?
  internal var cover: AnyRoute?
  internal var triggerDismiss: Bool = false

  internal let type: RouterType
  internal weak var parent: Router?
  internal var children: [UUID: WeakContainer<Router>] = [:]

  init(type: RouterType) {
    self.type = type
    log("init `\(type)`")
  }

  init(type: RouterType, parent: Router) {
    self.type = type
    self.parent = parent
    parent.addChild(self)
    log("init `\(type)` from parent `\(parent.type)`")
  }

  deinit {
    parent?.removeChild(self)
    log("deinit")
  }
}

public extension Router {
  func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  func present(_ destination: some Route) {
    route(to: destination, type: .sheet)
  }

  func cover(_ destination: some Route) {
    route(to: destination, type: .cover)
  }
}

public extension Router {
  func dismiss() {
    if type.isPresented {
      triggerDismiss = true
      log("dismiss")
    } else {
      path.removeLast()
    }
  }
}

internal extension Router {
  func addChild(_ child: Router) {
    children[child.id] = WeakContainer(value: child)
  }

  func removeChild(_ child: Router) {
    children.removeValue(forKey: child.id)
  }
}

private extension Router {
  func route(to destination: some Route, type: RoutingType) {
    log("navigating to: \(destination), type: \(type)")

    switch type {
    case .push:
      path.append(destination)
    case .sheet:
      sheet = AnyRoute(wrapped: destination)
    case .cover:
      cover = AnyRoute(wrapped: destination)
    }
  }
}

internal extension Router {
  func onAppear(_ route: some Route) {
//    log("OnAppear - \(route.name)")
  }

  func onDisappear(_ route: some Route) {
//    log("Disappear - \(route.name)")
  }
}

private extension Router {

  func log(_ message: String) {
    let base = "Router \(type.name) (\(id)) - "
    print(base + message)
  }
}
