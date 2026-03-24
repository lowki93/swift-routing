# Configuration and Logging

Learn how to configure SwiftRouting and customize logging behavior.

## Overview

SwiftRouting provides a ``Configuration`` structure to customize router behavior, including logging and error handling. This guide covers how to set up and use these features.

## Basic Configuration

### Default Configuration

By default, `RoutingView` uses `Configuration.default`, which logs navigation events to the console via `OSLog`:

```swift
RoutingView(destination: AppRoute.self, root: .home)
```

### Custom Configuration

To customize behavior, create a ``Router`` with your own configuration and inject it:

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            RoutingView(destination: AppRoute.self, root: .home)
                .environment(
                    \.router,
                    Router(configuration: Configuration(shouldCrashOnRouteNotFound: true))
                )
        }
    }
}
```

## Configuration Options

### shouldCrashOnRouteNotFound

When `true`, the app crashes if a route cannot be resolved. This is useful during development to catch routing errors early:

```swift
// Development: crash on errors
Configuration(shouldCrashOnRouteNotFound: true)

// Production: fail silently
Configuration(shouldCrashOnRouteNotFound: false)
```

### Custom Logger

Provide a custom logger closure to handle navigation events:

```swift
let config = Configuration(
    logger: { loggerConfig in
        // Custom logging logic
        print("[\(loggerConfig.router.id)] \(loggerConfig.message)")
    },
    shouldCrashOnRouteNotFound: false
)
```

## Logging System

### LoggerConfiguration

The logger closure receives a ``LoggerConfiguration`` containing:

| Property | Description |
|----------|-------------|
| `message` | The ``LoggerMessage`` describing the event |
| `router` | The ``BaseRouter`` that triggered the event |

### LoggerMessage Types

SwiftRouting logs various events through ``LoggerMessage``:

#### Router Lifecycle

| Message | Description |
|---------|-------------|
| `.create(from:configuration:)` | Router was initialized |
| `.delete` | Router was deallocated |

#### Navigation Events

| Message | Description |
|---------|-------------|
| `.navigation(from:to:type:)` | Navigation occurred between routes |
| `.onAppear(route)` | Route's view appeared |
| `.onDisappear(route)` | Route's view disappeared |

#### User Actions

| Message | Description |
|---------|-------------|
| `.action(.back)` | User navigated back |
| `.action(.popToRoot)` | Navigation reset to root |
| `.action(.close)` | Modal was dismissed |
| `.action(.closeChildren)` | Child routers were closed |
| `.action(.changeTab)` | Tab selection changed |

#### Context Events

| Message | Description |
|---------|-------------|
| `.context(.add)` | Context observer was registered |
| `.context(.execute)` | Context was sent and executed |
| `.context(.remove)` | Context observer was removed |

#### Routing Errors

| Message | Description |
|---------|-------------|
| `.error(RouterError)` | A route could not be resolved to its destination |

When a route cannot be matched, SwiftRouting emits `.error(RouterError.routeNotFound)` before either crashing or displaying the fallback message. Use this in your logger to monitor unresolved routes in production:

```swift
Configuration(logger: { config in
    if case .error(let error) = config.message {
        // Report to your error tracking service
        Analytics.record(error.description)
    }
})
```

## Custom Logger Examples

### Analytics Integration

Send navigation events to your analytics service:

```swift
let config = Configuration(
    logger: { loggerConfig in
        switch loggerConfig.message {
        case .navigation(let from, let to, let type):
            Analytics.track("navigation", properties: [
                "from": from.name,
                "to": to.name,
                "type": "\(type)"
            ])
        default:
            break
        }
    },
    shouldCrashOnRouteNotFound: false
)
```

### Debug Logging

Detailed logging for development:

```swift
let config = Configuration(
    logger: { loggerConfig in
        let routerId = loggerConfig.router.id.uuidString.prefix(8)
        
        switch loggerConfig.message {
        case .create(let from, _):
            if let parent = from {
                print("🆕 [\(routerId)] Created from \(parent)")
            } else {
                print("🆕 [\(routerId)] Root router created")
            }
            
        case .delete:
            print("🗑️ [\(routerId)] Deallocated")
            
        case .navigation(let from, let to, let type):
            print("🧭 [\(routerId)] \(from.name) → \(to.name) (\(type))")
            
        case .action(let action):
            print("⚡ [\(routerId)] Action: \(action)")
            
        case .context(let context):
            print("📦 [\(routerId)] Context: \(context)")
            
        case .onAppear(let route):
            print("👁️ [\(routerId)] Appear: \(route.name)")
            
        case .onDisappear(let route):
            print("👁️‍🗨️ [\(routerId)] Disappear: \(route.name)")
        }
    },
    shouldCrashOnRouteNotFound: true
)
```

### Filtered Logging

Log only specific events:

```swift
let config = Configuration(
    logger: { loggerConfig in
        switch loggerConfig.message {
        case .navigation, .action:
            LoggerConfiguration.default(loggerConfiguration: loggerConfig)
        default:
            break
        }
    },
    shouldCrashOnRouteNotFound: false
)
```

### Disable Logging

To disable logging entirely, pass `nil`:

```swift
let config = Configuration(
    logger: nil,
    shouldCrashOnRouteNotFound: false
)
```

## Environment-Based Configuration

Use different configurations for debug and release builds:

```swift
extension Configuration {
    static var app: Configuration {
        #if DEBUG
        Configuration(
            logger: { config in
                print("🧭 \(config.message)")
            },
            shouldCrashOnRouteNotFound: true
        )
        #else
        Configuration(
            logger: nil,
            shouldCrashOnRouteNotFound: false
        )
        #endif
    }
}

// Usage
Router(configuration: .app)
```

## Topics

### Related

- ``LoggerConfiguration``
- ``LoggerMessage``
- ``Router``
