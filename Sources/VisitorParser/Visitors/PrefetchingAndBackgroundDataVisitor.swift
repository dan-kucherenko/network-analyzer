import SwiftSyntax

class PrefetchingAndBackgroundDataVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "sessionSendsLaunchEvents": PropertyImpact(),
        "multipathServiceType": PropertyImpact()
    ]
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text
                
                if properties.keys.contains(property),
                   let propertyImpact = properties[property] {
                    propertyImpact.found = true

                    if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
                        let boolValue = booleanLiteral.literal.text == "true"
                        propertyImpact.value = booleanLiteral.literal.text
                        
                        switch property {
                        case "sessionSendsLaunchEvents":
                            propertyImpact.hasNetworkImpact = boolValue
                        default:
                            break
                        }
                    } else if let stringLiteral = parentNode.last?.as(StringLiteralExprSyntax.self) {
                        if let stringSegment = stringLiteral.segments.first as? StringSegmentSyntax? {
                            propertyImpact.value = stringSegment?.content.text
                            propertyImpact.hasNetworkImpact = true
                        }
                    } else if property == "multipathServiceType" {
                        if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
                            propertyImpact.value = enumCaseExpr.declName.baseName.text
                            propertyImpact.hasNetworkImpact = true
                        }
                    }
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
