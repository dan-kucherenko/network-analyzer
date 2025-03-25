import SwiftSyntax

class ConnectionVisitor: SyntaxVisitor, Visitable {
    private var properties: [String: PropertyImpact] = [
        "allowsCellularAccess": PropertyImpact(),
        "networkServiceType": PropertyImpact(),
        "waitsForConnectivity": PropertyImpact()
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
                        case "allowsCellularAccess":
                            propertyImpact.hasNetworkImpact = !boolValue
                        case "waitsForConnectivity":
                            propertyImpact.hasNetworkImpact = boolValue
                        default:
                            break
                        }
                    }
                    
                    else if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let enumCase = enumCaseExpr.declName.baseName.text
                        if property == "networkServiceType" {
                            propertyImpact.value = enumCase
                            propertyImpact.hasNetworkImpact = (enumCase != "background")
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
    
    func getImpactingSummary() -> [String] {
        return properties.compactMap { property, impactInfo -> String? in
            "Property: \(property), impact info: \n\(impactInfo.description)"
        }
    }
}
