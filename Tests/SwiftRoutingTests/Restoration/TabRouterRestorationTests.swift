import Combine
import Foundation
import Testing
@testable import SwiftRouting

@MainActor private let schema = RestorationSchema(route: CodableTestRoute.self)

/// The path a tab's stack is saved with.
private let tabPath = CodableTestRoute.details(id: "42")

/// A `tab(x)` stack under `parent`, built the way `RoutingView` builds it.
@MainActor
private func stack(_ tab: some TabRoute, in parent: BaseRouter) -> Router {
  Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: tab.type, parent: parent, schema: schema)
}

@MainActor
private func restorationErrorCount(_ spy: LoggerSpy) -> Int {
  spy.receivedMessages.filter {
    if case .error(.restoration) = $0 { true } else { false }
  }.count
}

@MainActor
private func routes(of router: Router) -> [CodableTestRoute?] {
  router.path.map { $0.wrapped as? CodableTestRoute }
}

/// Builds `app -> tabRouter(CodableTestTabRoute)` on tab B with a stack in each of the tabs A, B and C
/// (each with the path `[details(42)]`), and returns the data a save writes.
@MainActor
private func savedTabsData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: root)
  tabRouter.change(tab: CodableTestTabRoute.b)
  let stacks = [CodableTestTabRoute.a, .b, .c].map { stack($0, in: tabRouter) }
  stacks.forEach { $0.path = [AnyRoute(wrapped: tabPath)] }
  let data = try store.save(from: root)
  withExtendedLifetime(stacks) {}
  return data
}

/// A new launch of the app: a root router with a store loaded from `data`, and a logger.
@MainActor
struct TabLaunch {
  let spy = LoggerSpy(storesConfiguration: false)
  let root: Router
  let store: NavigationRestorationStore

  init(data: Data?, shouldCrashOnRouteNotFound: Bool = false, failureHook: @escaping @Sendable (String) -> Void = { _ in }) {
    let spy = spy
    root = Router(configuration: Configuration(logger: { spy.receive($0) }, shouldCrashOnRouteNotFound: shouldCrashOnRouteNotFound))
    store = NavigationRestorationStore(data: data, failureHook: failureHook)
    root.attachRestorationStore(store)
  }

  func snapshot() -> NavigationSnapshot {
    store.snapshot(from: root)
  }
}

private extension NavigationSnapshot {
  /// The node of the tab router, `app/tabRouter(CodableTestTabRoute)`.
  var tabRouterNode: RestorationNode? {
    root.children["tabRouter(CodableTestTabRoute)"]
  }
}

@MainActor
struct TabRouterRestorationTests {

  @MainActor
  struct Seeding {
    let data: Data
    let launch: TabLaunch

    init() throws {
      data = try savedTabsData()
      launch = TabLaunch(data: data)
    }

    @Test
    func givenSavedTabB_whenTabRouterBuilt_thenTabAndRestoredTabAreB() {
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      #expect(tabRouter.tab.wrapped as? CodableTestTabRoute == .b)
      #expect(tabRouter.restoredTab?.wrapped as? CodableTestTabRoute == .b)
    }

    @Test
    func givenSavedTabB_whenTabRouterBuilt_thenNoLogOtherThanCreate() async {
      await Task.yield()
      launch.spy.clearReceivedMessages()

      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      await Task.yield()

      let others = launch.spy.receivedMessages.filter { if case .create = $0 { false } else { true } }
      #expect(others.isEmpty)
      withExtendedLifetime(tabRouter) {}
    }

    @Test
    func givenSavedTabB_whenTabRouterBuilt_thenNothingIsEmitted() async {
      await Task.yield()
      var presentCount = 0
      var reselectCount = 0
      var tabChangeCount = 0
      var cancellables: Set<AnyCancellable> = []
      launch.root.present.sink { _ in presentCount += 1 }.store(in: &cancellables)

      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      tabRouter.tabReselected.sink { _ in reselectCount += 1 }.store(in: &cancellables)
      tabRouter.$tab.dropFirst().sink { _ in tabChangeCount += 1 }.store(in: &cancellables)
      await Task.yield()

      #expect(presentCount == 0)
      #expect(reselectCount == 0)
      #expect(tabChangeCount == 0)
      #expect(tabRouter.restoredTab != nil)
    }

    @Test
    func givenSavedTabs_whenTabAndStacksRebuilt_thenEachStackKeepsItsOwnPath() {
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      let stackA = stack(CodableTestTabRoute.a, in: tabRouter)
      let stackB = stack(CodableTestTabRoute.b, in: tabRouter)

      #expect(routes(of: stackA) == [tabPath])
      #expect(routes(of: stackB) == [tabPath])
    }

    @Test
    func givenSavedTabB_whenTabRouterBuiltTwice_thenTheSecondOneStartsOnItsDefaultTab() {
      _ = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      let second = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      #expect(second.tab.wrapped as? CodableTestTabRoute == .a)
      #expect(second.restoredTab == nil)
    }

    @Test
    func givenNoStore_whenTabRouterBuilt_thenItStartsOnTheGivenTab() {
      let root = Router(configuration: Configuration())

      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: root)

      #expect(tabRouter.tab.wrapped as? CodableTestTabRoute == .a)
      #expect(tabRouter.restoredTab == nil)
    }
  }

  @MainActor
  struct Saving {
    @Test
    func givenTabsA_B_C_whenSaved_thenEachStackIsSavedUnderItsOwnSegment() throws {
      let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedTabsData())

      #expect(Set(snapshot.tabRouterNode?.children.keys.map { $0 } ?? []) == ["tab(a)", "tab(b)", "tab(c)"])
    }

    @Test
    func givenTabB_whenSaved_thenTheSelectedTabIsSavedOnTheTabRouterNode() throws {
      let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedTabsData())

      let expectedTab = try RestorationCodec.encode(AnyRoute(wrapped: CodableTestTabRoute.b))
      #expect(snapshot.tabRouterNode?.state?.tab == expectedTab)
    }
  }

  @MainActor
  struct Merge {
    let data: Data
    let launch: TabLaunch
    let tabRouter: TabRouter

    init() throws {
      data = try savedTabsData()
      launch = TabLaunch(data: data)
      tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
    }

    @Test
    func givenTabCNeverBuilt_whenSaved_thenItsStoredStackIsKept() {
      let stacks = [CodableTestTabRoute.a, .b].map { stack($0, in: tabRouter) }

      let node = launch.snapshot().tabRouterNode?.children["tab(c)"]

      #expect(node?.state?.path.count == 1)
      withExtendedLifetime(stacks) {}
    }

    @Test
    func givenTabCNeverBuilt_whenSaved_thenSelectedTabAndLiveStacksAreSaved() {
      let stacks = [CodableTestTabRoute.a, .b].map { stack($0, in: tabRouter) }

      let node = launch.snapshot().tabRouterNode

      #expect(node?.state?.tab != nil)
      #expect(Set(node?.children.keys.map { $0 } ?? []) == ["tab(a)", "tab(b)", "tab(c)"])
      withExtendedLifetime(stacks) {}
    }

    @Test
    func givenLiveStackWithNewPath_whenSaved_thenTheLiveStateWinsOverTheStoredOne() throws {
      let stackA = stack(CodableTestTabRoute.a, in: tabRouter)
      stackA.path = []

      let node = launch.snapshot().tabRouterNode?.children["tab(a)"]

      #expect(node?.state?.path.isEmpty == true)
      withExtendedLifetime(stackA) {}
    }

    @Test
    func givenTabCBuiltThenReleased_whenSaved_thenItIsNotResurrected() {
      var stackC: Router? = stack(CodableTestTabRoute.c, in: tabRouter)
      stackC = nil

      let node = launch.snapshot().tabRouterNode

      #expect(node?.children["tab(c)"] == nil)
      withExtendedLifetime(stackC) {}
    }

    @Test
    func givenTabCBuiltAndStillLive_whenSaved_thenItIsSavedFromTheLiveRouter() {
      let stackC = stack(CodableTestTabRoute.c, in: tabRouter)
      stackC.path = []

      let node = launch.snapshot().tabRouterNode?.children["tab(c)"]

      #expect(node?.state?.path.isEmpty == true)
      withExtendedLifetime(stackC) {}
    }

    @Test
    func givenSavedMergeResult_whenReloadedAndSavedAgain_thenTabCSurvives() throws {
      let stacks = [CodableTestTabRoute.a, .b].map { stack($0, in: tabRouter) }
      let saved = try launch.store.save(from: launch.root)
      let next = TabLaunch(data: saved)
      let nextTabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: next.root)

      let node = next.snapshot().tabRouterNode?.children["tab(c)"]

      #expect(node?.state?.path.count == 1)
      withExtendedLifetime((stacks, nextTabRouter)) {}
    }
  }

  @MainActor
  struct StaleNodes {
    private let sheetRoute = CodableTestRoute.settings

    /// A saved tree with a sheet open over the stack of tab A, with its own path.
    private func dataWithSheet() throws -> Data {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = Router(
        root: AnyRoute(wrapped: sheetRoute),
        type: .presented(sheetRoute.name),
        parent: host,
        modalSlot: .sheet,
        schema: schema
      )
      sheet.path = [AnyRoute(wrapped: tabPath)]
      let data = try store.save(from: root)
      withExtendedLifetime(sheet) {}
      return data
    }

    private func sheetNode(in snapshot: NavigationSnapshot) -> RestorationNode? {
      snapshot.tabRouterNode?.children["tab(a)"]?.children["presented(settings)#sheet"]
    }

    @Test
    func givenHostStillShowingTheRestoredSheet_whenSavedBeforeItsRouterIsBuilt_thenTheSheetNodeIsKept() throws {
      let launch = TabLaunch(data: try dataWithSheet())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)

      let node = sheetNode(in: launch.snapshot())

      #expect(node?.state?.path.count == 1)
      withExtendedLifetime(host) {}
    }

    @Test
    func givenHostThatNoLongerPresentsTheSheet_whenSaved_thenTheStoredSheetNodeIsDropped() throws {
      let launch = TabLaunch(data: try dataWithSheet())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)
      host.sheet = nil

      let node = sheetNode(in: launch.snapshot())

      #expect(node == nil)
      withExtendedLifetime(host) {}
    }

    @Test
    func givenHostPresentingAnotherSheet_whenSaved_thenTheStoredSheetNodeIsDropped() throws {
      let launch = TabLaunch(data: try dataWithSheet())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)
      host.sheet = AnyRoute(wrapped: CodableTestRoute.settings, inStack: false)

      let node = sheetNode(in: launch.snapshot())

      #expect(node == nil)
      withExtendedLifetime(host) {}
    }

    @Test
    func givenRestoredSheetWhoseRouterWasConsumedThenReleased_whenSaved_thenTheNodeIsNotResurrected() throws {
      let launch = TabLaunch(data: try dataWithSheet())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)
      var sheet: Router? = Router(
        root: AnyRoute(wrapped: sheetRoute),
        type: .presented(sheetRoute.name),
        parent: host,
        modalSlot: .sheet,
        schema: schema
      )
      sheet = nil

      let node = sheetNode(in: launch.snapshot())

      #expect(node == nil)
      withExtendedLifetime((host, sheet)) {}
    }
  }

  @MainActor
  struct FailedPaths {
    /// The saved tree with a nested stack in tab A, whose own root no longer decodes.
    private func dataWithUndecodableTabStack() throws -> Data {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)
      let nested = Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack("inner"), parent: host, schema: schema)
      nested.path = [AnyRoute(wrapped: tabPath)]
      var snapshot = store.snapshot(from: root)
      snapshot.root.children["tabRouter(CodableTestTabRoute)"]?.children["tab(a)"]?.state?.root?.payload = Data("{\"removed\":{}}".utf8)
      withExtendedLifetime((host, nested)) {}
      return try NavigationRestorationStore.encode(snapshot)
    }

    @Test
    func givenStackThatFailedToDecode_whenSaved_thenItsStoredSubtreeIsDropped() throws {
      let launch = TabLaunch(data: try dataWithUndecodableTabStack())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      let host = stack(CodableTestTabRoute.a, in: tabRouter)

      let node = launch.snapshot().tabRouterNode?.children["tab(a)"]

      #expect(node?.children["stack(inner)"] == nil)
      #expect(restorationErrorCount(launch.spy) == 1)
      withExtendedLifetime(host) {}
    }
  }

  @MainActor
  struct NotCodableTab {
    /// A tab type that is not `Codable` (`TestTabRoute`) with Codable stacks under it.
    private func data() throws -> Data {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: root)
      let stackSettings = stack(TestTabRoute.settings, in: tabRouter)
      stackSettings.path = [AnyRoute(wrapped: tabPath)]
      let data = try store.save(from: root)
      withExtendedLifetime(stackSettings) {}
      return data
    }

    @Test
    func givenNonCodableTabType_whenSaved_thenNoTabIsWrittenButTheStacksAre() throws {
      let launch = TabLaunch(data: try data())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: launch.root)
      let stackSettings = stack(TestTabRoute.settings, in: tabRouter)

      let node = launch.snapshot().root.children["tabRouter(TestTabRoute)"]

      #expect(node?.state == nil)
      #expect(node?.children["tab(settings)"]?.state?.path.count == 1)
      withExtendedLifetime(stackSettings) {}
    }

    @Test
    func givenNonCodableTabType_whenTabRouterBuiltTwice_thenDefaultTabAndNotCodableLoggedOnce() throws {
      let launch = TabLaunch(data: try data())

      let first = TabRouter(tab: TestTabRoute.home, parent: launch.root)
      _ = TabRouter(tab: TestTabRoute.home, parent: launch.root)

      #expect(first.tab.wrapped as? TestTabRoute == .home)
      #expect(restorationErrorCount(launch.spy) == 1)
      assertLogMessagesContain(
        launch.spy,
        expected: .error(.restoration(.notCodable(container: "app/tabRouter(TestTabRoute)", type: "TestTabRoute")))
      )
    }

    @Test
    func givenNonCodableTabTypeAndCrashFlagOn_whenTabRouterBuilt_thenTheFailureHookIsCalledOnce() throws {
      let recorder = FailureRecorder()
      let launch = TabLaunch(data: try data(), shouldCrashOnRouteNotFound: true, failureHook: { recorder.record($0) })

      _ = TabRouter(tab: TestTabRoute.home, parent: launch.root)

      #expect(recorder.messages.count == 1)
      #expect(recorder.messages.first?.contains("app/tabRouter(TestTabRoute)") == true)
    }

    @Test
    func givenNonCodableTabTypeAndCrashFlagOff_whenTabRouterBuilt_thenTheFailureHookIsNotCalled() throws {
      let recorder = FailureRecorder()
      let launch = TabLaunch(data: try data(), failureHook: { recorder.record($0) })

      _ = TabRouter(tab: TestTabRoute.home, parent: launch.root)

      #expect(recorder.messages.isEmpty)
    }

    @Test
    func givenNonCodableTabType_whenStacksRebuilt_thenTheirPathsAreRestored() throws {
      let launch = TabLaunch(data: try data())
      let tabRouter = TabRouter(tab: TestTabRoute.home, parent: launch.root)

      let stackSettings = stack(TestTabRoute.settings, in: tabRouter)

      #expect(routes(of: stackSettings) == [tabPath])
    }
  }

  @MainActor
  struct RemovedTabCase {
    let launch: TabLaunch

    init() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedTabsData())
      snapshot.root.children["tabRouter(CodableTestTabRoute)"]?.state?.tab?.payload = Data("{\"removed\":{}}".utf8)
      launch = TabLaunch(data: try NavigationRestorationStore.encode(snapshot))
    }

    @Test
    func givenRemovedTabCase_whenTabRouterBuilt_thenItStartsOnTheDefaultTab() {
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      #expect(tabRouter.tab.wrapped as? CodableTestTabRoute == .a)
      #expect(tabRouter.restoredTab == nil)
    }

    @Test
    func givenRemovedTabCase_whenTabRouterBuiltTwice_thenDecodingFailedLoggedOnce() {
      _ = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)
      _ = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      #expect(restorationErrorCount(launch.spy) == 1)
      assertLogMessagesContain(
        launch.spy,
        expected: .error(.restoration(.decodingFailed(container: "app/tabRouter(CodableTestTabRoute)", error: "")))
      )
    }

    @Test
    func givenRemovedTabCaseAndCrashFlagOn_whenTabRouterBuilt_thenItDoesNotCrash() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedTabsData())
      snapshot.root.children["tabRouter(CodableTestTabRoute)"]?.state?.tab?.payload = Data("{\"removed\":{}}".utf8)
      let crashing = TabLaunch(data: try NavigationRestorationStore.encode(snapshot), shouldCrashOnRouteNotFound: true)

      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: crashing.root)

      #expect(tabRouter.restoredTab == nil)
    }
  }

  @MainActor
  struct RenamedTabType {
    @Test
    func givenSavedNodeOfAnOldTabType_whenRenamedTabRouterBuilt_thenTheOldNodeIsIgnored() throws {
      let launch = TabLaunch(data: try savedTabsData())

      let tabRouter = TabRouter(tab: RenamedCodableTestTabRoute.main, parent: launch.root)

      #expect(tabRouter.tab.wrapped as? RenamedCodableTestTabRoute == .main)
      #expect(tabRouter.restoredTab == nil)
      #expect(restorationErrorCount(launch.spy) == 0)
    }
  }

  @MainActor
  struct OrphanNodes {
    @Test
    func givenSavedNodeOfAnOldTabType_whenSavedWithTheRenamedTabRouter_thenTheOldSubtreeIsDropped() throws {
      let launch = TabLaunch(data: try savedTabsData())
      let tabRouter = TabRouter(tab: RenamedCodableTestTabRoute.main, parent: launch.root)

      let snapshot = launch.snapshot()

      #expect(snapshot.root.children["tabRouter(CodableTestTabRoute)"] == nil)
      #expect(snapshot.root.children["tabRouter(RenamedCodableTestTabRoute)"] != nil)
      withExtendedLifetime(tabRouter) {}
    }

    @Test
    func givenSavedNodeOfAnOldTabType_whenSavedWithoutAnyTabRouter_thenTheOldSubtreeIsKept() throws {
      let launch = TabLaunch(data: try savedTabsData())

      #expect(launch.snapshot().root.children["tabRouter(CodableTestTabRoute)"] != nil)
    }
  }

  @MainActor
  struct NestedContainers {
    private let home = AnyRoute(wrapped: CodableTestRoute.home)

    /// Session 1: `stack(home)` on `[details(42)]` with a nested `stack(inner)` on `[settings]`,
    /// built by the pushed screen.
    private func savedNestedData() throws -> Data {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let host = Router(root: home, type: .stack("home"), parent: root, schema: schema)
      host.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "42"))]
      let inner = Router(root: home, type: .stack("inner"), parent: host, schema: schema)
      inner.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
      let data = try store.save(from: root)
      withExtendedLifetime((host, inner)) {}
      return data
    }

    @Test
    func givenHostPoppedBeforeTheNestedStackIsBuilt_whenSavedAndReloaded_thenAFreshPushStartsTheNestedStackEmpty() throws {
      let second = TabLaunch(data: try savedNestedData())
      let host2 = Router(root: home, type: .stack("home"), parent: second.root, schema: schema)
      host2.path = []
      let data2 = try second.store.save(from: second.root)

      let third = TabLaunch(data: data2)
      let host3 = Router(root: home, type: .stack("home"), parent: third.root, schema: schema)
      host3.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "7"))]
      let inner3 = Router(root: home, type: .stack("inner"), parent: host3, schema: schema)

      #expect(inner3.path.isEmpty)
    }

    @Test
    func givenHostPoppedBeforeTheNestedStackIsBuilt_whenSaved_thenTheNestedNodeIsDropped() throws {
      let launch = TabLaunch(data: try savedNestedData())
      let host = Router(root: home, type: .stack("home"), parent: launch.root, schema: schema)
      host.path = []

      let node = launch.snapshot().root.children["stack(home)"]

      #expect(node?.children["stack(inner)"] == nil)
    }

    @Test
    func givenHostStillShowingTheSavedScreen_whenSavedBeforeTheNestedStackIsBuilt_thenTheNestedNodeIsKept() throws {
      let launch = TabLaunch(data: try savedNestedData())
      let host = Router(root: home, type: .stack("home"), parent: launch.root, schema: schema)

      let node = launch.snapshot().root.children["stack(home)"]

      #expect(node?.children["stack(inner)"]?.state?.path.count == 1)
      withExtendedLifetime(host) {}
    }

    @Test
    func givenHostPoppedAndPushedAgainBeforeANestedTabRouterIsBuilt_whenBuilt_thenItStartsOnItsDefaultTab() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let host = Router(root: home, type: .stack("home"), parent: root, schema: schema)
      host.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "42"))]
      let nested = TabRouter(tab: CodableTestTabRoute.a, parent: host)
      nested.change(tab: CodableTestTabRoute.b)
      let data = try store.save(from: root)

      let launch = TabLaunch(data: data)
      let host2 = Router(root: home, type: .stack("home"), parent: launch.root, schema: schema)
      host2.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "7"))]
      let nested2 = TabRouter(tab: CodableTestTabRoute.a, parent: host2)

      #expect(nested2.restoredTab == nil)
      #expect(nested2.tab.wrapped as? CodableTestTabRoute == .a)
      withExtendedLifetime((host, nested)) {}
    }

    @Test
    func givenHostStillShowingTheSavedScreen_whenNestedStackBuilt_thenItIsRestored() throws {
      let launch = TabLaunch(data: try savedNestedData())
      let host = Router(root: home, type: .stack("home"), parent: launch.root, schema: schema)

      let inner = Router(root: home, type: .stack("inner"), parent: host, schema: schema)

      #expect(routes(of: inner) == [.settings])
    }

    @Test
    func givenUnvisitedTabStacks_whenSavedUnderALiveTabRouter_thenTheyAreKept() throws {
      let launch = TabLaunch(data: try savedTabsData())
      let tabRouter = TabRouter(tab: CodableTestTabRoute.a, parent: launch.root)

      let node = launch.snapshot().tabRouterNode

      #expect(node?.children["tab(c)"]?.state?.path.count == 1)
      withExtendedLifetime(tabRouter) {}
    }
  }
}
