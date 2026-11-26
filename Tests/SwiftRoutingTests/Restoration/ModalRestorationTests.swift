import Combine
import Foundation
import Testing
@testable import SwiftRouting

@MainActor private let schema = RestorationSchema(route: CodableTestRoute.self)

private let sheetRoute = CodableTestRoute.details(id: "1")
/// Same name as `sheetRoute`: only the slot tells their presented routers apart.
private let coverRoute = CodableTestRoute.details(id: "2")
private let innerSheetRoute = CodableTestRoute.settings

@MainActor
private func restorationErrorCount(_ spy: LoggerSpy) -> Int {
  spy.receivedMessages.filter {
    if case .error(.restoration) = $0 { true } else { false }
  }.count
}

/// A `stack(home)` router under `parent`, built the way `RoutingView` builds it.
@MainActor
private func stack(_ name: String = "home", in parent: BaseRouter) -> Router {
  Router(root: AnyRoute(wrapped: CodableTestRoute.home), type: .stack(name), parent: parent, schema: schema)
}

/// The presented router of `route` in `slot` of `host`, built the way `RoutingView` builds it.
@MainActor
private func presented(of host: Router, route: CodableTestRoute, slot: ModalSlot) -> Router {
  Router(
    root: AnyRoute(wrapped: route),
    type: .presented(route.name),
    parent: host,
    modalSlot: slot,
    schema: schema
  )
}

/// Builds `app -> stack(home)` with the path `[details(42)]`, a sheet and a cover that each have their own
/// path, a stack nested in the sheet and a sheet nested in the sheet, and returns the data a save writes.
@MainActor
private func savedModalsData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let host = stack(in: root)
  host.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "42"))]
  host.sheet = AnyRoute(wrapped: sheetRoute)
  host.cover = AnyRoute(wrapped: coverRoute)

  let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
  sheet.path = [AnyRoute(wrapped: CodableTestRoute.settings)]
  let cover = presented(of: host, route: coverRoute, slot: .cover)
  cover.path = [AnyRoute(wrapped: CodableTestRoute.home)]

  let nestedStack = stack("inner", in: sheet)
  nestedStack.path = [AnyRoute(wrapped: CodableTestRoute.details(id: "nested"))]
  sheet.sheet = AnyRoute(wrapped: innerSheetRoute, inStack: false)
  let innerSheet = presented(of: sheet, route: innerSheetRoute, slot: .sheet)
  innerSheet.path = [AnyRoute(wrapped: CodableTestRoute.home)]

  let data = try store.save(from: root)
  withExtendedLifetime((nestedStack, innerSheet)) {}
  return data
}

/// The saved data with the sheet of the host removed, which leaves its presented node stale.
private func dataWithoutHostSheet(_ data: Data) throws -> Data {
  var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: data)
  snapshot.root.children["stack(home)"]?.state?.sheet = nil
  return try NavigationRestorationStore.encode(snapshot)
}

@MainActor
struct ModalRestorationTests {

  @MainActor
  struct Restored {
    let data: Data
    let root: Router
    let host: Router

    init() throws {
      data = try savedModalsData()
      root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      host = stack(in: root)
    }

    @Test
    func givenSavedSheet_whenHostRebuilt_thenHostShowsTheSheet() {
      #expect(host.sheet == AnyRoute(wrapped: sheetRoute))
      #expect(host.sheet?.inStack == true)
    }

    @Test
    func givenSavedCover_whenHostRebuilt_thenHostShowsTheCover() {
      #expect(host.cover == AnyRoute(wrapped: coverRoute))
    }

    @Test
    func givenSavedSheet_whenHostRebuilt_thenHostKeepsItsOwnPath() {
      #expect(host.path.map { $0.wrapped as? CodableTestRoute } == [.details(id: "42")])
    }

    @Test
    func givenRestoredSheet_whenPresentedRouterBuilt_thenItGetsItsPath() {
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(sheet.path.map { $0.wrapped as? CodableTestRoute } == [.settings])
    }

    @Test
    func givenRestoredCover_whenPresentedRouterBuilt_thenItGetsItsPath() {
      let cover = presented(of: host, route: coverRoute, slot: .cover)

      #expect(cover.path.map { $0.wrapped as? CodableTestRoute } == [.home])
    }

    @Test
    func givenSheetAndCoverOfTheSameRouteName_whenBothBuilt_thenEachKeepsItsOwnState() {
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      let cover = presented(of: host, route: coverRoute, slot: .cover)

      #expect(sheet.path.map { $0.wrapped as? CodableTestRoute } == [.settings])
      #expect(cover.path.map { $0.wrapped as? CodableTestRoute } == [.home])
    }

    @Test
    func givenRestoredSheet_whenSheetNestedInItBuilt_thenItIsRestoredRecursively() {
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      let innerSheet = presented(of: sheet, route: innerSheetRoute, slot: .sheet)

      #expect(sheet.sheet == AnyRoute(wrapped: innerSheetRoute))
      #expect(sheet.sheet?.inStack == false)
      #expect(innerSheet.path.map { $0.wrapped as? CodableTestRoute } == [.home])
    }

    @Test
    func givenRestoredSheet_whenStackNestedInItBuilt_thenItIsSeeded() {
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      let nestedStack = stack("inner", in: sheet)

      #expect(nestedStack.path.map { $0.wrapped as? CodableTestRoute } == [.details(id: "nested")])
    }

    @Test
    func givenRestoredSheet_whenSecondPresentedRouterBuilt_thenItStartsOnDefaultState() {
      _ = presented(of: host, route: sheetRoute, slot: .sheet)

      let second = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(second.path.isEmpty)
    }

    @Test
    func givenRestoredSheet_whenPresentedRouterBuiltForAnotherRoute_thenItStartsOnDefaultState() {
      let other = presented(of: host, route: .details(id: "9"), slot: .sheet)

      #expect(other.path.isEmpty)
    }

    @Test
    func givenRestoredSheet_whenSheetThenReplacedAndPresentedAgain_thenItStartsOnDefaultState() {
      host.sheet = nil
      host.sheet = AnyRoute(wrapped: sheetRoute)

      let fresh = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(fresh.path.isEmpty)
    }
  }

  @MainActor
  struct Seeding {
    @Test
    func givenSavedModals_whenHostRebuilt_thenOnlyCreateIsLogged() throws {
      let data = try savedModalsData()
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let before = spy.receivedMessages.count

      let host = stack(in: root)

      let added = spy.receivedMessages.dropFirst(before)
      #expect(added.count == 1)
      #expect(added.allSatisfy { if case .create = $0 { true } else { false } })
      withExtendedLifetime(host) {}
    }

    @Test
    func givenSavedModals_whenHostRebuilt_thenNothingIsPresented() async throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      var presentCount = 0
      let cancellable = root.present.sink { _ in presentCount += 1 }

      let host = stack(in: root)
      _ = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(presentCount == 0)
      withExtendedLifetime(cancellable) {}
    }

    @Test
    func givenSavedModals_whenHostAndChildRebuilt_thenNeitherLeavesScreenNorDismisses() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))

      let host = stack(in: root)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(!sheet.hasLeftScreen)
      #expect(host.sheet != nil)
    }
  }

  @MainActor
  struct FreshModal {
    @Test
    func givenStaleNodeAndHostWithoutSheet_whenSheetPresentedFresh_thenItStartsOnDefaultState() throws {
      let data = try dataWithoutHostSheet(try savedModalsData())
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)

      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(host.sheet?.wrapped as? CodableTestRoute == sheetRoute)
      #expect(sheet.path.isEmpty)
    }

    @Test
    func givenStaleNodeAndHostWithoutSheet_whenStackNestedInFreshSheetBuilt_thenItStartsOnDefaultState() throws {
      let data = try dataWithoutHostSheet(try savedModalsData())
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      let nestedStack = stack("inner", in: sheet)

      #expect(nestedStack.path.isEmpty)
    }

    @Test
    func givenStaleNodeAndHostWithoutSheet_whenSheetNestedInFreshSheetBuilt_thenItStartsOnDefaultState() throws {
      let data = try dataWithoutHostSheet(try savedModalsData())
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      sheet.sheet = AnyRoute(wrapped: innerSheetRoute, inStack: false)

      let innerSheet = presented(of: sheet, route: innerSheetRoute, slot: .sheet)

      #expect(innerSheet.path.isEmpty)
    }

    @Test
    func givenRestoredHost_whenCoverClearedAndPresentedFresh_thenItStartsOnDefaultState() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)
      host.cover = nil

      host.cover = AnyRoute(wrapped: coverRoute)
      let cover = presented(of: host, route: coverRoute, slot: .cover)

      #expect(cover.path.isEmpty)
    }

    @Test
    func givenFreshSheet_whenPresentedRouterBuilt_thenNoRestorationLog() throws {
      let data = try dataWithoutHostSheet(try savedModalsData())
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)

      host.sheet = AnyRoute(wrapped: sheetRoute)
      _ = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(restorationErrorCount(spy) == 0)
    }
  }

  @MainActor
  struct Deeplink {
    @Test
    func givenRestoredSheetWithoutChildRouter_whenDeeplinkHandled_thenSheetAndCoverAreCleared() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)

      host.handle(deeplink: DeeplinkRoute(type: .push, route: CodableTestRoute.settings))

      #expect(host.sheet == nil)
      #expect(host.cover == nil)
    }

    @Test
    func givenRestoredSheetWithoutChildRouter_whenDeeplinkHandled_thenDeeplinkLandsOnTopOfTheRestoredPath() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)

      host.handle(deeplink: DeeplinkRoute(type: .push, route: CodableTestRoute.settings))

      #expect(host.path.map { $0.wrapped as? CodableTestRoute } == [.settings])
    }

    @Test
    func givenDeeplinkClosedRestoredSheet_whenSheetPresentedFresh_thenItStartsOnDefaultState() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)
      host.closeChildren()

      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      #expect(sheet.path.isEmpty)
    }

    @Test
    func givenDeeplinkClosedRestoredSheet_whenNestedStackBuiltInFreshSheet_thenItStartsOnDefaultState() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: data))
      let host = stack(in: root)
      host.closeChildren()
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      let nestedStack = stack("inner", in: sheet)

      #expect(nestedStack.path.isEmpty)
    }

    @Test
    func givenDeeplinkClosedRestoredSheet_whenSnapshotTaken_thenNoPresentedNodeIsSaved() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore(data: data)
      root.attachRestorationStore(store)
      let host = stack(in: root)
      host.closeChildren()

      let snapshot = store.snapshot(from: root)

      #expect(snapshot.root.children["stack(home)"]?.children.isEmpty == true)
      #expect(snapshot.root.children["stack(home)"]?.state?.sheet == nil)
      #expect(snapshot.root.children["stack(home)"]?.state?.cover == nil)
    }
  }

  @MainActor
  struct Saving {
    @Test
    func givenSheetAndCoverPresented_whenSnapshotTaken_thenBothSlotsAreInTheKey() throws {
      let data = try savedModalsData()

      let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: data)

      let children = snapshot.root.children["stack(home)"]?.children
      #expect(children?.keys.sorted() == ["presented(details)#cover", "presented(details)#sheet"])
    }

    @Test
    func givenPresentedRouterThatIsTheSheet_whenSnapshotTaken_thenOnlyItsOwnSlotIsSaved() {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      // Same route as the sheet, but the cover is not showing it.
      let strayCover = presented(of: host, route: sheetRoute, slot: .cover)

      let snapshot = store.snapshot(from: root)

      #expect(snapshot.root.children["stack(home)"]?.children.keys.sorted() == ["presented(details)#sheet"])
      withExtendedLifetime((sheet, strayCover)) {}
    }

    @Test
    func givenPendingModalAndDismissingChild_whenSnapshotTaken_thenNeitherIsSaved() {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let dismissing = presented(of: host, route: sheetRoute, slot: .sheet)
      host.sheet = nil
      host.present(CodableTestRoute.settings)

      let snapshot = store.snapshot(from: root)

      let node = snapshot.root.children["stack(home)"]
      #expect(host.sheet == nil)
      #expect(node?.state?.sheet == nil)
      #expect(node?.children.isEmpty == true)
      withExtendedLifetime(dismissing) {}
    }

    @Test
    func givenSheetThatLeftScreen_whenSnapshotTaken_thenItIsNotSaved() {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      host.sheet = nil

      let snapshot = store.snapshot(from: root)

      #expect(sheet.hasLeftScreen)
      #expect(snapshot.root.children["stack(home)"]?.children.isEmpty == true)
    }

    @Test
    func givenRestoredSheetWithoutChildRouter_whenSnapshotTaken_thenTheSheetAndItsSavedNodeAreKept() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore(data: data)
      root.attachRestorationStore(store)
      let host = stack(in: root)

      let snapshot = store.snapshot(from: root)

      #expect(snapshot.root.children["stack(home)"]?.state?.sheet != nil)
      // The host still shows the restored sheet, whose router is not built yet: its node is not lost.
      #expect(snapshot.root.children["stack(home)"]?.children["presented(details)#sheet"] != nil)
      withExtendedLifetime(host) {}
    }

    @Test
    func givenSavedRestoredTree_whenSavedAgain_thenTheDataIsIdentical() throws {
      let data = try savedModalsData()
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore(data: data)
      root.attachRestorationStore(store)
      let host = stack(in: root)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      let cover = presented(of: host, route: coverRoute, slot: .cover)
      let nestedStack = stack("inner", in: sheet)
      let innerSheet = presented(of: sheet, route: innerSheetRoute, slot: .sheet)

      let saved = try store.save(from: root)

      #expect(saved == data)
      withExtendedLifetime((cover, nestedStack, innerSheet)) {}
    }
  }

  @MainActor
  struct DecodingFailure {
    @Test
    func givenUndecodableSheet_whenHostRebuilt_thenHostShowsNoModalAndKeepsItsPath() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: try savedModalsData())
      snapshot.root.children["stack(home)"]?.state?.sheet = StoredRoute(payload: Data("{}".utf8), inStack: true)
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: try NavigationRestorationStore.encode(snapshot)))

      let host = stack(in: root)

      #expect(host.sheet == nil)
      #expect(host.path.map { $0.wrapped as? CodableTestRoute } == [.details(id: "42")])
    }

    @Test
    func givenUndecodableSheet_whenHostRebuilt_thenOneDecodingFailedIsLogged() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: try savedModalsData())
      snapshot.root.children["stack(home)"]?.state?.sheet = StoredRoute(payload: Data("{}".utf8), inStack: true)
      let spy = LoggerSpy(storesConfiguration: false)
      let root = Router(configuration: Configuration(loggerSpy: spy))
      root.attachRestorationStore(NavigationRestorationStore(data: try NavigationRestorationStore.encode(snapshot)))

      _ = stack(in: root)

      #expect(restorationErrorCount(spy) == 1)
      assertLogMessagesContain(spy, expected: .error(.restoration(.decodingFailed(container: "app/stack(home)#sheet", error: ""))))
    }

    @Test
    func givenUndecodableSheet_whenSheetPresentedFresh_thenItsSubtreeStartsOnDefaultState() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: try savedModalsData())
      snapshot.root.children["stack(home)"]?.state?.sheet = StoredRoute(payload: Data("{}".utf8), inStack: true)
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: try NavigationRestorationStore.encode(snapshot)))
      let host = stack(in: root)
      host.sheet = AnyRoute(wrapped: sheetRoute)

      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)
      let nestedStack = stack("inner", in: sheet)

      #expect(sheet.path.isEmpty)
      #expect(nestedStack.path.isEmpty)
    }

    @Test
    func givenUndecodableSheet_whenCoverIsDecodable_thenCoverIsStillRestored() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: try savedModalsData())
      snapshot.root.children["stack(home)"]?.state?.sheet = StoredRoute(payload: Data("{}".utf8), inStack: true)
      let root = Router(configuration: Configuration())
      root.attachRestorationStore(NavigationRestorationStore(data: try NavigationRestorationStore.encode(snapshot)))

      let host = stack(in: root)

      #expect(host.cover == AnyRoute(wrapped: coverRoute))
    }
  }

  @MainActor
  struct Attachment {
    @Test
    func givenPresentedRouter_whenStoreAttached_thenItKeepsTheStoreOfTheRoot() {
      let root = Router(configuration: Configuration())
      let expectedStore = NavigationRestorationStore()
      root.attachRestorationStore(expectedStore)
      let host = stack(in: root)
      let sheet = presented(of: host, route: sheetRoute, slot: .sheet)

      let attached = sheet.attachRestorationStore(NavigationRestorationStore())

      #expect(!attached)
      #expect(sheet.restorationStore === expectedStore)
    }

    @Test
    func givenRootRouter_whenStoreAttached_thenItIsAttached() {
      let root = Router(configuration: Configuration())
      let expectedStore = NavigationRestorationStore()

      let attached = root.attachRestorationStore(expectedStore)

      #expect(attached)
      #expect(root.restorationStore === expectedStore)
    }
  }
}
