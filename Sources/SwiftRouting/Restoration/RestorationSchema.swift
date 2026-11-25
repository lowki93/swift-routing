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

  /// A schema for a container of the given type, `nil` for a presented container.
  ///
  /// A presented container takes no part in restoration until the host restores its own modal,
  /// otherwise a sheet the user opens later would start from the previous session's state.
  init?<R: Route>(type: RouterType, route: R.Type) {
    guard !type.isPresented else { return nil }
    self.init(route: route)
  }

  /// The first type that is not `Codable`, if any.
  var firstNonCodable: Any.Type? {
    types.first { !RestorationCodec.isCodable($0) }
  }

  func decodeRoute(_ stored: StoredRoute) throws -> AnyRoute {
    try routeDecoder(stored)
  }
}
