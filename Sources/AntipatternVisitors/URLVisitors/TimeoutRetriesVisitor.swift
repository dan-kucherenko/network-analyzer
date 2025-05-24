import SwiftSyntax

class TimeoutAndRetryVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "timeoutIntervalForRequest",
        "timeoutIntervalForResource"
    ]
    var warnings: [XcodeDiagnostic] = []
    
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
                
                if properties.contains(property),
                   let numberLiteral = parentNode.last?.as(IntegerLiteralExprSyntax.self) {
                    let timeoutValue = Int(numberLiteral.literal.text)
                    
                    switch property {
                    case "timeoutIntervalForRequest":
                        if let timeout = timeoutValue, timeout < 30 || timeout > 120 {
                            warnings.append(XcodeDiagnostic(
                                filePath: filePath,
                                line: location.line,
                                column: location.column,
                                message: "Consider setting a more appropriate timeout value between 30 and 120 seconds. Property controls how long (in seconds) a task should wait for additional data. Default value is 60 seconds. Current value is: \(timeout) seconds"
                            ))
                        }
                    case "timeoutIntervalForResource":
                        if let timeout = timeoutValue, timeout < 3600 || timeout > 3600 * 60 * 3 {
                            warnings.append(XcodeDiagnostic(
                                filePath: filePath,
                                line: location.line,
                                column: location.column,
                                message: "Consider setting a more appropriate timeout value between 1 hour and 8 days. Property controls how long (in seconds) to wait for a complete resource to transfer before giving up. Default value is 7 days. Current value is: \(timeout) seconds"
                            ))
                        }
                    default:
                        break
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
                warnings.append(XcodeDiagnostic(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Timeout property '\(property)' is being accessed. Make sure to set appropriate timeout values."
                ))
            }
        }
        return .visitChildren
    }
}
