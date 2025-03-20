import SwiftSyntax

class HttpVisitor: SyntaxVisitor {
    struct PropertyImpact {
        var found: Bool = false
        var value: String?
        var hasNetworkImpact: Bool = false
        
        var description: String {
            return "Found: \(found), Value: \(value), Network Impact: \(hasNetworkImpact)"
        }
    }
    
    private var properties: [String: PropertyImpact] = [
        "httpAdditionalHeaders": PropertyImpact(),
        "httpShouldSetCookies": PropertyImpact(),
        "httpCookieAcceptPolicy": PropertyImpact(),
        "httpShouldUsePipelining": PropertyImpact()
    ]

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if ((node.base?.as(DeclReferenceExprSyntax.self)) != nil) {
            let property = node.declName.baseName.text
            if properties.keys.contains(property) {
                properties[property]?.found = true
            }
        }
        return .visitChildren
    }
    
    //    override func visit(_ node: InfixOperatorExprSyntax) -> SyntaxVisitorContinueKind {
    //        if let assignExpr = element.as(InfixOperatorExprSyntax.self),
    //           let memberAccess = assignExpr.leftOperand.as(MemberAccessExprSyntax.self) {
    //            let property = memberAccess.declName.baseName.text
    //
    //            if properties.keys.contains(property),
    //               let propertyImpact = properties[property] {
    //                propertyImpact.found = true
    //
    //                if let booleanLiteral = assignExpr.rightOperand.as(BooleanLiteralExprSyntax.self) {
    //                    let boolValue = booleanLiteral.literal.text == "true"
    //                    propertyImpact.value = "Test Bool"
    //                    print("Sequence Syntax visitor")
    //
    //                    switch property {
    //                    case "httpShouldSetCookies":
    //                        propertyImpact.hasNetworkImpact = boolValue
    //                    case "httpShouldUsePipelining":
    //                        propertyImpact.hasNetworkImpact = !boolValue
    //                    default:
    //                        break
    //                    }
    //                } else if let enumCaseExpr = assignExpr.rightOperand.as(MemberAccessExprSyntax.self) {
    //                    let enumCase = enumCaseExpr.declName.baseName.text
    //
    //                    if property == "httpCookieAcceptPolicy" {
    //                        propertyImpact.value = enumCase
    //                        propertyImpact.hasNetworkImpact = true
    //                    }
    //                } else if property == "httpAdditionalHeaders" {
    //                    propertyImpact.hasNetworkImpact = true
    //                }
    //            }
    //        }
    //        return .visitChildren
    //    }
    
    func getPropertyStatus(for property: String) -> PropertyImpact? {
        return properties[property]
    }
    
    var hasNetworkImpactingConfigurations: Bool {
        return properties.values.contains { $0.hasNetworkImpact }
    }
    
    func getImpactingSummary() -> [String] {
        return properties
            .compactMap { property, impactInfo -> String? in
                "Property: \(property), impact info: \n\(impactInfo.description)"
            }
    }
}
