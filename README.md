# Network Analyzer

A Swift-based network analysis tool that helps developers analyze and understand their code structure in order to find places that may impact the network usage of the mobile app

## Requirements

- macOS 15.0 or later
- Swift 6.0 or later

## Installation

1. Clone the repository:

```bash
git clone https://github.com/dan-kucherenko/network-analyzer.git
cd network-analyzer
```

2. Build the project:

```bash
swift build
```

## Usage

After building the project, you can run the analyzer using:

```bash
.build/debug/network-analyzer -i <input_file_path> -o <output_file_path>
```

Or for release builds:

```bash
.build/release/network-analyzer -i <input_file_path> -o <output_file_path>
```

### Command Line Options

- `-i, --input-file <path>` : Path to the input Swift file you want to analyze
- `-o, --output-path <path>` : (Optional) Path where the analysis results will be saved. If not provided, results will be printed to the console

### Analysis Output

The tool performs multiple types of analysis on your code:

1. URL Analysis - Detects URL-related patterns and potential issues
2. Polling Analysis - Identifies polling mechanisms and their implementation
3. Lifecycle Analysis - Analyzes network-related lifecycle management
4. Caching Analysis - Examines caching strategies and implementations
5. Notification Analysis - Reviews notification patterns related to networking

## Dependencies

The project uses Swift Package Manager for dependency management. The main dependencies are:

- [SwiftSyntax](https://github.com/swiftlang/swift-syntax) (v600.0.1 or later) - For Swift code parsing and analysis
- [Swift DocC SymbolKit](https://github.com/apple/swift-docc-symbolkit) - For symbol processing
- [Swift Argument Parser](https://github.com/apple/swift-argument-parser) (v1.3.0 or later) - For command-line argument parsing
