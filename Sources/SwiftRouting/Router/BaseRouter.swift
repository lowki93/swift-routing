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

extension BaseRouter: CustomStringConvertible {
  public var description: String {
    if let router = self as? Router {
      String(describing: router.type)
    } else if let tabRouter = self as? TabRouter {
      "tabRouter(\(String(describing: type(of: tabRouter.tab.wrapped)).lowercased()))"
    } else {
      "baseRouter"
    }
  }
}
