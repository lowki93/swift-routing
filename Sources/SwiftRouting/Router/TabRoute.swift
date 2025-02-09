//
//  TabRoute.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 08/02/2025.
//

public protocol TabRoute: Hashable, Sendable {
  var name: String { get }
  var type: RouterType { get }
}

public extension TabRoute {
  var type: RouterType { .tab(name) }
}
