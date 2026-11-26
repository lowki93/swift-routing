//
//  RestorationCodec.swift
//  swift-routing
//

import Foundation

/// Encodes and decodes routes whose concrete type is only known at runtime.
enum RestorationCodec {

  struct NotCodable: Error, CustomStringConvertible {
    let type: String
    var description: String { "'\(type)' is not Codable" }
  }

  struct TypeMismatch: Error, CustomStringConvertible {
    let expected: String
    var description: String { "decoded value is not a '\(expected)'" }
  }

  /// Whether `type` can be saved and restored.
  static func isCodable(_ type: Any.Type) -> Bool {
    type is any Encodable.Type && type is any Decodable.Type
  }

  static func name(of type: Any.Type) -> String {
    String(describing: type)
  }

  static func encode(_ route: AnyRoute) throws -> StoredRoute {
    try encode(value: route.wrapped, inStack: route.inStack)
  }

  /// Encodes any `Encodable` value, such as a split selection.
  static func encode(value: Any, inStack: Bool = true) throws -> StoredRoute {
    guard let encodable = value as? any Encodable else {
      throw NotCodable(type: name(of: Swift.type(of: value)))
    }
    return StoredRoute(payload: try makeEncoder().encode(encodable), inStack: inStack)
  }

  /// Decodes `stored` as a `T`, validating the cast to the concrete type.
  static func decode<T>(_ type: T.Type, from stored: StoredRoute) throws -> T {
    guard let decodable = type as? any Decodable.Type else {
      throw NotCodable(type: name(of: type))
    }
    let value = try JSONDecoder().decode(decodable, from: stored.payload)
    guard let typed = value as? T else {
      throw TypeMismatch(expected: name(of: type))
    }
    return typed
  }

  static func makeEncoder() -> JSONEncoder {
    let encoder = JSONEncoder()
    // Stable output: saving the same tree twice gives the same `Data`.
    encoder.outputFormatting = [.sortedKeys]
    return encoder
  }
}
