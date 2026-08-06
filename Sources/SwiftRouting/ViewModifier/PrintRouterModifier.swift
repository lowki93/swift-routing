//
//  PrintRouterModifier.swift
//  swift-routing
//

import Combine
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

private struct PrintRouterOnTriggerModifier<T: Equatable>: ViewModifier {

  @Environment(\.router) private var router
  let trigger: T

  func body(content: Content) -> some View {
    content
      .onAppear { print(router.routerTreeDescription()) }
      .onChange(of: trigger) { print(router.routerTreeDescription()) }
  }
}

private struct PrintRouterOnEveryChangeModifier: ViewModifier {

  @Environment(\.router) private var router
  @State private var cancellable: AnyCancellable?

  func body(content: Content) -> some View {
    // Uses `configuration.events` rather than relying on SwiftUI's automatic @Published
    // tracking: that mechanism only re-invokes `body` for routers whose properties were
    // already read during a previous render, so a router created *after* this view last
    // rendered (e.g. one added deep in the tree by a `RoutingView` the user just navigated
    // into) would never be picked up -- especially fatal when this modifier sits at the
    // very top of the app, where the root router has no children yet on first render.
    // `events` is shared by reference across every router in the hierarchy (`Configuration`
    // is copied by value, but the underlying `PassthroughSubject` is a reference type), so
    // it fires for an event anywhere in the tree regardless of where this modifier sits.
    //
    // Subscribed manually into `@State` (once, in `onAppear`) rather than via `.onReceive`:
    // `.onReceive` tears down and recreates its subscription on every `body` re-evaluation
    // of the modified view, and printing the tree here reads `@Published` properties across
    // several routers, which itself triggers a re-render of this view. That re-render
    // recreates the `.onReceive` subscription, and any `events.send()` firing in that gap
    // is lost forever since `PassthroughSubject` doesn't replay/buffer -- observed as an
    // increasing mismatch between event sends and printed logs the busier the app got.
    // A `@State`-held subscription is set up exactly once and survives body re-evaluations.
    content
      .onAppear {
        print(router.routerTreeDescription())
        cancellable = router.configuration.events
          .sink { _ in print(router.routerTreeDescription()) }
      }
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
    modifier(PrintRouterOnTriggerModifier(trigger: trigger))
  }

  /// Prints the full router hierarchy to the console every time any router in the
  /// hierarchy logs an event (push, present, context, tab change, router creation...),
  /// no matter where in the tree it happens or where this modifier is placed --
  /// including at the very top of the app, before any child router exists yet.
  ///
  /// ```swift
  /// content.printRouterOnChange()
  /// ```
  ///
  /// > Note:
  /// > Doesn't require picking a specific value to watch, but is the noisiest of the three
  /// > variants since it reprints on every logged event anywhere in the hierarchy. Prefer
  /// > `printRouter()` or `printRouter(trigger:)` if that's too much.
  func printRouterOnChange() -> some View {
    modifier(PrintRouterOnEveryChangeModifier())
  }
}
