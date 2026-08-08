# Changelog

All notable changes to SwiftRouting are documented here.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## Maintaining this file

- Add an entry under `[Unreleased]` in the same PR as the code change.
- On release, `.github/workflows/changelog.yml` renames `[Unreleased]` to the new
  version and dates it automatically when the tag is pushed.

## [Unreleased]

## [0.7.0] - 2026-08-08

### Added

- `ContextModel.canTerminate(_:)` to check for a registered `RouteContext` observer before calling `terminate(_:)`
- `Set<RouterContext>.contains(for:)`
- `printRouter(trigger:)`/`printRouterOnChange()` view modifiers to print the full router hierarchy to the console for debugging (`DEBUG` builds only) -- every router gets a `root:` line, a `path:` line for anything pushed on top of it (omitted when nothing's been pushed), and a split router gets `content:`/`detail:` lines for its column selections
- `Configuration.events`, a payload-less signal fired when any router in the hierarchy logs a meaningful event (routine/redundant ones like view appearance or going back are filtered out) -- powers `printRouterOnChange()`, usable independently of whatever `Configuration.logger` is already configured

### Fixed

- Data race in `BaseRouter.addChild`/`removeChild` (called from non-`@MainActor` `init`/`deinit`) that could corrupt or crash on concurrent router creation/teardown off the main actor -- now guarded by a lock
- `Router.detailBinding(as:)`/`contentBinding(as:)` wrote the selection directly instead of going through `select(detail:)`/`select(content:)`, so selecting a `List` row never logged a `.navigation` event -- `Configuration.logger` and `Configuration.events` (and therefore `printRouterOnChange()`) silently never fired for that path
- `NavigationLink(route:)` pushes bypassed `push(_:)`/`route(to:type:)` entirely (SwiftUI mutates the `NavigationStack(path:)` binding directly), so they were never logged either -- now logged from `path`'s own change instead, catching both origins
- A native swipe-back/back-button tap, or a long-press-back-button jump to an ancestor, mutates `path` the same way and bypassed `back()`/`terminate(_:)` entirely -- now logged as `.action(.back(count:))` from the same observer, without double-logging `back()`/`popToRoot()`/`terminate(_:)`'s own explicit calls
- `select(detail:)`/`select(content:)` logged `navigate from: X to: X` when re-selecting the value that was already selected, since `currentRoute` was read before the selection was updated -- now a no-op when the value hasn't changed
- Pushing onto an empty `path` in a split router always logged `from: root`, even when a detail/content was already selected -- `path`'s `didSet` now resolves "from" the same way `currentRoute` does, instead of assuming `root`

## [0.6.0] - 2026-07-31

### Added

- `SplitDeeplink`/`SplitDeeplinkHandler` and `Router.handle(splitDeeplink:)` for deep linking into `RoutingSplitView` columns (#101)
- `SwiftRoutingTestSupport` package with `RouterSpy`/`TabRouterSpy` test doubles (#102)
- Public `AnyRoute.init(_:)` initializer, enabling external `RouterModel`/`SplitModel` conformances (#102)
- `CHANGELOG.md`, with automated release closeout on tag push (#105)

### Fixed

- Corrected macOS requirement in README (13+ → 14+) (#106)

### Documentation

- Link `RouterType` references to `BaseRouter.description` instead of leaving them unlinked (#103)
- Explain the Route/RouteDestination separation rationale in the README (#104)
- README doc links and the SPM install snippet pointed at a hardcoded old version (`0.2.0`) instead of the current release (`0.6.0`)

## [0.5.0] - 2026-07-30

### Added

- `RoutingSplitView` / `NavigationSplitView` support (#91)

### Documentation

- Split Navigation DocC article (#100)

## [0.4.0] - 2026-06-26

### Added

- `deepestRouter()` on `BaseRouter` for deep link dispatch (#95)

### Fixed

- Clean up root contexts on root change and fix `RouterContext` hash (#97)

### Documentation

- `deepestRouter()` documentation (#98)

## [0.3.0] - 2026-04-23

### Added

- `onTabReselected` modifier for `RoutingTabView`, with a double-write bug fix (#94)

### Changed

- Extract context and presentation into dedicated `ContextModel`/`PresentationModel` protocols (#92)

### Documentation

- Migration article from native `NavigationStack` (#84)
- FAQ article (#82)
- Visual diagrams in Architecture.md (#81)
- Troubleshooting article (#79)
- Reference new articles in SwiftRouting.md (#83)
- Enrich Testing.md with the `LoggerSpy` pattern (#80)
- Medium article link in README (#89)
- README/skills install fixes (#87, #88)
- Introduction article (#90)

### Tests

- `NavigationLink` extension tests (#85)
- `ErrorView` tests for unmatched routes (#86)

## [0.2.0] - 2026-03-02

### Added

- Unit test suite (#57)

### Changed

- `DeeplinkRoute` factory methods (#58)

### Fixed

- DocC version display (#61, #62)

### Documentation

- Documentation pass (#60)

## [0.1.0] - 2026-02-20

### Added

- `TabDeeplinkHandler` (#52)
- Clean context on back navigation (#41)

### Changed

- `onAppear`/`onDisappear` logging improvements (#50)

### Documentation

- Doc and DocC pass (#51)
- AI skills setup (#53, #54)

## [0.0.35] - 2026-01-19

### Added

- `add(context:)`/`remove(context:)` methods on `RouterModel` (#49)

## [0.0.34] - 2026-01-13

### Changed

- Context handling updates + `RouterModel` documentation (#48)

## [0.0.33] - 2025-12-30

### Changed

- Mark deeplink functions as `async throws` (#47)

## [0.0.32] - 2025-12-19

### Fixed

- Remove erroneous `Route` conformance (#43)

### Changed

- `DeeplinkHandler` updates (#44)

## [0.0.31] - 2025-12-15

### Added

- `TabRouter` update function (#42)

## [0.0.30] - 2025-11-18

### Fixed

- `RouterPresentModifier` fix (#40)

### Documentation

- Router context leak notes (#39)

## [0.0.29] - 2025-11-07

### Added

- Router present modifier (#38)

## [0.0.28] - 2025-11-03

### Fixed

- Only add `RouterContext` on first appear (#37)

## [0.0.27] - 2025-10-29

### Fixed

- Add back by default in `terminate` (#36)

## [0.0.26] - 2025-10-27

### Changed

- Improve route termination (#35)

## [0.0.25] - 2025-10-22

### Changed

- Improve logger (#34)

## [0.0.24] - 2025-10-09

### Added

- `routingType` support (#32)
- `root` override in `DeeplinkRoute` (#33)

## [0.0.23] - 2025-07-10

### Added

- Expose route count (#31)

## [0.0.22] - 2025-06-24

### Fixed

- Crash on back action (#29)
- Back condition fix (#30)

## [0.0.21] - 2025-06-13

### Fixed

- Remove stale `TabRouter` from parent (#28)

## [0.0.20] - 2025-06-13

### Fixed

- Context memory leak and cleanup (#27)

## [0.0.19] - 2025-06-11

### Fixed

- Context memory leak (#26)

## [0.0.18] - 2025-06-03

### Added

- Execute context without back or close (#25)

## [0.0.17] - 2025-05-20

### Fixed

- Modal execution with multiple contexts (#24)

## [0.0.16] - 2025-05-16

### Fixed

- Close/back action defaults (#23)

## [0.0.15] - 2025-05-16

### Fixed

- Default close/back action (#22)

## [0.0.14] - 2025-05-16

### Added

- Context on close or back (#19)

## [0.0.13] - 2025-05-16

### Fixed

- Default value in `RoutingType.sheet` (#21)

## [0.0.12] - 2025-05-16

### Added

- Present a route without a navigation stack (#20)

## [0.0.11] - 2025-04-23

### Fixed

- `TabRouter` tab-on-change behavior (#18)

## [0.0.10] - 2025-04-05

### Added

- `TabRouter` (#13)

## [0.0.9] - 2025-03-28

### Added

- Expose action (#17)

## [0.0.8] - 2025-03-26

### Fixed

- Deep link `closeChildren` behavior (#16)

## [0.0.7] - 2025-03-21

### Fixed

- `closeChildren` (#15)

## [0.0.6] - 2025-03-17

### Fixed

- Remove `Observable`, add `@MainActor` on navigation functions (#14)

## [0.0.5] - 2025-03-06

### Added

- Hide tab bar option (#12)

## [0.0.4] - 2025-03-06

### Added

- Expose parent router (#11)

## [0.0.3] - 2025-03-06

### Fixed

- Change root view of the stack (#10)

## [0.0.2] - 2025-02-28

### Added

- Configuration support (#9)
- Feedback handling (#8)

## [0.0.1] - 2025-02-20

### Added

- Initial project foundation (#1, #2, #3, #4)

[Unreleased]: https://github.com/lowki93/swift-routing/compare/0.7.0...HEAD
[0.7.0]: https://github.com/lowki93/swift-routing/compare/0.6.0...0.7.0
[0.6.0]: https://github.com/lowki93/swift-routing/compare/0.5.0...0.6.0
[0.5.0]: https://github.com/lowki93/swift-routing/compare/0.4.0...0.5.0
[0.4.0]: https://github.com/lowki93/swift-routing/compare/0.3.0...0.4.0
[0.3.0]: https://github.com/lowki93/swift-routing/compare/0.2.0...0.3.0
[0.2.0]: https://github.com/lowki93/swift-routing/compare/0.1.0...0.2.0
[0.1.0]: https://github.com/lowki93/swift-routing/compare/0.0.35...0.1.0
