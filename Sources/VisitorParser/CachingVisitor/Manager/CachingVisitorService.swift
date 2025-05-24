import SwiftSyntax

class CachingVisitorService {
    private let filePath: String
    private let outputPath: String
    let visitors: [Visitable]

    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        visitors = [
            CachingPolicyVisitor(filePath: filePath),
        ]
    }

    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [XcodeDiagnostic] {
        visitors.flatMap { visitor in
            visitor.walk(tree)
            return visitor.warnings
        }
    }
}
