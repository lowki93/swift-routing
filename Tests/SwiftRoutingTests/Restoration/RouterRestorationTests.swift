import Combine
import Foundation
import Testing
@testable import SwiftRouting

/// Records what the store's failure hook receives, instead of crashing the test process.
final class FailureRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var _messages: [String] = []

  var messages: [String] { lock.withLock { _messages } }

  func record(_ message: String) {
    lock.withLock { _messages.append(message) }
  }
}

/// Errors received by `spy`, in order.
@MainActor
private func restorationReasons(_ spy: LoggerSpy) -> [RestorationReason] {
  spy.receivedMessages.compactMap {
    if case let .error(.restoration(reason)) = $0 { reason } else { nil }
  }
}

/// Builds `app -> stack(home)` with a root and a 2-route path (the second one without stack),
/// and returns the data a save would have written.
@MainActor
private func savedRestorationData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let stack = Router(
    root: AnyRoute(wrapped: CodableTestRoute.settings),
    type: .stack("home"),
    parent: root,
    schema: RestorationSchema(route: CodableTestRoute.self)
  )
  stack.path = [
    AnyRoute(wrapped: CodableTestRoute.details(id: "42")),
    AnyRoute(wrapped: CodableTestRoute.home, inStack: false),
  ]
  return try NavigationRestorationStore.encode(store.snapshot(from: root))
}

@MainActor
struct RouterRestorationTests {
  @MainActor
  struct WithoutStore {
    @Test
    func givenNoStoreAttached_whenRouterBuiltWithSchema_thenBehavesAsToday() throws {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))

      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )

      #expect((stack.root.wrapped as? CodableTestRoute) == .home)
      #expect(stack.path.isEmpty)
      #expect(spy.receivedMessages.allSatisfy { if case .error = $0 { false } else { true } })
    }

    @Test
    func givenNoStoreAttached_whenRouterBuiltWithNonCodableSchema_thenNoLogAndNoCrash() {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))

      _ = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: TestRoute.self)
      )

      #expect(spy.receivedMessages.allSatisfy { if case .error = $0 { false } else { true } })
    }
  }

  @MainActor
  struct RoundTrip {
    @Test
    func givenSavedTree_whenRouterRebuilt_thenRootPathAndInStackAreRestored() throws {
      let data = try savedRestorationData()

      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )

      #expect((stack.root.wrapped as? CodableTestRoute) == .settings)
      #expect(stack.path.map { $0.wrapped as? CodableTestRoute } == [.details(id: "42"), .home])
      #expect(stack.path.map(\.inStack) == [true, false])
    }

    @Test
    func givenSavedTree_whenRouterRebuilt_thenSeedingFiresNoNavigationLogPresentOrEvent() async throws {
      let data = try savedRestorationData()
      let spy = LoggerSpy(storesConfiguration: false)
      let configuration = Configuration(loggerSpy: spy)
      let root = Router(configuration: configuration)
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      // Lets the deferred `.create` signal of `root` go out before subscribing.
      await Task.yield()
      var presentCount = 0
      var eventCount = 0
      let presentCancellable = root.present.sink { _ in presentCount += 1 }
      let eventsCancellable = configuration.events.sink { eventCount += 1 }

      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )
      await Task.yield()

      #expect(stack.path.count == 2)
      #expect(spy.receivedMessages.count == 2)
      let createCount = spy.receivedMessages.filter { if case .create = $0 { true } else { false } }.count
      #expect(createCount == 2)
      #expect(presentCount == 0)
      // The only signal is the one of the stack's own `.create`.
      #expect(eventCount == 1)
      withExtendedLifetime((presentCancellable, eventsCancellable)) {}
    }

    @Test
    func givenSavedTree_whenSecondRouterBuiltAtSamePath_thenItStartsOnDefaultState() throws {
      let data = try savedRestorationData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let schema = RestorationSchema(route: CodableTestRoute.self)
      let first = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)

      let second = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)

      #expect(first.path.count == 2)
      #expect((second.root.wrapped as? CodableTestRoute) == .home)
      #expect(second.path.isEmpty)
    }

    @Test
    func givenOrphanNode_whenOtherRouterBuilt_thenNoLogAndDefaultState() throws {
      let data = try savedRestorationData()
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: data))

      let other = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("renamedInCode"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )

      #expect(other.path.isEmpty)
      #expect(spy.receivedMessages.allSatisfy { if case .error = $0 { false } else { true } })
    }
  }

  @MainActor
  struct NotCodable {
    @Test
    func givenStoreAttached_whenNonCodableRouterBuiltTwice_thenDefaultStateAndLoggedOnce() {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore())
      let schema = RestorationSchema(route: TestRoute.self)

      let first = Router(root: AnyRoute(wrapped: TestRoute.home), type: .stack("home"), parent: root, schema: schema)
      _ = Router(root: AnyRoute(wrapped: TestRoute.home), type: .stack("home"), parent: root, schema: schema)

      let reasons = restorationReasons(spy)
      #expect(first.path.isEmpty)
      #expect(reasons.count == 1)
      guard case let .notCodable(container, type) = reasons.first else {
        Issue.record("expected notCodable, got \(reasons)")
        return
      }
      #expect(container == "app/stack(home)")
      #expect(type.contains("TestRoute"))
    }

    @Test
    func givenCrashFlagOff_whenNonCodableRouterBuilt_thenFailureHookNotCalled() {
      let recorder = FailureRecorder()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(failureHook: recorder.record))

      _ = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: TestRoute.self)
      )

      #expect(recorder.messages.isEmpty)
    }

    @Test
    func givenCrashFlagOn_whenNonCodableRouterBuilt_thenFailureHookCalledWithReason() {
      let recorder = FailureRecorder()
      let root = Router(configuration: Configuration(logger: nil, shouldCrashOnRouteNotFound: true))
      root.attachRestorationStore(NavigationRestorationStore(failureHook: recorder.record))

      _ = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: TestRoute.self)
      )

      #expect(recorder.messages.count == 1)
      #expect(recorder.messages.first?.contains("TestRoute") == true)
    }
  }

  @MainActor
  struct DecodingFailure {
    private func renamedData() throws -> Data {
      // Saved by the old app version: `CodableTestRoute`, now decoded as `RenamedCodableTestRoute`.
      try savedRestorationData()
    }

    @Test
    func givenUndecodablePayload_whenRouterBuilt_thenDefaultStateAndLoggedOnce() throws {
      let data = try renamedData()
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let schema = RestorationSchema(route: RenamedCodableTestRoute.self)

      let stack = Router(root: AnyRoute(wrapped: RenamedCodableTestRoute.landing), type: .stack("home"), parent: root, schema: schema)
      _ = Router(root: AnyRoute(wrapped: RenamedCodableTestRoute.landing), type: .stack("home"), parent: root, schema: schema)

      let reasons = restorationReasons(spy)
      #expect((stack.root.wrapped as? RenamedCodableTestRoute) == .landing)
      #expect(stack.path.isEmpty)
      #expect(reasons.count == 1)
      guard case let .decodingFailed(container, _) = reasons.first else {
        Issue.record("expected decodingFailed, got \(reasons)")
        return
      }
      #expect(container == "app/stack(home)")
    }

    @Test
    func givenUndecodablePayloadAndCrashFlagOn_whenRouterBuilt_thenFailureHookNotCalled() throws {
      let data = try renamedData()
      let recorder = FailureRecorder()
      let root = Router(configuration: Configuration(logger: nil, shouldCrashOnRouteNotFound: true))
      root.attachRestorationStore(NavigationRestorationStore(data: data, failureHook: recorder.record))

      _ = Router(
        root: AnyRoute(wrapped: RenamedCodableTestRoute.landing),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: RenamedCodableTestRoute.self)
      )

      #expect(recorder.messages.isEmpty)
    }

    @Test
    func givenUndecodablePayload_whenChildOfFailedRouterBuilt_thenSubtreeStartsOnDefaultState() throws {
      // Child saved under the same path, then the parent fails to decode.
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let schema = RestorationSchema(route: CodableTestRoute.self)
      let stack = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      stack.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      let child = Router(root: AnyRoute(wrapped: CodableTestRoute.details(id: "1")), type: .stack("child"), parent: stack, schema: schema)
      child.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      let data = try NavigationRestorationStore.encode(store.snapshot(from: root))

      let newRoot = Router(configuration: Configuration())
      newRoot.attachRestorationStore(NavigationRestorationStore(data: data))
      let newStack = Router(
        root: AnyRoute(wrapped: RenamedCodableTestRoute.landing),
        type: .stack("home"),
        parent: newRoot,
        schema: RestorationSchema(route: RenamedCodableTestRoute.self)
      )
      let newChild = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("child"), parent: newStack, schema: schema)

      #expect(newStack.path.isEmpty)
      #expect((newChild.root.wrapped as? CodableTestRoute) == .home)
      #expect(newChild.path.isEmpty)
    }

    @Test
    func givenOtherRouterDecodes_whenSiblingFails_thenOtherRouterIsStillRestored() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let schema = RestorationSchema(route: CodableTestRoute.self)
      let first = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("a"), parent: root, schema: schema)
      first.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      let second = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("b"), parent: root, schema: schema)
      second.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      let data = try NavigationRestorationStore.encode(store.snapshot(from: root))

      let newRoot = Router(configuration: Configuration())
      newRoot.attachRestorationStore(NavigationRestorationStore(data: data))
      let failed = Router(
        root: AnyRoute(wrapped: RenamedCodableTestRoute.landing),
        type: .stack("a"),
        parent: newRoot,
        schema: RestorationSchema(route: RenamedCodableTestRoute.self)
      )
      let restored = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("b"), parent: newRoot, schema: schema)

      #expect(failed.path.isEmpty)
      #expect(restored.path.map { $0.wrapped as? CodableTestRoute } == [.settings])
    }
  }

  @MainActor
  struct Snapshot {
    @Test
    func givenSiblingsSharingAKey_whenSnapshotTaken_thenNeitherSavedAndDuplicateKeyLoggedOnce() {
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let schema = RestorationSchema(route: CodableTestRoute.self)
      let first = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      let second = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("home"), parent: root, schema: schema)
      first.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      second.path = [AnyRoute(wrapped: CodableTestRoute.settings)]

      _ = store.snapshot(from: root)
      let snapshot = store.snapshot(from: root)

      let reasons = restorationReasons(spy)
      #expect(snapshot.root.children.isEmpty)
      #expect(reasons == [.duplicateKey(container: "app/stack(home)")])
    }

    @Test
    func givenNonCodableRouter_whenSnapshotTaken_thenItIsNotSaved() {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: TestRoute.self)
      )
      stack.path = [AnyRoute(wrapped: TestRoute.settings)]

      let snapshot = store.snapshot(from: root)

      #expect(snapshot.root.children.isEmpty)
    }

    @Test
    func givenContextAndTransientState_whenSnapshotEncoded_thenTheyNeverAppearInTheData() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("home"),
        parent: root,
        schema: RestorationSchema(route: CodableTestRoute.self)
      )
      stack.add(context: StringContext.self) { _ in }
      stack.present(CodableTestRoute.settings)
      stack.present(CodableTestRoute.details(id: "later"))

      let data = try NavigationRestorationStore.encode(store.snapshot(from: root))

      let keys = allKeys(in: try JSONSerialization.jsonObject(with: data))
      #expect(!keys.contains { $0.localizedCaseInsensitiveContains("context") })
      #expect(!keys.contains { $0.localizedCaseInsensitiveContains("pending") })
      #expect(!keys.contains { $0.localizedCaseInsensitiveContains("dismissing") })
      #expect(!keys.contains { $0.localizedCaseInsensitiveContains("compact") })
    }
  }
}

private func allKeys(in object: Any) -> Set<String> {
  if let dictionary = object as? [String: Any] {
    return dictionary.reduce(into: Set(dictionary.keys)) { $0.formUnion(allKeys(in: $1.value)) }
  }
  if let array = object as? [Any] {
    return array.reduce(into: []) { $0.formUnion(allKeys(in: $1)) }
  }
  return []
}
