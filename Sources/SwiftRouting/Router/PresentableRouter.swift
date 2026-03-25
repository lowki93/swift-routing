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
/// ``Router`` and future types like `SplitRouter`. It owns the shared presentation
/// state (`sheet`, `cover`, `triggerClose`) and provides default implementations of
/// ``PresentationModel``, so subclasses get modal presentation for free.
///
/// You should not use `PresentableRouter` directly — use ``Router`` or a subclass instead.
public class PresentableRouter: BaseRouter {

  /// The route currently presented as a sheet, or `nil` if no sheet is shown.
  @Published internal var sheet: AnyRoute? {
    didSet {
      guard oldValue != sheet else { return }
      present.send((sheet != nil, self))
    }
  }

  /// The route currently presented as a full-screen cover, or `nil` if none is shown.
  @Published internal var cover: AnyRoute? {
    didSet {
      guard oldValue != cover else { return }
      present.send((cover != nil, self))
    }
  }

  /// Triggers dismissal of the current modal when set to `true`.
  @Published internal var triggerClose: Bool = false

  /// Indicates whether this router is presented modally.
  ///
  /// Defaults to `false`. Subclasses override this to reflect their presentation state.
  public var isPresented: Bool { false }
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
    triggerClose = true
    log(.action(.close))
  }

  @MainActor public func closeChildren() {
    for child in children.values.compactMap({ $0.value as? PresentableRouter }) where child.isPresented {
      log(.action(.closeChildren(child)))
      sheet = nil
      cover = nil
    }
  }
}
