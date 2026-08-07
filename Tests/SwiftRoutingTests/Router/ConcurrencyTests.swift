import Testing
@testable import SwiftRouting

/// Concurrency tests for `Router`/`BaseRouter`.
///
/// Most navigation methods (`push`, `back`, `add(context:)`, etc.) are `@MainActor`-isolated,
/// so concurrent calls to them are serialized by the actor and can't race by construction --
/// those tests below mainly guard against regressions (e.g. someone removing `@MainActor`).
///
/// `addChild`/`removeChild` are **not** actor-isolated (they run from `init`/`deinit`, which
/// aren't guaranteed to execute on the main actor), and the public `TabRouter.routers` reads
/// `children` without isolation either. Those are real potential data races, so those tests
/// deliberately spawn work off the main actor and are meant to be run under ThreadSanitizer:
///
///   swift test --sanitize=thread --filter ConcurrencyTests
@MainActor
struct ConcurrencyTests {

  @MainActor
  struct ConcurrentPush {
    @Test
    func multipleTasksPushConcurrently_return_allRoutesInPath() async {
      let router = Router(configuration: Configuration())

      await withTaskGroup(of: Void.self) { group in
        for index in 0..<50 {
          group.addTask { @MainActor in
            router.push(TestRoute.details(id: "\(index)"))
          }
        }
      }

      #expect(router.path.count == 50)
    }
  }

  @MainActor
  struct ConcurrentPathReadWrite {
    @Test
    func concurrentReadsAndWrites_return_consistentFinalCount() async {
      let router = Router(configuration: Configuration())

      await withTaskGroup(of: Void.self) { group in
        for index in 0..<50 {
          group.addTask { @MainActor in
            router.push(TestRoute.details(id: "\(index)"))
          }
          group.addTask { @MainActor in
            _ = router.path.count
            _ = router.currentRoute
          }
        }
      }

      #expect(router.path.count == 50)
    }
  }

  /// `addChild`/`removeChild` run from `init`/`deinit`, which are not `@MainActor`-isolated.
  /// These tests deliberately create/release child routers off the main actor to stress that
  /// path -- run under `swift test --sanitize=thread` to actually detect a race, since a plain
  /// run can pass by luck even if the underlying access is unsynchronized.
  struct ConcurrentChildAccess {
    @Test
    func concurrentChildCreationOffMainActor_return_allChildrenAttached() async {
      let parentRouter = Router(configuration: Configuration())
      let collector = ChildCollector()

      await withTaskGroup(of: Void.self) { group in
        for index in 0..<50 {
          group.addTask {
            // Deliberately not @MainActor: exercises addChild's actual (lack of) isolation.
            let child = Router(
              root: AnyRoute(TestRoute.details(id: "\(index)")),
              type: .presented("sheet-\(index)"),
              parent: parentRouter
            )
            await collector.add(child)
          }
        }
      }

      // Children must stay alive (retained by `collector`) until after this check --
      // otherwise they deinit and remove themselves before the count is read.
      let childCount = parentRouter.children.count
      #expect(childCount == 50)
      #expect(await collector.count == 50)
    }

    @Test
    func concurrentChildCreationAndRemoval_return_allChildrenRemoved() async {
      let parentRouter = Router(configuration: Configuration())

      await withTaskGroup(of: Void.self) { group in
        for index in 0..<50 {
          group.addTask {
            // Created and released within the task: exercises addChild (init) racing with
            // removeChild (deinit) from other concurrently-running tasks.
            let child = Router(
              root: AnyRoute(TestRoute.details(id: "\(index)")),
              type: .presented("sheet-\(index)"),
              parent: parentRouter
            )
            withExtendedLifetime(child) {}
          }
        }
      }

      // Every child was released inside its own task, so removeChild should have run for
      // all 50 -- if any add/remove pair raced and got lost, this count would be off.
      #expect(parentRouter.children.isEmpty)
    }

    @Test
    func tabRouterRoutersReadConcurrentlyWithChildMutation_return_allChildrenRemoved() async {
      let parentRouter = Router(configuration: Configuration())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: parentRouter)

      await withTaskGroup(of: Void.self) { group in
        for index in 0..<50 {
          group.addTask {
            // Writer: mutates `children` off the main actor via a non-isolated init.
            let child = Router(
              root: AnyRoute(TestRoute.details(id: "\(index)")),
              type: .stack("tab-child-\(index)"),
              parent: tabRouter
            )
            withExtendedLifetime(child) {}
          }
          group.addTask {
            // Reader: `TabRouter.routers` reads `children` without actor isolation.
            _ = tabRouter.routers
          }
        }
      }

      #expect(tabRouter.routers.isEmpty)
    }
  }
}
