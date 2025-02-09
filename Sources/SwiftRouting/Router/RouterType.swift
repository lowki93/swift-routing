//
//  RouterType.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 06/02/2025.
//

public enum RouterType: Hashable, Sendable {
  case root
  case tab(String)
  case stack(String)
  case presented(String)

  var name: String {
    switch self {
    case .root: "Root"
    case let .tab(name): "Tab - " + name
    case let .stack(name): "Stack - " + name
    case let .presented(name): "Presented - " + name
    }
  }

  var isPresented: Bool {
    switch self {
    case .presented:  true
    default: false
    }
  }
}
