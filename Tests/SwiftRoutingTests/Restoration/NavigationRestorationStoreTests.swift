import Combine
import Foundation
import Testing
@testable import SwiftRouting

@MainActor
struct NavigationRestorationStoreTests {

  /// A tree `app -> stack(name)` whose stack path is `[settings]`, saved as data.
  private func data(forStack name: String, path: [CodableTestRoute]) throws -> Data {
    let root = Router(configuration: Configuration())
    let store = NavigationRestorationStore()
    root.attachRestorationStore(store)
    let stack = Router(
      root: AnyRoute(wrapped: CodableTestRoute.home),
      type: .stack(name),
      parent: root,
      schema: RestorationSchema(route: CodableTestRoute.self)
    )
    stack.path = path.map { AnyRoute(wrapped: $0) }
    return try NavigationRestorationStore.encode(store.snapshot(from: root))
  }

  @MainActor
  struct Loading {
    @Test
    func givenNoData_whenStoreCreated_thenSnapshotIsEmptyAndNothingFailed() {
      let store = NavigationRestorationStore(data: nil)

      #expect(store.snapshot == .empty)
      #expect(store.takeLoadFailure() == nil)
    }

    @Test
    func givenCorruptData_whenStoreCreated_thenSnapshotDiscardedWithOneDecodingFailure() {
      let store = NavigationRestorationStore(data: Data("not json".utf8))

      #expect(store.snapshot == .empty)
      guard case .decodingFailed = store.takeLoadFailure() else {
        Issue.record("expected decodingFailed")
        return
      }
      #expect(store.takeLoadFailure() == nil)
    }

    @Test
    func givenUnknownVersion_whenStoreCreated_thenSnapshotDiscardedWithOneDecodingFailure() throws {
      let future = NavigationSnapshot(version: NavigationSnapshot.currentVersion + 1, root: RestorationNode())
      let store = NavigationRestorationStore(data: try NavigationRestorationStore.encode(future))

      #expect(store.snapshot == .empty)
      guard case .decodingFailed = store.takeLoadFailure() else {
        Issue.record("expected decodingFailed")
        return
      }
    }

    @Test
    func givenCorruptData_whenStoreAttached_thenOneDecodingFailedLoggedAndRoutersStartOnDefault() {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: Data("not json".utf8)))

      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )

      let errorCount = spy.receivedMessages.filter { if case .error(.restoration) = $0 { true } else { false } }.count
      #expect(errorCount == 1)
      assertLogMessagesContain(spy, expected: .error(.restoration(.decodingFailed(container: "snapshot", error: ""))))
      #expect(stack.path.isEmpty)
    }
  }

  @MainActor
  struct Independence {
    @Test
    func givenTwoStores_whenOneIsConsumed_thenTheOtherStillRestores() throws {
      let first = try NavigationRestorationStoreTests().data(forStack: "home", path: [.settings])
      let second = try NavigationRestorationStoreTests().data(forStack: "home", path: [.details(id: "2"), .settings])
      let schema = RestorationSchema(route: CodableTestRoute.self)
      let firstRoot = Router(configuration: Configuration())
      firstRoot.attachRestorationStore(NavigationRestorationStore(data: first))
      let secondRoot = Router(configuration: Configuration())
      secondRoot.attachRestorationStore(NavigationRestorationStore(data: second))

      let firstStack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: firstRoot, schema: schema)
      let secondStack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: secondRoot, schema: schema)

      #expect(firstStack.path.count == 1)
      #expect(secondStack.path.count == 2)
    }
  }

  @MainActor
  struct Encoding {
    @Test
    func givenSameTree_whenEncodedTwice_thenDataIsIdentical() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )
      stack.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "1"))]

      let first = try NavigationRestorationStore.encode(store.snapshot(from: root))
      let second = try NavigationRestorationStore.encode(store.snapshot(from: root))

      #expect(first == second)
    }

    @Test
    func givenSnapshot_whenEncodedAndDecoded_thenItIsEqual() throws {
      let data = try NavigationRestorationStoreTests().data(forStack: "home", path: [.settings])

      let store = NavigationRestorationStore(data: data)

      #expect(try NavigationRestorationStore.encode(store.snapshot) == data)
    }
  }

  @MainActor
  struct Attachment {
    private let schema = RestorationSchema(route: CodableTestRoute.self)

    @Test
    func givenStoreAttachedToRoot_whenDescendantAsks_thenStoreIsReachable() {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      let nested = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("nested"), parent: stack, schema: schema)

      #expect(root.restorationStore === store)
      #expect(stack.restorationStore === store)
      #expect(nested.restorationStore === store)
    }

    @Test
    func givenRootWithoutStore_whenDescendantAsks_thenNoStore() {
      let root = Router(configuration: Configuration())
      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)

      #expect(root.restorationStore == nil)
      #expect(stack.restorationStore == nil)
    }
  }

  @MainActor
  struct Saving {
    private let schema = RestorationSchema(route: CodableTestRoute.self)

    private func makeTree(path: [CodableTestRoute]) -> (root: Router, store: NavigationRestorationStore, stack: Router) {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      stack.path = path.map { AnyRoute(wrapped: $0) }
      return (root, store, stack)
    }

    @Test
    func givenRouteRemovedAfterFirstSave_whenSavedAgain_thenOnlyWhatExistsIsStored() throws {
      let (root, store, stack) = makeTree(path: [.settings, .details(id: "1")])
      _ = try store.save(from: root)
      stack.path.removeLast()

      let data = try store.save(from: root)

      let restoredRoot = Router(configuration: Configuration())
      restoredRoot.attachRestorationStore(NavigationRestorationStore(data: data))
      let restored = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: restoredRoot, schema: schema)
      #expect(restored.path.map { $0.wrapped as? CodableTestRoute } == [.settings])
    }
  }

  @MainActor
  struct Clearing {
    private let schema = RestorationSchema(route: CodableTestRoute.self)

    @Test
    func givenSavedState_whenCleared_thenSnapshotEmptyAndSignalFiredOnce() throws {
      let data = try NavigationRestorationStoreTests().data(forStack: "home", path: [.settings])
      let store = NavigationRestorationStore(data: data)
      var signals = 0
      let subscription = store.cleared.sink { signals += 1 }

      store.clear()

      #expect(store.snapshot == .empty)
      #expect(signals == 1)
      subscription.cancel()
    }

    @Test
    func givenStoreAttached_whenRouterClears_thenRouterBuiltAfterwardsStartsOnDefault() throws {
      let data = try NavigationRestorationStoreTests().data(forStack: "home", path: [.settings])
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))

      root.clearNavigationRestoration()

      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      #expect(stack.path.isEmpty)
    }

    @Test
    func givenStoreAttached_whenClearedThroughRouterModel_thenRouterBuiltAfterwardsStartsOnDefault() throws {
      let data = try NavigationRestorationStoreTests().data(forStack: "home", path: [.settings])
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let model: any RouterModel = root

      model.clearNavigationRestoration()

      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      #expect(stack.path.isEmpty)
    }

    @Test
    func givenNoStore_whenRouterClears_thenNothingHappens() {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      let before = spy.receivedMessages.count

      root.clearNavigationRestoration()

      #expect(spy.receivedMessages.count == before)
    }

    @Test
    func givenCleared_whenSavedAfterwards_thenSaveIsNotBlocked() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      root.clearNavigationRestoration()
      stack.path = [AnyRoute(wrapped: CodableTestRoute.settings)]

      let data = try store.save(from: root)

      #expect(NavigationRestorationStore(data: data).snapshot != .empty)
    }
  }

  @MainActor
  struct Keys {
    private let schema = RestorationSchema(route: CodableTestRoute.self)

    @Test
    func givenDifferentKeys_whenStorageKeyBuilt_thenSlotsDiffer() {
      #expect(NavigationRestorationModifier.storageKey(for: "a") != NavigationRestorationModifier.storageKey(for: "b"))
      #expect(NavigationRestorationModifier.storageKey(for: "default") == "SwiftRouting.navigationRestoration.default")
    }

    @Test
    func givenEmptySlot_whenRoutersBuilt_thenStartOnDefault() {
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: nil))

      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)

      #expect(stack.path.isEmpty)
    }
  }

  @MainActor
  struct Codec {
    @Test
    func codableType_isCodable_returnTrue() {
      #expect(RestorationCodec.isCodable(CodableTestRoute.self))
    }

    @Test
    func nonCodableType_isCodable_returnFalse() {
      #expect(!RestorationCodec.isCodable(TestRoute.self))
    }

    @Test
    func neverType_isCodable_returnTrue() {
      #expect(RestorationCodec.isCodable(Never.self))
    }
  }
}
