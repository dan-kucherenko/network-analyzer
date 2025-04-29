import SwiftSyntax

class DataCachingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "urlCache": PropertyImpact(),
        "requestCachePolicy": PropertyImpact()
    ]
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                
                if properties.keys.contains(property),
                   let propertyImpact = properties[property] {
                    propertyImpact.found = true

                    if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
                        propertyImpact.value = booleanLiteral.literal.text
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
                    } else if property == "urlCache" || property == "requestCachePolicy" {
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
                    }
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let property = node.declName.baseName.text
        if properties.keys.contains(property) {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            let propertyImpact = properties[property]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.location.append((line: location.line, column: location.column))
        }
        return .visitChildren
    }
}
