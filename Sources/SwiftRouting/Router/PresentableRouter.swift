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

  /// Set by `close()` right before it logs its own `.action(.close)` on `self`, so
  /// `logCloseIfNeeded` -- triggered later, on the *parent*, once `sheet`/`cover` actually
  /// clears via `CloseModifier`'s native `dismiss()` -- knows not to log a second time.
  private var isCloseLoggedExplicitly = false

  /// Indicates whether this router is presented modally.
  ///
  /// Defaults to `false`. Subclasses override this to reflect their presentation state.
  public var isPresented: Bool { false }

  /// Catches dismissals that bypass `close()` entirely -- a native swipe-down, tapping outside
  /// the sheet, or a `@Environment(\.dismiss)` call from inside the presented content all clear
  /// `sheet`/`cover` directly through the live `.sheet(item:)`/`.cover(item:)` binding.
  ///
  /// Called on the *parent* (whoever owns `sheet`/`cover`), but attributes the log to the
  /// *presented* child router -- matched by `root`, since that's what `close()` itself logs on
  /// when called explicitly, and the two shouldn't disagree on who dismissed what.
  private func logCloseIfNeeded(from oldValue: AnyRoute?, to newValue: AnyRoute?) {
    guard let oldValue, newValue == nil else { return }
    guard let presentedChild = children.values
      .compactMap({ $0.value as? PresentableRouter })
      .first(where: { $0.isPresented && $0.root == oldValue })
    else { return }
    guard !presentedChild.isCloseLoggedExplicitly else {
      presentedChild.isCloseLoggedExplicitly = false
      return
    }
    presentedChild.log(.action(.close))
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
    isCloseLoggedExplicitly = true
    triggerClose = true
    log(.action(.close))
  }

  @MainActor public func closeChildren() {
    let presentedChildren = children.values.compactMap({ $0.value as? PresentableRouter }).filter(\.isPresented)

    guard !presentedChildren.isEmpty else { return }
    presentedChildren.forEach {
      $0.isCloseLoggedExplicitly = true
      log(.action(.closeChildren($0)))
    }
    sheet = nil
    cover = nil
  }
}
