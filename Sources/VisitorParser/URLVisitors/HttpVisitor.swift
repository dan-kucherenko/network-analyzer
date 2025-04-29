import SwiftSyntax

class HttpVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "httpAdditionalHeaders": PropertyImpact(),
        "httpShouldSetCookies": PropertyImpact(),
        "httpCookieAcceptPolicy": PropertyImpact(),
        "httpShouldUsePipelining": PropertyImpact()
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
                        let boolValue = booleanLiteral.literal.text == "true"
                        propertyImpact.value = booleanLiteral.literal.text
                        
                        switch property {
                        case "httpShouldSetCookies":
                            propertyImpact.hasNetworkImpact = boolValue
                            propertyImpact.location.append((line: location.line, column: location.column))
                        case "httpShouldUsePipelining":
                            propertyImpact.hasNetworkImpact = !boolValue
                            propertyImpact.location.append((line: location.line, column: location.column))
                        default:
                            break
                        }
                    } else if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let enumCase = enumCaseExpr.declName.baseName.text
                        
                        if property == "httpCookieAcceptPolicy" {
                            propertyImpact.value = enumCase
                            propertyImpact.hasNetworkImpact = (enumCase.elementsEqual("never")) ? false : true
                            propertyImpact.location.append((line: location.line, column: location.column))
                        }
                    } else if property == "httpAdditionalHeaders" {
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
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
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                let propertyImpact = properties[property]
                propertyImpact?.found = true
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }
        return .visitChildren
    }
}
