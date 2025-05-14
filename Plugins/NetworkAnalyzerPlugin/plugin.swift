import PackagePlugin
import Foundation

@main
struct NetworkAnalyzerPlugin: BuildToolPlugin { 
    func createBuildCommands(
        context: PluginContext,
        target: Target
    ) throws -> [Command] {
        // Only process source module targets
        guard let target = target as? SourceModuleTarget else {
            return []
        }
        
        // Get all Swift source files
        let swiftFiles = target.sourceFiles(withSuffix: "swift")
        
        // Create a command for each Swift file
        return try swiftFiles.map {
            let inputPath = $0.url
            
            return .buildCommand(
                displayName: "Analyzing network usage in \(inputPath.lastPathComponent)",
                executable: try context.tool(named: "network-analyzer").url,
                arguments: [
                    "-i", inputPath.path
                ],
                inputFiles: [inputPath.standardizedFileURL],
            )
        }
    }
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension NetworkAnalyzerPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(
        context: XcodePluginContext,
        target: XcodeTarget
    ) throws -> [Command] {
        let swiftFiles = target.inputFiles.filter { $0.url.pathExtension == "swift" }
        
        return try swiftFiles.map {
            let inputPath = $0.url
            
            return .buildCommand(
                displayName: "Analyzing network usage in \(inputPath.lastPathComponent)",
                executable: try context.tool(named: "network-analyzer").url,
                arguments: [
                    "-i", inputPath.path
                ],
                inputFiles: [inputPath.standardizedFileURL]
            )
        }
    }
}
#endif
