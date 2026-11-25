//
//  RestorationSchema.swift
//  swift-routing
//

import Foundation

/// What a container knows about its concrete types: whether it can be restored, and how to decode its routes.
struct RestorationSchema {

  /// Every type the container needs to be `Codable`.
  let types: [Any.Type]

  private let routeDecoder: (StoredRoute) throws -> AnyRoute

  /// A schema for a container whose routes are `R`.
  init<R: Route>(route: R.Type) {
    self.types = [R.self]
    self.routeDecoder = { stored in
      AnyRoute(wrapped: try RestorationCodec.decode(R.self, from: stored), inStack: stored.inStack)
    }
  }

  /// The first type that is not `Codable`, if any.
  var firstNonCodable: Any.Type? {
    types.first { !RestorationCodec.isCodable($0) }
  }

  func decodeRoute(_ stored: StoredRoute) throws -> AnyRoute {
    try routeDecoder(stored)
  }
}
