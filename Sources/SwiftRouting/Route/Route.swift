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
