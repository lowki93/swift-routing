//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Observation
import SwiftUI

@Observable
public class Router: ObservableObject, Identifiable, @unchecked Sendable {

  internal static let defaultRouter: Router = Router(type: .root)

  public let id: UUID = UUID()

  internal var rootRoute: AnyRoute?
  internal var path = NavigationPath()
  internal var sheet: AnyRoute?
  internal var cover: AnyRoute?
  internal var triggerClose: Bool = false
  internal var present: Bool {
    sheet != nil || cover != nil
  }

  internal let type: RouterType
  internal weak var parent: Router?
  internal var children: [UUID: WeakContainer<Router>] = [:]

  init(type: RouterType) {
    self.type = type
    log("init")
  }

  init(type: RouterType, parent: Router) {
    self.type = type
    self.parent = parent
    parent.addChild(self)
    log("init from parent `\(parent.type)`")
  }

  deinit {
    parent?.removeChild(self)
    log("deinit")
  }
}

extension Router: RouterModel {
  public func push(_ destination: some Route) {
    route(to: destination, type: .push)
  }

  public func present(_ destination: some Route) {
    route(to: destination, type: .sheet)
  }

  public func cover(_ destination: some Route) {
    route(to: destination, type: .cover)
  }
}

private extension Router  {
  func route(to destination: some Route, type: RoutingType) {
    log("navigating to: \(destination.name), type: \(type)")

    switch type {
    case .push:
      path.append(destination)
    case .sheet:
      sheet = AnyRoute(wrapped: destination)
    case .cover:
      cover = AnyRoute(wrapped: destination)
    case .root:
      rootRoute = AnyRoute(wrapped: destination)
    }
  }
}

public extension Router {
  func handle(deeplink: DeeplinkRoute<some Route>) {
    parent?.closeChildren()
    popToRoot()

    for route in deeplink.path {
      push(route)
    }

    route(to: deeplink.route, type: deeplink.type)
  }
}

public extension Router {
  func popToRoot() {
    path.popToRoot()
    log("popToRoot")
  }

  func close() {
    if type.isPresented {
      triggerClose = true
      log("close")
    }
  }

  func back() {
    path.removeLast()
    log("back")
  }

  func closeChildren() {
    for router in children.values.compactMap(\.value) where router.present {
      router.sheet = nil
      router.cover = nil
    }
  }
}

public extension Router {
  @discardableResult func find(tab: some TabRoute) -> Router? {
    children.values.compactMap(\.value).first(where: { $0.type == tab.type })
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

internal extension Router {
  func onAppear(_ route: some Route) {
    log("OnAppear - \(route.name)")
  }

  func onDisappear(_ route: some Route) {
    log("Disappear - \(route.name)")
  }
}

private extension Router {

  func log(_ message: String) {
    #if DEBUG
    let base = "[Router]:\(type) - "
    print(base + message)
    #endif
  }
}
