import SwiftSyntax

class ContentDeliveryVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "httpMaximumConnectionsPerHost": PropertyImpact(),
        "allowsExpensiveNetworkAccess": PropertyImpact()
    ]

    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text

                if properties.keys.contains(property),
                   var propertyImpact = properties[property] {
                    propertyImpact.found = true

                    if let intLiteral = parentNode.last?.as(IntegerLiteralExprSyntax.self),
                       property == "httpMaximumConnectionsPerHost" {
                        propertyImpact.value = intLiteral.literal.text
                        propertyImpact.hasNetworkImpact = (Int(intLiteral.literal.text) ?? 0) > 6
                    } else if let boolLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self),
                              property == "allowsExpensiveNetworkAccess" {
                        propertyImpact.value = boolLiteral.literal.text
                        propertyImpact.hasNetworkImpact = boolLiteral.literal.text == "true"
                    }

                    properties[property] = propertyImpact
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if ((node.base?.as(DeclReferenceExprSyntax.self)) != nil) {
            let property = node.declName.baseName.text
            if properties.keys.contains(property) {
                properties[property]?.found = true
            }
        }
        return .visitChildren
    }
}
