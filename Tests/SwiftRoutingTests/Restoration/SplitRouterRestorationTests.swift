import Combine
import Foundation
import Testing
@testable import SwiftRouting

private let route = CodableTestRoute.self
private let detailPath = CodableTestRoute.details(id: "7")
private let nestedPath = CodableTestRoute.details(id: "nested")
private let savedDetail = CodableSplitDetail(id: "d1")
private let otherDetail = CodableSplitDetail(id: "d2")

/// What `RoutingSplitView` builds for a 3-column split: factories that refuse the detail `"gone"`.
@MainActor
private func threeColumns(in parent: BaseRouter) -> Router {
  Router(
    root: AnyRoute(wrapped: CodableTestRoute.home),
    type: .split("home", hasContentColumn: true),
    parent: parent,
    detailRouteFactory: { ($0 as? CodableSplitDetail).flatMap { $0.id == "gone" ? nil : AnyRoute(wrapped: CodableTestRoute.details(id: $0.id)) } },
    contentRouteFactory: { ($0 as? CodableSplitContent).map { _ in AnyRoute(wrapped: CodableTestRoute.settings) } },
    schema: RestorationSchema(route: route, content: CodableSplitContent.self, detail: CodableSplitDetail.self)
  )
}

/// What `RoutingSplitView` builds for a 2-column split (`ContentData == Never`).
@MainActor
private func twoColumns(in parent: BaseRouter) -> Router {
  Router(
    root: AnyRoute(wrapped: CodableTestRoute.home),
    type: .split("home", hasContentColumn: false),
    parent: parent,
    detailRouteFactory: { ($0 as? CodableSplitDetail).map { AnyRoute(wrapped: CodableTestRoute.details(id: $0.id)) } },
    schema: RestorationSchema(route: route, content: Never.self, detail: CodableSplitDetail.self)
  )
}

/// A stack nested in the split, as a screen of the detail column would build it.
@MainActor
private func nestedStack(in split: Router) -> Router {
  Router(
    root: AnyRoute(wrapped: CodableTestRoute.home),
    type: .stack("nested"),
    parent: split,
    schema: RestorationSchema(route: route)
  )
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

/// A saved 3-column split on content `teams`, detail `d1` and a detail path `[details(7)]`,
/// with a stack nested in it holding `[details(nested)]`.
@MainActor
private func savedThreeColumnData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let split = threeColumns(in: root)
  split.select(content: CodableSplitContent.teams)
  split.select(detail: savedDetail)
  split.path = [AnyRoute(wrapped: detailPath)]
  let nested = nestedStack(in: split)
  nested.path = [AnyRoute(wrapped: nestedPath)]
  let data = try store.save(from: root)
  withExtendedLifetime((split, nested)) {}
  return data
}

@MainActor
private func savedTwoColumnData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let split = twoColumns(in: root)
  split.select(detail: savedDetail)
  let data = try store.save(from: root)
  withExtendedLifetime(split) {}
  return data
}

private extension NavigationSnapshot {
  var splitNode: RestorationNode? { root.children["split(home)"] }
}

@MainActor
struct SplitRouterRestorationTests {

  @MainActor
  struct Seeding {
    let launch: TabLaunch

    init() throws {
      launch = TabLaunch(data: try savedThreeColumnData())
    }

    @Test
    func givenSavedSplit_whenSplitBuilt_thenContentDetailAndPathAreRestoredTogether() {
      let split = threeColumns(in: launch.root)

      #expect(split.contentSelection == AnyHashable(CodableSplitContent.teams))
      #expect(split.detailSelection == AnyHashable(savedDetail))
      #expect(routes(of: split) == [detailPath])
    }

    @Test
    func givenSavedSplit_whenSplitBuilt_thenNoLogOtherThanCreate() async {
      await Task.yield()
      launch.spy.clearReceivedMessages()

      let split = threeColumns(in: launch.root)
      await Task.yield()

      let others = launch.spy.receivedMessages.filter { if case .create = $0 { false } else { true } }
      #expect(others.isEmpty)
      withExtendedLifetime(split) {}
    }

    @Test
    func givenSavedSplit_whenSplitBuilt_thenNothingIsPresentedAndNoErrorIsLogged() async {
      await Task.yield()
      var presentCount = 0
      var cancellables: Set<AnyCancellable> = []
      launch.root.present.sink { _ in presentCount += 1 }.store(in: &cancellables)

      let split = threeColumns(in: launch.root)
      await Task.yield()

      #expect(presentCount == 0)
      #expect(restorationErrorCount(launch.spy) == 0)
      withExtendedLifetime(split) {}
    }

    @Test
    func givenSavedSplit_whenSplitBuiltTwice_thenTheSecondOneStartsOnItsDefaultState() {
      _ = threeColumns(in: launch.root)

      let second = threeColumns(in: launch.root)

      #expect(second.contentSelection == nil)
      #expect(second.detailSelection == nil)
      #expect(second.path.isEmpty)
    }

    @Test
    func givenNoStore_whenSplitBuilt_thenItStartsOnItsDefaultState() {
      let split = threeColumns(in: Router(configuration: Configuration()))

      #expect(split.contentSelection == nil)
      #expect(split.detailSelection == nil)
    }

    @Test
    func givenSavedTwoColumnSplit_whenSplitBuilt_thenTheDetailSelectionIsRestored() throws {
      let launch = TabLaunch(data: try savedTwoColumnData())

      let split = twoColumns(in: launch.root)

      #expect(split.detailSelection == AnyHashable(savedDetail))
      #expect(split.contentSelection == nil)
      #expect(restorationErrorCount(launch.spy) == 0)
    }
  }

  @MainActor
  struct Saving {
    @Test
    func givenSelections_whenSaved_thenTheSplitNodeEncodesBothSelections() throws {
      let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedThreeColumnData())

      let state = snapshot.splitNode?.state
      #expect(state?.contentSelection != nil)
      #expect(state?.detailSelection != nil)
      #expect(state?.path.count == 1)
    }

    @Test
    func givenTwoColumnSplit_whenSaved_thenOnlyTheDetailSelectionIsEncoded() throws {
      let snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedTwoColumnData())

      #expect(snapshot.splitNode?.state?.detailSelection != nil)
      #expect(snapshot.splitNode?.state?.contentSelection == nil)
    }

    @Test
    func givenReloadedSplit_whenSavedAgain_thenTheSelectionsSurvive() throws {
      let launch = TabLaunch(data: try savedThreeColumnData())
      let split = threeColumns(in: launch.root)

      let state = launch.snapshot().splitNode?.state

      #expect(state == (try JSONDecoder().decode(NavigationSnapshot.self, from: savedThreeColumnData())).splitNode?.state)
      withExtendedLifetime(split) {}
    }
  }

  @MainActor
  struct NotCodable {
    private func launch(builtWith schema: RestorationSchema) throws -> (TabLaunch, Router) {
      let launch = TabLaunch(data: try savedThreeColumnData())
      let split = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .split("home", hasContentColumn: true),
        parent: launch.root,
        schema: schema
      )
      return (launch, split)
    }

    @Test
    func givenNonCodableDetailData_whenSplitBuiltTwice_thenDefaultStateAndNotCodableNamesTheTypeOnce() throws {
      let schema = RestorationSchema(route: route, content: CodableSplitContent.self, detail: NonCodableSplitDetail.self)
      let (launch, split) = try launch(builtWith: schema)
      _ = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .split("home", hasContentColumn: true),
        parent: launch.root,
        schema: schema
      )

      #expect(split.detailSelection == nil)
      #expect(split.contentSelection == nil)
      #expect(split.path.isEmpty)
      #expect(restorationErrorCount(launch.spy) == 1)
      assertLogMessagesContain(
        launch.spy,
        expected: .error(.restoration(.notCodable(container: "app/split(home)", type: "NonCodableSplitDetail")))
      )
    }

    @Test
    func givenNonCodableContentData_whenSplitBuilt_thenNotCodableNamesTheContentType() throws {
      let schema = RestorationSchema(route: route, content: NonCodableSplitContent.self, detail: CodableSplitDetail.self)
      let (launch, split) = try launch(builtWith: schema)

      #expect(split.detailSelection == nil)
      assertLogMessagesContain(
        launch.spy,
        expected: .error(.restoration(.notCodable(container: "app/split(home)", type: "NonCodableSplitContent")))
      )
    }

    @Test
    func givenNonCodableDetailDataAndCrashFlagOn_whenSplitBuilt_thenTheFailureHookIsCalledOnce() throws {
      let recorder = FailureRecorder()
      let launch = TabLaunch(data: nil, shouldCrashOnRouteNotFound: true, failureHook: recorder.record)

      _ = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .split("home", hasContentColumn: true),
        parent: launch.root,
        schema: RestorationSchema(route: route, content: CodableSplitContent.self, detail: NonCodableSplitDetail.self)
      )

      #expect(recorder.messages.count == 1)
    }

    @Test
    func givenNonCodableDetailData_whenSaved_thenNoStateIsWrittenForTheSplit() throws {
      let root = Router(configuration: Configuration())
      let store = NavigationRestorationStore()
      root.attachRestorationStore(store)
      let split = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .split("home", hasContentColumn: false),
        parent: root,
        detailRouteFactory: { ($0 as? NonCodableSplitDetail).map { _ in AnyRoute(wrapped: CodableTestRoute.settings) } },
        schema: RestorationSchema(route: route, content: Never.self, detail: NonCodableSplitDetail.self)
      )
      split.select(detail: NonCodableSplitDetail(id: "x"))

      #expect(store.snapshot(from: root).splitNode?.state == nil)
    }
  }

  @MainActor
  struct Rejected {
    private func launch(detail: CodableSplitDetail) throws -> TabLaunch {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedThreeColumnData())
      snapshot.root.children["split(home)"]?.state?.detailSelection = try RestorationCodec.encode(value: detail, inStack: false)
      return TabLaunch(data: try NavigationRestorationStore.encode(snapshot))
    }

    @Test
    func givenSelectionTheFactoryRefuses_whenSplitBuilt_thenTheWholeSplitStartsOnDefault() throws {
      let launch = try launch(detail: CodableSplitDetail(id: "gone"))

      let split = threeColumns(in: launch.root)

      #expect(split.detailSelection == nil)
      #expect(split.contentSelection == nil)
      #expect(split.path.isEmpty)
    }

    @Test
    func givenSelectionTheFactoryRefuses_whenSplitBuiltTwice_thenDecodingFailedIsLoggedOnce() throws {
      let launch = try launch(detail: CodableSplitDetail(id: "gone"))

      _ = threeColumns(in: launch.root)
      _ = threeColumns(in: launch.root)

      #expect(restorationErrorCount(launch.spy) == 1)
      assertLogMessagesContain(launch.spy, expected: .error(.restoration(.decodingFailed(container: "app/split(home)", error: ""))))
    }

    @Test
    func givenSelectionTheFactoryRefuses_whenNestedStackBuilt_thenItStartsOnDefault() throws {
      let launch = try launch(detail: CodableSplitDetail(id: "gone"))
      let split = threeColumns(in: launch.root)

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenUndecodableSelection_whenSplitBuilt_thenDefaultStateAndOneDecodingFailed() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedThreeColumnData())
      snapshot.root.children["split(home)"]?.state?.contentSelection?.payload = Data("\"removedCase\"".utf8)
      let launch = TabLaunch(data: try NavigationRestorationStore.encode(snapshot))

      let split = threeColumns(in: launch.root)

      #expect(split.contentSelection == nil)
      #expect(split.detailSelection == nil)
      #expect(split.path.isEmpty)
      #expect(restorationErrorCount(launch.spy) == 1)
      assertLogMessagesContain(launch.spy, expected: .error(.restoration(.decodingFailed(container: "app/split(home)", error: ""))))
    }

    @Test
    func givenRefusedSelectionAndCrashFlagOn_whenSplitBuilt_thenItDoesNotCrash() throws {
      var snapshot = try JSONDecoder().decode(NavigationSnapshot.self, from: savedThreeColumnData())
      snapshot.root.children["split(home)"]?.state?.detailSelection = try RestorationCodec.encode(value: CodableSplitDetail(id: "gone"))
      let crashing = TabLaunch(data: try NavigationRestorationStore.encode(snapshot), shouldCrashOnRouteNotFound: true)

      let split = threeColumns(in: crashing.root)

      #expect(split.detailSelection == nil)
    }
  }

  @MainActor
  struct StaleState {
    let launch: TabLaunch

    init() throws {
      launch = TabLaunch(data: try savedThreeColumnData())
    }

    @Test
    func givenRestoredSplit_whenNestedStackBuiltWithoutSelectionChange_thenItIsRestored() {
      let split = threeColumns(in: launch.root)

      #expect(routes(of: nestedStack(in: split)) == [nestedPath])
    }

    @Test
    func givenRestoredSplit_whenSameDetailSelectedAgain_thenNestedStackIsStillRestored() {
      let split = threeColumns(in: launch.root)
      split.select(detail: savedDetail)

      #expect(routes(of: nestedStack(in: split)) == [nestedPath])
    }

    @Test
    func givenRestoredSplit_whenAnotherDetailSelectedBeforeNestedStackBuilt_thenItStartsOnDefault() {
      let split = threeColumns(in: launch.root)
      split.select(detail: otherDetail)

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenRestoredSplit_whenAnotherContentSelectedBeforeNestedStackBuilt_thenItStartsOnDefault() {
      let split = threeColumns(in: launch.root)
      split.select(content: CodableSplitContent.players)

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenRestoredSplit_whenDetailClearedBeforeNestedStackBuilt_thenItStartsOnDefault() {
      let split = threeColumns(in: launch.root)
      split.select(detail: CodableSplitDetail?.none)

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenRestoredSplit_whenDetailChangedThenReselectedEqualToTheRestoredOne_thenNestedStackStaysOnDefault() {
      let split = threeColumns(in: launch.root)
      split.select(detail: otherDetail)
      split.select(detail: savedDetail)

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenRestoredSplit_whenDetailChanged_thenTheStoredNestedNodeIsNotSavedAgain() {
      let split = threeColumns(in: launch.root)
      split.select(detail: otherDetail)

      let node = launch.snapshot().splitNode

      #expect(node?.children["stack(nested)"] == nil)
      #expect(node?.state?.detailSelection != nil)
      withExtendedLifetime(split) {}
    }

    @Test
    func givenRestoredSplit_whenNestedStackBuiltThenDetailChanged_thenTheBuiltStackKeepsItsRestoredPath() {
      let split = threeColumns(in: launch.root)
      let nested = nestedStack(in: split)
      split.select(detail: otherDetail)

      #expect(routes(of: nested) == [nestedPath])
    }
  }

  @MainActor
  struct NotRestoredHost {
    /// A split saved with a nested stack, relaunched with selections that are not `Codable`.
    private func nonCodableSplit(in launch: TabLaunch) throws -> Router {
      Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .split("home", hasContentColumn: false),
        parent: launch.root,
        detailRouteFactory: { ($0 as? NonCodableSplitDetail).map { _ in AnyRoute(wrapped: CodableTestRoute.settings) } },
        schema: RestorationSchema(route: route, content: Never.self, detail: NonCodableSplitDetail.self)
      )
    }

    @Test
    func givenNonCodableSplit_whenDetailSelectedThenNestedStackBuilt_thenItStartsOnDefault() throws {
      let launch = TabLaunch(data: try savedThreeColumnData())
      let split = try nonCodableSplit(in: launch)
      split.select(detail: NonCodableSplitDetail(id: "y"))

      #expect(nestedStack(in: split).path.isEmpty)
    }

    @Test
    func givenNonCodableSplit_whenDetailSelected_thenTheStoredNestedNodeIsNotSavedAgain() throws {
      let launch = TabLaunch(data: try savedThreeColumnData())
      let split = try nonCodableSplit(in: launch)
      split.select(detail: NonCodableSplitDetail(id: "y"))

      #expect(launch.snapshot().splitNode?.children["stack(nested)"] == nil)
      withExtendedLifetime(split) {}
    }

    @Test
    func givenNonCodableStack_whenNestedContainerBuiltUnderAPushedScreen_thenItStartsOnDefault() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("main"),
        parent: launch.root,
        schema: RestorationSchema(route: TestRoute.self)
      )
      stack.push(TestRoute.details(id: "1"))

      #expect(nestedStack(in: stack).path.isEmpty)
      #expect(launch.snapshot().root.children["stack(main)"]?.children["stack(nested)"] == nil)
    }

    @Test
    func givenNonCodableStack_whenNestedContainerBuiltInRootScreen_thenItIsRestored() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = nonCodableStack(in: launch)

      #expect(routes(of: nestedStack(in: stack)) == [nestedPath])
    }

    @Test
    func givenNonCodableStack_whenPushedThenNestedContainerBuilt_thenItStartsOnDefault() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = nonCodableStack(in: launch)
      stack.push(TestRoute.details(id: "1"))

      #expect(nestedStack(in: stack).path.isEmpty)
    }

    @Test
    func givenNonCodableStack_whenNestedNotBuiltAndNothingChanged_thenTheStoredNodeIsKept() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = nonCodableStack(in: launch)

      #expect(launch.snapshot().root.children["stack(main)"]?.children["stack(nested)"] != nil)
      withExtendedLifetime(stack) {}
    }

    @Test
    func givenNonCodableStack_whenPushedAndNestedNotBuilt_thenTheStoredNodeIsNotSavedAgain() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = nonCodableStack(in: launch)
      stack.push(TestRoute.details(id: "1"))

      #expect(launch.snapshot().root.children["stack(main)"]?.children["stack(nested)"] == nil)
    }

    @Test
    func givenNonCodableSplit_whenNestedContainerBuiltInSidebar_thenItIsRestored() throws {
      let launch = TabLaunch(data: try savedThreeColumnData())
      let split = try nonCodableSplit(in: launch)

      #expect(routes(of: nestedStack(in: split)) == [nestedPath])
    }

    @Test
    func givenRestoredStackReleased_whenSecondRouterBuiltAndNestedContainerBuiltUnderAnotherScreen_thenItStartsOnDefault() throws {
      let launch = TabLaunch(data: try savedRestoredStackWithPathData())
      var first: Router? = codableStack(in: launch)
      first = nil
      let second = codableStack(in: launch)
      second.push(CodableTestRoute.details(id: "y"))

      #expect(nestedStack(in: second).path.isEmpty)
      withExtendedLifetime(first) {}
    }

    @Test
    func givenRestoredStackReleased_whenSecondRouterBuilt_thenTheStaleNestedNodeIsNotSavedAgain() throws {
      let launch = TabLaunch(data: try savedRestoredStackWithPathData())
      var first: Router? = codableStack(in: launch)
      first = nil
      let second = codableStack(in: launch)

      #expect(launch.snapshot().root.children["stack(main)"]?.children["stack(nested)"] == nil)
      withExtendedLifetime((first, second)) {}
    }

    private func nonCodableStack(in launch: TabLaunch) -> Router {
      Router(
        root: AnyRoute(wrapped: TestRoute.home),
        type: .stack("main"),
        parent: launch.root,
        schema: RestorationSchema(route: TestRoute.self)
      )
    }

    private func codableStack(in launch: TabLaunch) -> Router {
      Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("main"),
        parent: launch.root,
        schema: RestorationSchema(route: route)
      )
    }

    @Test
    func givenRestoredStack_whenNestedContainerBuilt_thenItIsRestored() throws {
      let launch = TabLaunch(data: try savedStackData())
      let stack = Router(
        root: AnyRoute(wrapped: CodableTestRoute.home),
        type: .stack("main"),
        parent: launch.root,
        schema: RestorationSchema(route: route)
      )

      #expect(routes(of: nestedStack(in: stack)) == [nestedPath])
    }
  }
}

/// A saved codable stack `main` holding a nested stack `[details(nested)]`.
@MainActor
private func savedStackData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let stack = Router(
    root: AnyRoute(wrapped: CodableTestRoute.home),
    type: .stack("main"),
    parent: root,
    schema: RestorationSchema(route: route)
  )
  let nested = nestedStack(in: stack)
  nested.path = [AnyRoute(wrapped: nestedPath)]
  let data = try store.save(from: root)
  withExtendedLifetime((stack, nested)) {}
  return data
}

/// A saved codable stack `main` on `[details(x)]` holding a nested stack `[details(nested)]` under it.
@MainActor
private func savedRestoredStackWithPathData() throws -> Data {
  let root = Router(configuration: Configuration())
  let store = NavigationRestorationStore()
  root.attachRestorationStore(store)
  let stack = Router(
    root: AnyRoute(wrapped: CodableTestRoute.home),
    type: .stack("main"),
    parent: root,
    schema: RestorationSchema(route: route)
  )
  stack.push(CodableTestRoute.details(id: "x"))
  let nested = nestedStack(in: stack)
  nested.path = [AnyRoute(wrapped: nestedPath)]
  let data = try store.save(from: root)
  withExtendedLifetime((stack, nested)) {}
  return data
}
