//
//  TabRouter.swift
//  swift-routing
//
//  Created by Kevin Budain on 06/03/2025.
//

import Observation
import SwiftUI

@MainActor @Observable
public final class TabRouter: BaseRouter, @unchecked Sendable {

  public var tab: AnyTabRoute

  init(tab: some TabRoute, parent: Router) {
    self.tab = AnyTabRoute(wrapped: tab)
    super.init(configuration: parent.configuration, parent: parent)
    parent.addChild(self)
    log(.routerLifecycle, message: "init", metadata: ["from": parent])
  }
}

// MARK: - Navigation

extension TabRouter {
  public func change(tab: some TabRoute) {
    self.tab = AnyTabRoute(wrapped: tab)
    log(.action, message: "changeTab", metadata: ["tab": tab.name])
  }

  public func push(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.push(destination)
  }

  public func present(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.present(destination)
  }

  public func cover(_ destination: some Route, in tab: some TabRoute) {
    change(tab: tab)
    find(tab: tab)?.cover(destination)
  }
}

// MARK: - Tab

public extension TabRouter {
  /// Finds the corresponding router for a given tab.
  ///
  /// This method searches among the child routers to find the one associated with the specified tab.
  ///
  /// - Parameter tab: The `TabRoute` to search for.
  @discardableResult func find(tab: some TabRoute) -> Router? {
    children.values.compactMap({ $0.value as? Router }).first(where: { $0.type == tab.type })
  }
}

// MARK: - Deeplink

public extension TabRouter {

  func handle(tabDeeplink: TabDeeplink<some TabRoute, some Route>) {
    change(tab: tabDeeplink.tab)

    guard let deeplink = tabDeeplink.deeplink else { return }
    find(tab: tabDeeplink.tab)?.handle(deeplink: deeplink)
  }
}
