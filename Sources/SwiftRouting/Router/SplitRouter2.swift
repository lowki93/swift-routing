//
//  SplitRouter2.swift
//  SwiftRouting
//
//  Created by Kevin Budain on 10/06/2026.
//

import SwiftUI

/// A router managing sheet, cover, and typed column selections at the `RoutingSplitView2` level.
///
/// `SplitRouter2` exposes typed `Binding<T?>` for each column via ``contentBinding(as:)``
/// and ``detailBinding(as:)``, letting the sidebar and content columns drive their respective
/// neighbours without depending on a specific type at the router level.
///
/// ```swift
/// @Environment(\.splitRouter2) var splitRouter
///
/// // Sidebar drives the detail column
/// List(array, selection: splitRouter?.detailBinding(as: PlayerType.self)) { item in
///   NavigationLink(item.label, value: item)
/// }
///
/// // Programmatic selection
/// splitRouter?.select(detail: PlayerType.footballer)
/// ```
public final class SplitRouter2: PresentableRouter, @unchecked Sendable {

  @Published internal var contentSelection: AnyHashable?
  @Published internal var detailSelection: AnyHashable?

  /// `true` when the split view was created with a content column (3-column layout).
  public let hasContentColumn: Bool

  /// `true` when the app is running on a phone-idiom device (iPhone).
  /// Updated by `RoutingSplitView2` on multitasking resize via `horizontalSizeClass`.
  @Published public internal(set) var isCompact: Bool {
    didSet {
      print("=== isCompact : ", isCompact)
    }
  }

  public override var currentRoute: AnyRoute { root }

  init(root: AnyRoute, hasContentColumn: Bool, parent: BaseRouter) {
    self.hasContentColumn = hasContentColumn
    #if os(iOS)
    self.isCompact = UIDevice.current.userInterfaceIdiom == .phone
    #else
    self.isCompact = false
    #endif
    super.init(configuration: parent.configuration, root: root, parent: parent)
    parent.addChild(self)
  }

  /// Returns a typed `Binding<T?>` wired to the content column selection.
  public func contentBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    Binding(
      get: { [weak self] in self?.contentSelection as? T },
      set: { [weak self] in self?.contentSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Returns a typed `Binding<T?>` wired to the detail column selection.
  public func detailBinding<T: Hashable & Sendable>(as type: T.Type) -> Binding<T?> {
    Binding(
      get: { [weak self] in self?.detailSelection as? T },
      set: { [weak self] in self?.detailSelection = $0.map(AnyHashable.init) }
    )
  }

  /// Programmatically sets the content column selection.
  public func select<T: Hashable & Sendable>(content value: T?) {
    contentSelection = value.map(AnyHashable.init)
  }

  /// Programmatically sets the detail column selection.
  public func select<T: Hashable & Sendable>(detail value: T?) {
    detailSelection = value.map(AnyHashable.init)
  }
}
