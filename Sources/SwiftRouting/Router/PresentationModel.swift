//
//  PresentationModel.swift
//  swift-routing
//
//  Created by Kévin Budain on 25/03/26.
//

import Foundation

/// Defines modal and sheet presentation capabilities for router types.
///
/// `PresentationModel` is implemented by ``Router``.
///
/// Use these methods to present routes modally or to dismiss the current router.
public protocol PresentationModel {

  /// Indicates whether this router is presented as a modal (sheet or cover).
  var isPresented: Bool { get }

  /// Presents a route as a modal sheet.
  ///
  /// ``Router`` holds a request made while one of its sheets or covers is still dismissing, and
  /// presents it once that dismissal ends. Only the latest held request is kept, and ``close()`` or
  /// ``closeChildren()`` drops it.
  ///
  /// - Parameters:
  ///   - destination: The route to present.
  ///   - withStack: If `true`, the sheet includes its own navigation stack.
  func present(_ destination: some Route, withStack: Bool)

  /// Presents a route as a full-screen cover.
  ///
  /// ``Router`` holds it while one of its sheets or covers is still dismissing, like
  /// ``present(_:withStack:)``.
  ///
  /// - Parameter destination: The route to present.
  func cover(_ destination: some Route)

  /// Dismisses the current modal router.
  ///
  /// No-op if the router is not presented.
  func close()

  /// Closes all child routers presented from this router.
  func closeChildren()
}

public extension PresentationModel {
  /// Presents a route as a modal sheet with a navigation stack.
  func present(_ destination: some Route) {
    present(destination, withStack: true)
  }
}
