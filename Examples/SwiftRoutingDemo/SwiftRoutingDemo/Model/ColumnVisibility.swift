//
//  ColumnVisibility.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 24/06/2026.
//

import Foundation

enum ColumnVisibility: String, Identifiable, Hashable, Sendable, CaseIterable {
  case detailOnly
  case doubleColumn
  case all
  case automatic

  var id: String {
    rawValue
  }
}
