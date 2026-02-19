# Configuration

Use this guide to configure SwiftRouting runtime behavior.

## What Configuration Controls

`Configuration` currently controls:
- logging output (via `logger` closure)
- behavior when a route cannot be resolved in `RouteDestination` (`shouldCrashOnRouteNotFound`)

## shouldCrashOnRouteNotFound

`shouldCrashOnRouteNotFound` defines what happens when a route is not found for the current destination mapping.

Behavior:
- `true`: triggers `fatalError` (fail fast, useful in development/testing)
- `false`: shows an in-app error message instead of crashing

This check is applied by SwiftRouting's internal route resolution layer.

## Recommended Policy

- Development / CI: `shouldCrashOnRouteNotFound = true`
- Production: `shouldCrashOnRouteNotFound = false`

This helps catch routing integration mistakes early without crashing end users in production.

## Logger Configuration

You can provide a custom logger closure to inspect routing events:

```swift
let configuration = Configuration(
  logger: { payload in
    print(payload.message)
  },
  shouldCrashOnRouteNotFound: true
)
```

## Convenience Initializers

Examples:

```swift
// Uses default logger
let devConfig = Configuration(shouldCrashOnRouteNotFound: true)
let prodConfig = Configuration(shouldCrashOnRouteNotFound: false)

// Custom logger
let customConfig = Configuration(
  logger: { payload in
    print(payload.message)
  },
  shouldCrashOnRouteNotFound: false
)
```

## Best Practices

- Decide crash policy explicitly per environment.
- Keep logger output structured and searchable.
- Treat route-not-found as a release blocker before shipping.
