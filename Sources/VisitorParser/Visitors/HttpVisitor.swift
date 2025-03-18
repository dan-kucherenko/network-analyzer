import SwiftSyntax

class HttpVisitor: SyntaxVisitor {
    struct PropertyImpact {
        var found: Bool = false
        var value: Any? = nil
        var hasNetworkImpact: Bool = false
    }
    
    private var properties: [String: PropertyImpact] = [
        "httpAdditionalHeaders": PropertyImpact(),
        "httpShouldSetCookies": PropertyImpact(),
        "httpCookieAcceptPolicy": PropertyImpact(),
        "httpShouldUsePipelining": PropertyImpact()
    ]

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let baseExpr = node.base?.as(DeclReferenceExprSyntax.self) {
            let property = node.declName.baseName.text
            if properties.keys.contains(property) {
                properties[property]?.found = true
            }
        }
        return .visitChildren
    }

    override func visit(_ node: SequenceExprSyntax) -> SyntaxVisitorContinueKind {
        for element in node.elements {
            if let assignExpr = element.as(InfixOperatorExprSyntax.self),
               let memberAccess = assignExpr.leftOperand.as(MemberAccessExprSyntax.self) {
                let property = memberAccess.declName.baseName.text
                
                if properties.keys.contains(property) {
                    properties[property]?.found = true
                    
                    if let booleanLiteral = assignExpr.rightOperand.as(BooleanLiteralExprSyntax.self) {
                        let boolValue = booleanLiteral.literal.text == "true"
                        properties[property]?.value = boolValue
                        
                        switch property {
                        case "httpShouldSetCookies":
                            properties[property]?.hasNetworkImpact = boolValue
                        case "httpShouldUsePipelining":
                            properties[property]?.hasNetworkImpact = !boolValue
                        default:
                            break
                        }
                    } else if let enumCaseExpr = assignExpr.rightOperand.as(MemberAccessExprSyntax.self) {
                        let enumCase = enumCaseExpr.declName.baseName.text
                        
                        if property == "httpCookieAcceptPolicy" {
                            properties[property]?.value = enumCase
                            properties[property]?.hasNetworkImpact = true
                        }
                    } else if property == "httpAdditionalHeaders" {
                        properties[property]?.hasNetworkImpact = true
                    }
                }
            }
        }
        return .visitChildren
    }
    
    func getPropertyStatus(for property: String) -> PropertyImpact? {
        return properties[property]
    }
    
    var hasNetworkImpactingConfigurations: Bool {
        return properties.values.contains { $0.hasNetworkImpact }
    }
    
    func getImpactingSummary() -> [(String, String)] {
        return properties.compactMap { property, impact -> (String, String)? in
            guard impact.found else { return nil }
            
            var message: String
            switch property {
            case "httpAdditionalHeaders":
                message = "Custom headers may increase request size"
            case "httpShouldSetCookies":
                message = impact.value as? Bool == true ? "Cookies enabled, may increase traffic" : "Cookies disabled"
            case "httpShouldUsePipelining":
                message = impact.value as? Bool == true ? "Pipelining enabled (optimized)" : "Pipelining disabled"
            case "httpCookieAcceptPolicy":
                message = "Cookie policy configuration found"
            default:
                message = "Configuration found"
            }
            return (property, message)
        }
    }
}
