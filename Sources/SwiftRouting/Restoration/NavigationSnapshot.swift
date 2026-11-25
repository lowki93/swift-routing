//
//  NavigationSnapshot.swift
//  swift-routing
//

import Foundation

/// A route saved as an opaque JSON payload, decoded only by the container that knows its concrete type.
struct StoredRoute: Codable, Equatable, Sendable {
  var payload: Data
  var inStack: Bool
}

/// What a single router contributes to a snapshot.
///
/// Contexts, `pendingModal`, `dismissingChild`, the subjects and `isCompact` are transient and
/// deliberately have no field here.
struct RouterState: Codable, Equatable, Sendable {
  var root: StoredRoute?
  var path: [StoredRoute] = []
  var sheet: StoredRoute?
  var cover: StoredRoute?
  var tab: StoredRoute?
  var contentSelection: StoredRoute?
  var detailSelection: StoredRoute?
}

/// A router in the saved tree: its own state, and its children keyed by segment.
struct RestorationNode: Codable, Equatable, Sendable {
  var state: RouterState?
  var children: [String: RestorationNode] = [:]

  var isEmpty: Bool {
    state == nil && children.isEmpty
  }

  /// The node reached by following `path` from this one, if it exists.
  func node(at path: ArraySlice<String>) -> RestorationNode? {
    guard let segment = path.first else { return self }
    return children[segment]?.node(at: path.dropFirst())
  }
}

/// The versioned tree written to the scene storage.
struct NavigationSnapshot: Codable, Equatable, Sendable {
  static let currentVersion = 1
  static let empty = NavigationSnapshot(version: currentVersion, root: RestorationNode())

  var version: Int
  var root: RestorationNode
}

/// Which modal slot of its parent a presented router fills.
enum ModalSlot: String, Codable, Sendable {
  case sheet
  case cover
}
