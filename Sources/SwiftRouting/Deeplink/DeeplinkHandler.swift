//
//  DeeplinkHandler.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 13/02/2025.
//

public protocol DeeplinkHandler {
  associatedtype R: Route
  associatedtype D: Route

  func deeplink(route: R) -> DeeplinkRoute<D>?
}
