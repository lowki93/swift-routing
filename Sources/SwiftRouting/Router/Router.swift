//
//  Router.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 22/01/2025.
//

import Observation
import SwiftUI

@Observable
open class Router<R: Route> {
  public var path = NavigationPath()
  public var sheet: R?
  public var cover: R?

  public init() {}
}

public extension Router {
  func push(_ route: R) {
    path.append(route)
  }

  func present(_ route: R) {
    sheet = route
  }

  func cover(_ route: R) {
    cover = route
  }
}

public extension Router {
  func dimiss() {
    sheet = nil
    cover = nil
  }
}
