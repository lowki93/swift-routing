//
//  PresentationModel.swift
//  swift-routing
//
//  Created by Kévin Budain on 25/03/26.
//

import Foundation

/// Defines modal and sheet presentation capabilities for router types.
///
/// `PresentationModel` is implemented by ``PresentableRouter`` and shared by all
/// concrete router types that support sheet and cover presentation, such as
/// ``Router`` and future router types like `SplitRouter`.
///
/// Use these methods to present routes modally or to dismiss the current router.
public protocol PresentationModel {

  /// Indicates whether this router is presented as a modal (sheet or cover).
  var isPresented: Bool { get }

  /// Presents a route as a modal sheet.
  ///
  /// - Parameters:
  ///   - destination: The route to present.
  ///   - withStack: If `true`, the sheet includes its own navigation stack.
  func present(_ destination: some Route, withStack: Bool)

  /// Presents a route as a full-screen cover.
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
