import SwiftSyntax

class HttpVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "httpAdditionalHeaders": PropertyImpact(),
        "httpShouldSetCookies": PropertyImpact(),
        "httpCookieAcceptPolicy": PropertyImpact(),
        "httpShouldUsePipelining": PropertyImpact()
    ]
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text
                
                if properties.keys.contains(property),
                   var propertyImpact = properties[property] {
                    propertyImpact.found = true

                    if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
                        let boolValue = booleanLiteral.literal.text == "true"
                        propertyImpact.value = booleanLiteral.literal.text
                        
                        switch property {
                        case "httpShouldSetCookies":
                            propertyImpact.hasNetworkImpact = boolValue
                        case "httpShouldUsePipelining":
                            propertyImpact.hasNetworkImpact = !boolValue
                        default:
                            break
                        }
                    } else if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let enumCase = enumCaseExpr.declName.baseName.text
                        
                        if property == "httpCookieAcceptPolicy" {
                            propertyImpact.value = enumCase
                            propertyImpact.hasNetworkImpact = (enumCase.elementsEqual("never")) ? false : true
                        }
                    } else if property == "httpAdditionalHeaders" {
                        propertyImpact.hasNetworkImpact = true
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
