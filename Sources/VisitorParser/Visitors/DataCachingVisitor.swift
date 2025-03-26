import SwiftSyntax

class DataCachingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "urlCache": PropertyImpact(),
        "requestCachePolicy": PropertyImpact()
    ]
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text
                
                if properties.keys.contains(property),
                   let propertyImpact = properties[property] {
                    propertyImpact.found = true

                    if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
                        propertyImpact.value = booleanLiteral.literal.text
                        
                        propertyImpact.hasNetworkImpact = true
                    } else if property == "urlCache" || property == "requestCachePolicy" {
                        propertyImpact.hasNetworkImpact = true
                    }
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let property = node.declName.baseName.text
        if properties.keys.contains(property) {
            properties[property]?.found = true
            properties[property]?.hasNetworkImpact = true
        }
        return .visitChildren
    }
}
