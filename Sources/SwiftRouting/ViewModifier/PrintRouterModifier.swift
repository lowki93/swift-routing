//
//  PrintRouterModifier.swift
//  swift-routing
//

import SwiftUI

extension BaseRouter {

  /// Walks up to the top-most router in the hierarchy (the one with no `parent`).
  var rootRouter: BaseRouter {
    parent?.rootRouter ?? self
  }

  /// Builds a human-readable, indented tree of this router's full hierarchy, starting from
  /// ``rootRouter``. Each line shows ``description`` plus the router's current route.
  func routerTreeDescription() -> String {
    rootRouter.treeLines().joined(separator: "\n")
  }

  private func treeLines(prefix: String = "", isRoot: Bool = true, isLast: Bool = true) -> [String] {
    let connector = isRoot ? "" : (isLast ? "└─ " : "├─ ")
    let line = "\(prefix)\(connector)\(description) — current: \(currentRoute.wrapped.description)"

    let childPrefix = isRoot ? "" : prefix + (isLast ? "   " : "│  ")
    // `children` is a Dictionary, whose iteration order is not deterministic --
    // sort so the printed tree is stable across calls instead of shuffling randomly.
    let sortedChildren = children.values.compactMap(\.value).sorted { $0.id.uuidString < $1.id.uuidString }

    let childLines = sortedChildren.enumerated().flatMap { index, child in
      child.treeLines(prefix: childPrefix, isRoot: false, isLast: index == sortedChildren.count - 1)
    }

    return [line] + childLines
  }
}

private struct PrintRouterModifier: ViewModifier {

  @Environment(\.router) private var router

  func body(content: Content) -> some View {
    content
      .onAppear { print(router.routerTreeDescription()) }
  }
}

private struct PrintRouterOnChangeModifier<T: Equatable>: ViewModifier {

  @Environment(\.router) private var router
  let trigger: T

  func body(content: Content) -> some View {
    content
      .onAppear { print(router.routerTreeDescription()) }
      .onChange(of: trigger) { print(router.routerTreeDescription()) }
  }
}

public extension View {

  /// Prints the full router hierarchy (starting from the top-most router) to the console
  /// when this view appears. Useful for debugging navigation state.
  ///
  /// ```swift
  /// struct SomeView: View {
  ///   var body: some View {
  ///     content
  ///       .printRouter()
  ///   }
  /// }
  /// ```
  ///
  /// Prints something like:
  /// ```
  /// router(app) — current: home
  /// ├─ tabRouter(hometab) — current: home
  /// │  ├─ router(tab(home)) — current: profile(userId: "42")
  /// │  └─ router(tab(settings)) — current: settings
  /// └─ router(presented(sheet)) — current: onboarding
  /// ```
  func printRouter() -> some View {
    modifier(PrintRouterModifier())
  }

  /// Prints the full router hierarchy to the console when this view appears, and again
  /// every time `trigger` changes. Useful for watching navigation state evolve over time.
  ///
  /// ```swift
  /// content.printRouter(trigger: router.currentRoute)
  /// ```
  ///
  /// - Parameter trigger: A value to observe; the tree is re-printed whenever it changes.
  func printRouter<T: Equatable>(trigger: T) -> some View {
    modifier(PrintRouterOnChangeModifier(trigger: trigger))
  }
}
