import SwiftSyntax

class HttpVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "httpAdditionalHeaders",
        "httpShouldSetCookies",
        "httpCookieAcceptPolicy",
        "httpShouldUsePipelining"
    ]
    var warnings: [XcodeDiagnostic] = []
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self),
           let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
            let property = memberAccessNode.declName.baseName.text
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            
            if properties.contains(property) {
                switch property {
                case "httpShouldSetCookies":
                    handleCookieSettingAssignment(parentNode: parentNode, location: location)
                case "httpShouldUsePipelining":
                    handlePipeliningAssignment(parentNode: parentNode, location: location)
                case "httpCookieAcceptPolicy":
                    handleCookiePolicyAssignment(parentNode: parentNode, location: location)
                case "httpAdditionalHeaders":
                    handleAdditionalHeadersAssignment(location: location)
                default:
                    break
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
                handlePropertyAccess(property: property, location: location)
            }
        }
        return .visitChildren
    }
}

private extension HttpVisitor {
    func handleCookieSettingAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            let boolValue = booleanLiteral.literal.text == "true"
            if boolValue {
                warnings.append(XcodeDiagnostic(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider disabling cookie handling by setting httpShouldSetCookies to false if not required for your API calls. Current value is: true"
                ))
            }
        }
    }
    
    func handlePipeliningAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            let boolValue = booleanLiteral.literal.text == "true"
            if !boolValue {
                warnings.append(XcodeDiagnostic(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider enabling HTTP pipelining by setting httpShouldUsePipelining to true for better performance. Current value is: false"
                ))
            }
        }
    }
    
    func handleCookiePolicyAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
            let enumCase = enumCaseExpr.declName.baseName.text
            if enumCase != "onlyFromMainDocumentDomain" {
                warnings.append(XcodeDiagnostic(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider using .onlyFromMainDocumentDomain policy for cookie acceptance to accept only needed cookies from the main document domain. Current policy: \(enumCase)"
                ))
            }
        }
    }
    
    func handleAdditionalHeadersAssignment(location: SourceLocation) {
        warnings.append(XcodeDiagnostic(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: "Review and optimize additional headers to include only necessary ones for your API calls. Unnecessary headers increase request size and processing overhead."
        ))
    }
    
    private func handlePropertyAccess(property: String, location: SourceLocation) {
        let message = switch property {
        case "httpAdditionalHeaders":
            "Additional headers are being accessed. Make sure to include only necessary headers for optimal performance."
        case "httpShouldSetCookies":
            "Cookie setting property is being accessed. Consider disabling cookie handling if not required for your API calls."
        case "httpCookieAcceptPolicy":
            "Cookie acceptance policy is being accessed. Consider using .onlyFromMainDocumentDomain policy for better security."
        case "httpShouldUsePipelining":
            "HTTP pipelining property is being accessed. Consider enabling pipelining for better performance."
        default:
            "HTTP property '\(property)' is being accessed. Review its configuration for optimal network performance."
        }
        
        warnings.append(XcodeDiagnostic(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: message
        ))
    }
}
