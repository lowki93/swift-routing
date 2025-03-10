//
//  BaseRouter.swift
//  swift-routing
//
//  Created by Kevin Budain on 09/03/2025.
//

import Foundation
import Observation

public class BaseRouter: ObservableObject, Identifiable {
  public let id: UUID = UUID()
  let configuration: Configuration
  var parent: BaseRouter?
  var children: [UUID: WeakContainer<BaseRouter>] = [:]

  init(configuration: Configuration, parent: BaseRouter? = nil) {
    self.configuration = configuration
    self.parent = parent
  }

  deinit {
    parent?.removeChild(self)
    log(.routerLifecycle, message: "deinit")
  }

  func addChild(_ child: BaseRouter) {
    children[child.id] = WeakContainer(value: child)
  }

  func removeChild(_ child: BaseRouter) {
    children.removeValue(forKey: child.id)
  }

  func log(_ type: LoggerAction, message: String? = nil, metadata: [String: Any]? = nil) {
    configuration.logger?(
      LoggerConfiguration(
        type: type,
        router: self,
        message: message,
        metadata: metadata
      )
    )
  }
}

public extension BaseRouter {
  func tabRouter(for tabRoute: some TabRoute) -> TabRouter? {
    let tabRouters = children.compactMap { $0.value.value as? TabRouter }

    return tabRouters.first { type(of: $0.tab.wrapped) == type(of: tabRoute) }
  }
}

extension BaseRouter: CustomStringConvertible {
  public var description: String {
    if let router = self as? Router {
      "router(\(String(describing: router.type)))"
    } else if let tabRouter = self as? TabRouter {
      "tabRouter(\(String(describing: type(of: tabRouter.tab.wrapped)).lowercased()))"
    } else {
      "baseRouter"
    }
  }
}
