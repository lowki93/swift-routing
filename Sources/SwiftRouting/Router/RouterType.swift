//
//  RouterType.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 06/02/2025.
//

public enum RouterType: Hashable, Sendable {
  case app
  case tab(String)
  case stack(String)
  case presented(String)

  var isPresented: Bool {
    switch self {
    case .presented:  true
    default: false
    }
  }
}
