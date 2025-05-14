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
                            propertyImpact.recommendation = "Consider disabling cookie handling by setting httpShouldSetCookies to false if not required for your API calls."
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
                            propertyImpact.recommendation = "Consider using .onlyFromMainDocumentDomain policy for cookie acceptance to accept only needed cookies from the main document domain."
                        }
                    } else if property == "httpAdditionalHeaders" {
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
                        propertyImpact.recommendation = "Review and optimize additional headers to include only necessary ones for your API calls. Unnecessary headers increase request size and processing overhead."
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
