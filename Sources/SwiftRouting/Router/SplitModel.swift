//
//  SplitModel.swift
//  swift-routing
//
//  Created by Kevin Budain on 25/06/2026.
//

import SwiftUI

/// Defines the interface for a router that manages a split view layout.
///
/// `SplitModel` abstracts the column-selection state and navigation methods shared by
/// any split-view router. ``Router`` conforms to this protocol when created with a
/// `.split` ``RouterType``.
///
/// Conforming types drive column selections via typed bindings or programmatic calls,
/// and expose `isCompact` so views can adapt to compact (iPhone / multitasking) environments.
///
/// ```swift
/// @Environment(\.router) var router
///
/// // Drive a list selection
/// List(players, selection: router.detailBinding(as: Player.self)) { ... }
///
/// // Programmatic selection
/// router.select(detail: players.first)
///
/// // Compact-mode guard
/// guard !router.isCompact else { return }
/// ```
public protocol SplitModel {

  /// The currently selected value for the detail column, type-erased.
  var detailSelection: AnyHashable? { get }

  /// The currently selected value for the content column (3-column layout), type-erased.
  var contentSelection: AnyHashable? { get }

  /// Whether the split view is currently in compact (single-column) mode.
  ///
  /// `true` on iPhone at launch and whenever `horizontalSizeClass` becomes `.compact`
  /// (e.g. during iPad multitasking). Always `false` for non-split routers.
  ///
  /// Use this to adapt sidebar behaviour — e.g. skip auto-selection on iPhone so the
  /// user's first tap triggers navigation rather than a silent highlight.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   guard !router.isCompact else { return }
  ///   router.select(detail: items.first)
  /// }
  /// ```
  var isCompact: Bool { get set }

  /// Whether this router was created with a content column (3-column layout).
  ///
  /// `true` when `RoutingSplitView2` was initialised with a `content:` closure.
  /// Always `false` for 2-column layouts.
  ///
  /// ```swift
  /// if router.hasContentColumn {
  ///   router.select(content: playerType)
  /// } else {
  ///   router.select(detail: playerType)
  /// }
  /// ```
  var hasContentColumn: Bool { get }

  /// Type-erased factory that maps a detail selection to its `AnyRoute`.
  /// Set by `RoutingSplitView2` at initialisation; used internally to resolve `currentRoute`.
  var detailRouteFactory: ((AnyHashable) -> AnyRoute?)? { get set }

  /// Type-erased factory that maps a content selection to its `AnyRoute`.
  /// Set by `RoutingSplitView2` at initialisation; used internally to resolve `currentRoute`.
  var contentRouteFactory: ((AnyHashable) -> AnyRoute?)? { get set }

  /// Returns a typed `Binding<T?>` wired to the content column selection (3-column layout).
  ///
  /// Intended for use in the sidebar of a 3-column `RoutingSplitView2` to drive the
  /// content column via a `List` selection binding.
  /// Returns `.constant(nil)` for non-split routers.
  ///
  /// ```swift
  /// List(playerTypes, selection: router.contentBinding(as: PlayerType.self)) { type in
  ///   NavigationLink(type.label, value: type)
  /// }
  /// ```
  ///
  /// - Parameter type: The `Hashable` type of the content column selection.
  /// - Returns: A binding to the current content selection, or `.constant(nil)` for non-split routers.
  func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?>

  /// Returns a typed `Binding<T?>` wired to the detail column selection.
  ///
  /// Intended for use in the sidebar (2-column) or content column (3-column) of a
  /// `RoutingSplitView2` to drive the detail column via a `List` selection binding.
  /// Returns `.constant(nil)` for non-split routers.
  ///
  /// ```swift
  /// List(players, selection: router.detailBinding(as: Player.self)) { player in
  ///   NavigationLink(player.name, value: player)
  /// }
  /// ```
  ///
  /// - Parameter type: The `Hashable` type of the detail column selection.
  /// - Returns: A binding to the current detail selection, or `.constant(nil)` for non-split routers.
  func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?>

  /// Programmatically drives the content column selection (3-column layout).
  ///
  /// Equivalent to the user tapping a row in the sidebar of a 3-column split view.
  /// No-op for non-split routers or when `hasContentColumn` is `false`.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   router.select(content: playerTypes.first)
  /// }
  /// ```
  ///
  /// - Parameter value: The value to select, or `nil` to clear the selection.
  func select<T: Hashable & Sendable>(content value: T?)

  /// Programmatically drives the detail column selection.
  ///
  /// Equivalent to the user tapping a row in the sidebar (2-column) or content column
  /// (3-column). No-op for non-split routers.
  ///
  /// ```swift
  /// .onFirstAppear {
  ///   guard !router.isCompact else { return }
  ///   router.select(detail: players.first)
  /// }
  /// ```
  ///
  /// - Parameter value: The value to select, or `nil` to clear the selection.
  func select<T: Hashable & Sendable>(detail value: T?)
}
