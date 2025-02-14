//
//  Route.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 21/01/2025.
//

import Foundation

public protocol Route: Hashable, Sendable {
  var name: String { get }
}

@dynamicMemberLookup
public struct AnyRoute: Identifiable, Equatable {
  public var id: Int { wrapped.hashValue }
  var wrapped: any Route

  public subscript<T>(dynamicMember keyPath: KeyPath<any Route, T>) -> T {
    wrapped[keyPath: keyPath]
  }

  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.hashValue == rhs.hashValue
  }
}
