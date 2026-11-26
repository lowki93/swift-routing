//
//  NavigationRestorationModifier.swift
//  swift-routing
//

import SwiftUI

/// Turns navigation restoration on for the scene it is applied in.
///
/// It owns the `@SceneStorage` blob, attaches the store to the root router on its first body pass
/// (before any child container is built), saves when the scene leaves `.active`, and erases the blob
/// when the store is cleared.
struct NavigationRestorationModifier: ViewModifier {

  @Environment(\.router) private var router
  @Environment(\.scenePhase) private var scenePhase
  @SceneStorage private var data: Data?
  @State private var holder = StoreHolder()

  init(key: String) {
    _data = SceneStorage(Self.storageKey(for: key))
  }

  /// The `SceneStorage` slot of `key`: another key reads another slot, so it starts fresh.
  static func storageKey(for key: String) -> String {
    "SwiftRouting.navigationRestoration.\(key)"
  }

  func body(content: Content) -> some View {
    // Attached while the body is evaluated, before `content` builds any router.
    let store = holder.store(loading: data, attachedTo: router)
    content
      .onChange(of: scenePhase) { _, phase in
        guard phase != .active else { return }
        save(store)
      }
      .onReceive(store.cleared) { data = nil }
  }

  private func save(_ store: NavigationRestorationStore) {
    // Not the store of this router (modifier applied below the app root): the root's modifier saves.
    guard router.restorationStore === store else { return }
    do {
      data = try store.save(from: router)
    } catch {
      router.log(.error(.restoration(.encodingFailed(container: NavigationRestorationStore.name(of: []), error: String(describing: error)))))
    }
  }

  /// Keeps the store across body passes, so it is built and attached once per router.
  private final class StoreHolder {
    private var store: NavigationRestorationStore?
    private weak var attachedRouter: Router?

    func store(loading data: Data?, attachedTo router: Router) -> NavigationRestorationStore {
      let store = store ?? NavigationRestorationStore(data: data)
      self.store = store
      if attachedRouter !== router {
        router.attachRestorationStore(store)
        attachedRouter = router
      }
      return store
    }
  }
}

public extension View {
  /// Restores the navigation of this scene after the system killed the app in the background.
  ///
  /// Apply it once per scene, at the app root, and place `.environment(\.router, ...)` after it: the modifier reads the root router from the environment.
  /// Without it nothing is saved, checked or logged.
  ///
  /// The navigation is saved when the scene leaves the foreground and restored the next time the
  /// scene is created, before the first frame, so the default state never flashes. Only containers
  /// whose routes are `Codable` are restored; the others start on their default state with a
  /// warning logged. Closing the app from the app switcher discards the saved state, and each
  /// window restores its own.
  ///
  /// Inject one root router per window with `.environment(\.router, ...)` placed after this modifier.
  /// Without it the environment falls back to a router shared by every window. Saved routes are
  /// written to disk in clear: never put a token or sensitive data in a route.
  ///
  /// ## Example
  ///
  /// ```swift
  /// @main
  /// struct DemoApp: App {
  ///   var body: some Scene {
  ///     WindowGroup {
  ///       RootView()
  ///     }
  ///   }
  /// }
  ///
  /// struct RootView: View {
  ///   @StateObject private var router = Router(configuration: .default)
  ///
  ///   var body: some View {
  ///     RoutingView(destination: HomeRoute.self, root: .home)
  ///       .navigationRestoration()
  ///       .environment(\.router, router)
  ///   }
  /// }
  /// ```
  ///
  /// - Parameter key: Names the saved state. Changing it starts fresh. Defaults to `"default"`.
  /// - Returns: A view that saves and restores its scene's navigation.
  func navigationRestoration(_ key: String = "default") -> some View {
    modifier(NavigationRestorationModifier(key: key))
  }
}
