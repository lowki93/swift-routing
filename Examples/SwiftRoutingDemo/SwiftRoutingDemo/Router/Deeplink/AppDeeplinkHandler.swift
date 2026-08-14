//
//  AppDeeplinkHandler.swift
//  SwiftRoutingDemo
//
//  Created by Kevin Budain on 14/08/2026.
//

import SwiftRouting

struct AppDeeplinkHandler: DeeplinkHandler {
  typealias R = AppDeeplinkID
  typealias D = AppRoute

  // Stub: case mapping is SWI-18's scope. This only proves the pipeline compiles and fires.
  func deeplink(from route: AppDeeplinkID) async throws -> DeeplinkRoute<AppRoute>? {
    nil
  }
}
