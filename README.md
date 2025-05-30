# Network Analyzer

A static analysis tool for detecting network-related anti-patterns in iOS applications. The tool analyzes Swift source code to identify potential issues with network usage, caching, lifecycle management, and push notifications.

## Features

- Static analysis of Swift source code
- Detection of network-related anti-patterns
- Support for command-line and build tool pluginusage
- Detailed recommendations for fixing detected issues

## Installation

### Swift Package Manager

Add the following dependency to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/yourusername/network-analyzer.git", from: "1.0.0")
]
```

### Build Tool Plugin

1. Add the plugin to your target in `Package.swift`:

```swift
targets: [
    .target(
        name: "YourTarget",
        plugins: [
            .plugin(name: "NetworkAnalyzerPlugin", package: "network-analyzer")
        ]
    )
]
```

2. The plugin will automatically run during the build process and show warnings in Xcode's issue navigator.

### Command Line

You can run the analyzer directly from the command line:

```bash
swift run network-analyzer -i /path/to/your/file.swift
```

Options:

- `-i, --input-file`: Path to the input file to analyze (required)
- `-o, --output-path`: Path to the output file (optional)

## Usage

### Build Tool Plugin

The plugin will automatically analyze your source files during the build process. Warnings will appear in:

- Xcode's issue navigator
- Build log
- Inline in your source code

### Command Line

```bash
# Analyze a single file
swift run network-analyzer -i /path/to/your/file.swift

# Analyze a file and save output
swift run network-analyzer -i /path/to/your/file.swift -o /path/to/output.txt
```

## Anti-Patterns Detected

### URL Configuration

- Extremely short timeout intervals
- Cellular access without checks
- Video network service for non-video content
- Disabled connectivity waiting
- Excessive connections per host
- Expensive network access enabled
- Launch events enabled
- Aggregate multipath service type

### Caching

- Zero-capacity URLCache
- ReloadIgnoringCacheData policy
- ReturnCacheDataDontLoad request policy

### HTTP Configuration

- Hardcoded cookies in headers
- Cookie acceptance policy set to always
- HTTP pipelining enabled

### Polling

- Frequent timer-based polling
- Recursive dispatch polling with asyncAfter
- Infinite loop with Thread.sleep

### Lifecycle

- Heavy network operations in applicationDidEnterBackground
- No pause/stop operations in applicationWillResignActive
- Network operations in background state

### Notifications

- content-available flag set to 1
- Heavy processing in didReceiveRemoteNotification without calling completion handler
- No proper background fetch handling

## Example Project

The example project includes:

- AppDelegate with lifecycle anti-patterns
- NetworkManager with URL configuration anti-patterns
- Polling implementation with various anti-patterns
- Push notification handling with anti-patterns

## Acknowledgments

- [SwiftSyntax](https://github.com/apple/swift-syntax) for providing the Swift source code parsing capabilities
- [ArgumentParser](https://github.com/apple/swift-argument-parser) for command-line argument parsing
