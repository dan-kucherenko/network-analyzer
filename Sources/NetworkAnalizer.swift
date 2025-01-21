import ArgumentParser
import Foundation

@main
struct NetworkAnalizer: ParsableCommand {
    static let configuration = CommandConfiguration(abstract: "Networking Code Analizer", version: "0.0.1")
    
    @Option(name: .short, help: "The path to the file to analyze")
    var inputFile: String
    
    @Option(name: .short, help: "The path to the output file")
    var outputPath: String?
    
    mutating func validate() throws {
        let path = URL(fileURLWithPath: inputFile)
        
        if !FileManager.default.fileExists(atPath: path.path) {
            throw ValidationError("The input file path: '\(inputFile)' is not a valid")
        }
    }
        
    mutating func run() throws {
        print("Hello, world!")
    }
}
