import SwiftSyntax

class VisitorManager {
    private let filePath: String
    private let outputPath: String
    let visitors: [Visitable]
    
    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        self.visitors = [
            HttpVisitor(viewMode: .all),
            ConnectionVisitor(viewMode: .all),
            ContentDeliveryVisitor(viewMode: .all)
        ]
    }
    
    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [String] {
        visitors.map { visitor in
            visitor.walk(tree)
            return visitor.getImpactingSummary(properties: visitor.properties)
        }.flatMap { $0 }
    }
}
