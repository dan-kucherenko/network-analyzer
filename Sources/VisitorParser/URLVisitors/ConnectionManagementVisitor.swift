import SwiftSyntax

class ConnectionVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "allowsCellularAccess": PropertyImpact(),
        "networkServiceType": PropertyImpact(),
        "waitsForConnectivity": PropertyImpact()
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
                        case "allowsCellularAccess":
                            propertyImpact.hasNetworkImpact = !boolValue
                            propertyImpact.location.append((line: location.line, column: location.column))
                            propertyImpact.recommendation = "Consider setting allowsCellularAccess to false if your app does not require access to cellular networks"
                        case "waitsForConnectivity":
                            propertyImpact.hasNetworkImpact = !boolValue
                            propertyImpact.location.append((line: location.line, column: location.column))
                            propertyImpact.recommendation = "Consider setting waitsForConnectivity to true for better app performance"
                        default:
                            break
                        }
                    }
                    
                    else if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let enumCase = enumCaseExpr.declName.baseName.text
                        if property == "networkServiceType" {
                            propertyImpact.value = enumCase
                            propertyImpact.hasNetworkImpact = (enumCase != "background" || enumCase != "default")
                            propertyImpact.location.append((line: location.line, column: location.column))
                            propertyImpact.recommendation = "Check the usage of networkServiceType. Default value is 'default'. .video, .voice, .responsiveData, .avStreaming may impact the network if not needed"
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
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                let propertyImpact = properties[property]
                propertyImpact?.found = true
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }
        return .visitChildren
    }
}
