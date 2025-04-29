import SwiftSyntax

class NotificationVisitorManager {
    private let filePath: String
    private let outputPath: String
    let visitors: [Visitable]

    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        visitors = [
            NotificationHandlingVisitor(filePath: filePath),
        ]
    }

    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [PropertyImpact] {
        visitors.flatMap { visitor in
            visitor.walk(tree)
            return visitor.properties.values.filter { $0.found && $0.hasNetworkImpact }
        }
    }
}
