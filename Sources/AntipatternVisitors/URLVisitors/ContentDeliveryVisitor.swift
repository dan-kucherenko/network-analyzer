import SwiftSyntax

class ContentDeliveryVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "httpMaximumConnectionsPerHost",
        "allowsExpensiveNetworkAccess"
    ]
    var warnings: [AntipatternWarning] = []
    
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

                if properties.contains(property) {
                    if let intLiteral = parentNode.last?.as(IntegerLiteralExprSyntax.self),
                       property == "httpMaximumConnectionsPerHost" {
                        let connections = Int(intLiteral.literal.text) ?? 0
                        if connections > 6 {
                            warnings.append(AntipatternWarning(
                                filePath: filePath,
                                line: location.line,
                                column: location.column,
                                message: "Consider setting a more appropriate value for httpMaximumConnectionsPerHost. Default value is 6 for cellular and 4 for wifi. Current value is: \(connections)"
                            ))
                        }
                    } else if let boolLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self),
                              property == "allowsExpensiveNetworkAccess" {
                        if boolLiteral.literal.text == "true" {
                            warnings.append(AntipatternWarning(
                                filePath: filePath,
                                line: location.line,
                                column: location.column,
                                message: "Consider setting allowsExpensiveNetworkAccess to false if your app does not require access to expensive networks. Current value is: true"
                            ))
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
            if properties.contains(property) {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Content delivery property '\(property)' is being accessed. Make sure to set appropriate values for optimal network performance."
                ))
            }
        }
        return .visitChildren
    }
}
