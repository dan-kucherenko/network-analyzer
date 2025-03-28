import ArgumentParser
import Foundation
import SwiftUI
import SwiftSyntax
import SwiftParser
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

        let manager = URLVisitorManager(filePath: inputFile, outputPath: outputPath ?? "")
        
        let results = manager.analyzeSyntaxTree(syntaxTree)

        if let outputPath {
            try results.joined(separator: "\n---\n").write(toFile: outputPath, atomically: true, encoding: .utf8)
        } else {
            print(results.joined(separator: "\n---\n"))
        }
    }
}
