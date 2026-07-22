//
//  NavigationSplitViewVisibility.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 24/06/2026.
//

import SwiftUI

extension NavigationSplitViewVisibility {
  init(from columnVisibility: ColumnVisibility) {
    switch columnVisibility {
    case .detailOnly:
      self = .detailOnly
    case .doubleColumn:
      self = .doubleColumn
    case .all:
      self = .all
    case .automatic:
      self = .automatic
    }
  }

  func toColumnVisibility() -> ColumnVisibility {
    switch self {
    case .detailOnly:
      return .detailOnly
    case .doubleColumn:
      return .doubleColumn
    case .all:
      return .all
    case .automatic:
      return .automatic
    default:
      return .automatic
    }
  }
}
