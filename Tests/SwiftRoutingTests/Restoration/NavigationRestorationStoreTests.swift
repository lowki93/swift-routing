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

      let reasons = spy.receivedMessages.compactMap {
        if case let .error(.restoration(reason)) = $0 { reason } else { nil }
      }
      #expect(reasons.count == 1)
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
