import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftUI
import SymbolKit

@main
struct NetworkAnalyzer: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Networking Code Analyzer", version: "0.0.1")

    @Option(name: .short, help: "Path to the input file to analyze")
    var inputFile: String

    @Option(name: .short, help: "Path to the output file")
    var outputPath: String?

    mutating func run() throws {
        let fileURL = URL(fileURLWithPath: inputFile)
        let fileContent = try String(contentsOf: fileURL, encoding: .utf8)

        let syntaxTree = Parser.parse(source: fileContent)

        // Initialize all managers
        let urlManager = URLVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let pollingManager = PollingVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let lifecycleManager = LifecycleVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let cachingManager = CachingVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")

        let urlResults = urlManager.analyzeSyntaxTree(syntaxTree)
        let pollingResults = pollingManager.analyzeSyntaxTree(syntaxTree)
        let lifecycleResults = lifecycleManager.analyzeSyntaxTree(syntaxTree)
        let cachingResults = cachingManager.analyzeSyntaxTree(syntaxTree)

        var allResults: [String] = []
        allResults.append(contentsOf: urlResults)
        allResults.append("---")
        allResults.append(contentsOf: pollingResults)
        allResults.append("---")
        allResults.append(contentsOf: lifecycleResults)
        allResults.append("---")
        allResults.append(contentsOf: cachingResults)

        let formattedResults = allResults.joined(separator: "\n")
        if let outputPath = outputPath {
            try formattedResults.write(toFile: outputPath, atomically: true, encoding: String.Encoding.utf8)
        } else {
            print(formattedResults)
        }
    }
}
