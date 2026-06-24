//
//  RouterType.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 06/02/2025.
//

import Foundation

/// Defines the different types of routers available.
enum RouterType: Hashable, Sendable {
  /// The primary router instantiated at app launch.
  case app
  /// A router associated with a specific tab.
  case tab(String, hideTabBarOnPush: Bool)
  /// A router linked to a navigation stack.
  case stack(String)
  /// A router presented as a sheet or cover.
  case presented(String)
  /// A router managing a split view (sidebar + detail, or sidebar + content + detail).
  case split(String, hasContentColumn: Bool)

  /// Indicates whether the router is presented as a sheet or cover.
  var isPresented: Bool {
    switch self {
    case .presented: true
    default: false
    }
  }

  /// Indicates whether the router manages a split view.
  var isSplit: Bool {
    switch self {
    case .split: true
    default: false
    }
  }
}

extension RouterType: CustomStringConvertible {
  var description: String {
    switch self {
    case .app: "app"
    case let .tab(value, _): "tab(\(value))"
    case let .stack(value): "stack(\(value))"
    case let .presented(value): "presented(\(value))"
    case let .split(value, _): "split(\(value))"
    }
  }
}
