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
  private let contentDecoder: ((StoredRoute) throws -> AnyHashable)?
  private let detailDecoder: ((StoredRoute) throws -> AnyHashable)?

  /// A schema for a container whose routes are `R`.
  init<R: Route>(route: R.Type) {
    self.types = [R.self]
    self.routeDecoder = Self.routeDecoder(R.self)
    self.contentDecoder = nil
    self.detailDecoder = nil
  }

  /// A schema for a split whose routes are `R` and whose selections are `ContentData` and `DetailData`.
  /// `Never` (a 2-column split) is `Codable`, so it passes the check.
  init<R: Route, ContentData: Hashable & Sendable, DetailData: Hashable & Sendable>(
    route: R.Type,
    content: ContentData.Type,
    detail: DetailData.Type
  ) {
    self.types = [R.self, ContentData.self, DetailData.self]
    self.routeDecoder = Self.routeDecoder(R.self)
    self.contentDecoder = { AnyHashable(try RestorationCodec.decode(ContentData.self, from: $0)) }
    self.detailDecoder = { AnyHashable(try RestorationCodec.decode(DetailData.self, from: $0)) }
  }

  private static func routeDecoder<R: Route>(_ type: R.Type) -> (StoredRoute) throws -> AnyRoute {
    { stored in AnyRoute(wrapped: try RestorationCodec.decode(R.self, from: stored), inStack: stored.inStack) }
  }

  /// The first type that is not `Codable`, if any.
  var firstNonCodable: Any.Type? {
    types.first { !RestorationCodec.isCodable($0) }
  }

  func decodeRoute(_ stored: StoredRoute) throws -> AnyRoute {
    try routeDecoder(stored)
  }

  func decodeContentSelection(_ stored: StoredRoute) throws -> AnyHashable {
    guard let contentDecoder else { throw RestorationCodec.TypeMismatch(expected: "content selection") }
    return try contentDecoder(stored)
  }

  func decodeDetailSelection(_ stored: StoredRoute) throws -> AnyHashable {
    guard let detailDecoder else { throw RestorationCodec.TypeMismatch(expected: "detail selection") }
    return try detailDecoder(stored)
  }
}
