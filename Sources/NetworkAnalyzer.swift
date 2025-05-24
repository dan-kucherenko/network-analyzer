import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax

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

        let services: [VisitableService] = [
            URLVisitorService(filePath: inputFile, outputPath: outputPath ?? ""),
            PollingVisitorService(filePath: inputFile, outputPath: outputPath ?? ""),
            LifecycleVisitorService(filePath: inputFile, outputPath: outputPath ?? ""),
            CachingVisitorService(filePath: inputFile, outputPath: outputPath ?? ""),
            NotificationVisitorService(filePath: inputFile, outputPath: outputPath ?? "")
        ]

        let diagnostics = services.flatMap { $0.analyzeSyntaxTree(syntaxTree) }
        let formattedDiagnostics = diagnostics.map { $0.format() }.joined(separator: "\n")
        print(formattedDiagnostics)
    }
}
