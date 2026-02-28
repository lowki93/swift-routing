# Testing Rules (SwiftRouting)

This file defines testing conventions for the project.

## 1) Test Structure

- Use a top-level `struct` per domain (example: `RouterTests`).
- Keep shared setup in the struct `init()`.
- Prefer instance properties for dependencies (example: `let router: Router`).
- Avoid helper factories like `makeRouter()` when the struct setup is enough.

Example:

```swift
@MainActor
struct RouterTests {
  let router: Router

  init() {
    self.router = Router(configuration: .default)
  }
}
```

## 2) Group Tests by Feature

- Group related tests inside nested `enum` blocks.
- One nested enum = one behavior area (example: `CurrentRoute`, `Push`, `Terminate`).

Example:

```swift
@MainActor
struct RouterTests {
  let router: Router

  init() {
    self.router = Router(configuration: .default)
  }

  @MainActor
  enum CurrentRoute {
    // currentRoute tests
  }
}
```

## 3) Test Naming

Preferred naming:

- `givenX_whenY_thenZ`

Accepted short state/result naming for simple cases:

- `pathIsEmpty_return_rootRoute`
- `pathIsNotEmpty_return_lastElementInPath`

Rules:

- Name must describe behavior, not implementation details.
- Keep names deterministic and readable.
- Use lowerCamelCase.

## 4) Assertions and Scope

- Keep one behavior per test.
- Use `#expect(...)` with clear expected values.
- Do not combine unrelated scenarios in one test.
- For mocked/setup reference values asserted in expectations, prefix variable names with `expected` (example: `expectedRouter`, `expectedSettingsContext`).
- Do not use `expected` prefix for observed outputs returned/emitted by the system under test (example: keep `foundRouter`, `receivedEvent`).

## 5) Mocks and Test Models

- Put reusable models in `Tests/SwiftRoutingTests/Mock/Model/`.
- Keep mock routes minimal (`name` + only required cases).
- Reuse shared mocks before creating new ones.

## 6) Stability Rules

- Tests must be deterministic (no randomness, no timing dependency).
- Prefer pure state verification over logs.
- Run `swift test` after each test change.

## 7) Logger Assertions

- When a test must validate logging behavior, always use `LoggerSpy`.
- Assert log payloads via `assertLogMessageKind(loggerSpy, is: ...)` instead of ad-hoc booleans/switches in each test.
- Prefer asserting both the log message and the emitting router identity (`loggerSpy.receivedRouterId`).
