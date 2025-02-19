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
  case tab(String)
  /// A router linked to a navigation stack.
  case stack(String)
  /// A router presented as a sheet or cover.
  case presented(String)

  /// Indicates whether the router is presented as a sheet or cover.
  var isPresented: Bool {
    switch self {
    case .presented: true
    default: false
    }
  }
}
