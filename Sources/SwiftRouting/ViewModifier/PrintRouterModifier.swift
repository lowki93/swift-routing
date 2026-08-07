//
//  PrintRouterModifier.swift
//  swift-routing
//

#if DEBUG
import Combine
import SwiftUI

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
        // `BaseRouter.log(_:)` defers `events.send()` to the next run loop tick (to avoid
        // reentering the shared subject from `deinit`), so a burst of several synchronous
        // log calls -- e.g. presenting a sheet logs both `.create` and `.navigation` --
        // schedules one deferred send per call. By the time any of them fire, every
        // underlying state change has already happened, so they'd otherwise print the same
        // resulting tree multiple times in a row. Deduping by content (rather than time)
        // collapses those into a single print with no added latency.
        cancellable = router.configuration.events
          .map { _ in router.routerTreeDescription() }
          .removeDuplicates()
          .sink { print($0) }
      }
  }
}

public extension View {

  /// Prints the full router hierarchy to the console when this view appears, and again
  /// every time `trigger` changes. Useful for watching navigation state evolve over time.
  ///
  /// Only available in `DEBUG` builds -- calls are compiled out entirely in release.
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
  /// Only available in `DEBUG` builds -- calls are compiled out entirely in release.
  ///
  /// ```swift
  /// content.printRouterOnChange()
  /// ```
  ///
  /// > Note:
  /// > Doesn't require picking a specific value to watch, but is the noisiest of the two
  /// > variants since it reprints on every logged event anywhere in the hierarchy. Prefer
  /// > `printRouter(trigger:)` if that's too much.
  func printRouterOnChange() -> some View {
    modifier(PrintRouterOnEveryChangeModifier())
  }
}
#endif
