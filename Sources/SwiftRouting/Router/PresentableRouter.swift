//
//  PresentableRouter.swift
//  swift-routing
//
//  Created by Kévin Budain on 25/03/26.
//

import Combine
import Foundation

/// An intermediate router class that adds sheet and cover presentation capabilities.
///
/// `PresentableRouter` sits between ``BaseRouter`` and concrete router types such as
/// ``Router`` and any concrete router type that needs modal presentation. It owns the shared presentation
/// state (`sheet`, `cover`, `triggerClose`) and provides default implementations of
/// ``PresentationModel``, so subclasses get modal presentation for free.
///
/// You should not use `PresentableRouter` directly — use ``Router`` instead.
public class PresentableRouter: BaseRouter {

  /// The route currently presented as a sheet, or `nil` if no sheet is shown.
  @Published internal var sheet: AnyRoute? {
    didSet {
      guard oldValue != sheet else { return }
      present.send((sheet != nil, self))
      logCloseIfNeeded(from: oldValue, to: sheet)
    }
  }

  /// The route currently presented as a full-screen cover, or `nil` if none is shown.
  @Published internal var cover: AnyRoute? {
    didSet {
      guard oldValue != cover else { return }
      present.send((cover != nil, self))
      logCloseIfNeeded(from: oldValue, to: cover)
    }
  }

  /// Triggers dismissal of the current modal when set to `true`.
  @Published internal var triggerClose: Bool = false

  /// Set right after logging an explicit `.action(.close)`, so `logCloseIfNeeded` doesn't log
  /// a second time once `sheet`/`cover` actually clears -- which, for `close()`, happens later
  /// via `CloseModifier`'s native `dismiss()`, not synchronously within the call.
  private var isCloseLoggedExplicitly = false

  /// Indicates whether this router is presented modally.
  ///
  /// Defaults to `false`. Subclasses override this to reflect their presentation state.
  public var isPresented: Bool { false }

  /// Catches dismissals that bypass `close()` entirely -- a native swipe-down, tapping outside
  /// the sheet, or a `@Environment(\.dismiss)` call from inside the presented content all clear
  /// `sheet`/`cover` directly through the live `.sheet(item:)`/`.cover(item:)` binding.
  private func logCloseIfNeeded(from oldValue: AnyRoute?, to newValue: AnyRoute?) {
    guard oldValue != nil, newValue == nil else { return }
    guard !isCloseLoggedExplicitly else {
      isCloseLoggedExplicitly = false
      return
    }
    log(.action(.close))
  }
}

// MARK: - PresentationModel

extension PresentableRouter: @preconcurrency PresentationModel {

  @MainActor public func present(_ destination: some Route, withStack: Bool) {
    log(.navigation(from: currentRoute.wrapped, to: destination, type: .sheet(withStack: withStack)))
    sheet = AnyRoute(wrapped: destination, inStack: withStack)
  }

  @MainActor public func cover(_ destination: some Route) {
    log(.navigation(from: currentRoute.wrapped, to: destination, type: .cover))
    cover = AnyRoute(wrapped: destination)
  }

  @MainActor public func close() {
    guard isPresented else { return }
    if let presenter = parent as? PresentableRouter {
      presenter.isCloseLoggedExplicitly = true
      presenter.log(.action(.close))
    }
    triggerClose = true
  }

  @MainActor public func closeChildren() {
    let presentedChildren = children.values.compactMap({ $0.value as? PresentableRouter }).filter(\.isPresented)

    guard !presentedChildren.isEmpty else { return }
    presentedChildren.forEach { log(.action(.closeChildren($0))) }
    isCloseLoggedExplicitly = true
    sheet = nil
    isCloseLoggedExplicitly = true
    cover = nil
  }
}
