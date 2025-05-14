import SwiftSyntax

class ContentDeliveryVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "httpMaximumConnectionsPerHost": PropertyImpact(),
        "allowsExpensiveNetworkAccess": PropertyImpact()
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

                    if let intLiteral = parentNode.last?.as(IntegerLiteralExprSyntax.self),
                       property == "httpMaximumConnectionsPerHost" {
                        propertyImpact.value = intLiteral.literal.text
                        propertyImpact.hasNetworkImpact = (Int(intLiteral.literal.text) ?? 0) > 6
                        propertyImpact.location.append((line: location.line, column: location.column))
                        propertyImpact.recommendation = "Consider setting a more appropriate value for httpMaximumConnectionsPerHost. Default value is 6 for cellular and 4 for wifi"
                    } else if let boolLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self),
                              property == "allowsExpensiveNetworkAccess" {
                        propertyImpact.value = boolLiteral.literal.text
                        propertyImpact.hasNetworkImpact = boolLiteral.literal.text == "true"
                        propertyImpact.location.append((line: location.line, column: location.column))
                        propertyImpact.recommendation = "Consider setting allowsExpensiveNetworkAccess to false if your app does not require access to expensive networks"
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
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                let propertyImpact = properties[property]
                propertyImpact?.found = true
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }
        return .visitChildren
    }
}
