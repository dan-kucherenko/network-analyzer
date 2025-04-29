import ArgumentParser
import Foundation
import SwiftParser
import SwiftSyntax
import SwiftUI
import SymbolKit

struct XcodeDiagnostic {
    let filePath: String
    let line: Int
    let column: Int
    let message: String
    let type: DiagnosticType
    
    enum DiagnosticType: String {
        case warning = "warning"
        case error = "error"
    }
    
    func format() -> String {
        return "\(filePath):\(line):\(column): \(type.rawValue): \(message)"
    }
}

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

        let urlManager = URLVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let pollingManager = PollingVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let lifecycleManager = LifecycleVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let cachingManager = CachingVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        let notificationManager = NotificationVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")

        var diagnostics: [XcodeDiagnostic] = []
        
        // Convert PropertyImpact results to Xcode diagnostics
        func processDiagnostics(_ impacts: [PropertyImpact], category: String) {
            impacts.forEach { impact in
                guard let message = impact.value else { return }
                
                // Create a diagnostic for each location where the issue was found
                impact.location.forEach { location in
                    diagnostics.append(XcodeDiagnostic(
                        filePath: inputFile,
                        line: location.line,
                        column: location.column,
                        message: "[\(category)] \(message)",
                        type: .warning
                    ))
                }
            }
        }

        // Process results from each visitor
        let categories: [([PropertyImpact], String)] = [
            (urlManager.analyzeSyntaxTree(syntaxTree), "URL Usage"),
            (pollingManager.analyzeSyntaxTree(syntaxTree), "Polling"),
            (lifecycleManager.analyzeSyntaxTree(syntaxTree), "Lifecycle"),
            (cachingManager.analyzeSyntaxTree(syntaxTree), "Caching"),
            (notificationManager.analyzeSyntaxTree(syntaxTree), "Notifications")
        ]
        
        for (results, category) in categories {
            processDiagnostics(results, category: category)
        }

        let formattedDiagnostics = diagnostics.map { $0.format() }.joined(separator: "\n")
        
        if let outputPath = outputPath {
            try formattedDiagnostics.write(toFile: outputPath, atomically: true, encoding: .utf8)
        } else {
            print(formattedDiagnostics)
        }
    }
}
