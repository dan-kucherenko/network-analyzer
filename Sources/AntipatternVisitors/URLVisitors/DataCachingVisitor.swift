import SwiftSyntax

class DataCachingVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "urlCache",
        "requestCachePolicy"
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
                case "urlCache":
                    handleURLCacheAssignment(parentNode: parentNode, location: location)
                case "requestCachePolicy":
                    handleRequestCachePolicyAssignment(parentNode: parentNode, location: location)
                default:
                    break
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let property = node.declName.baseName.text
        if properties.contains(property) {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            
            switch property {
            case "urlCache":
                handleURLCacheAccess(location: location)
            case "requestCachePolicy":
                handleRequestCachePolicyAccess(node: node, location: location)
            default:
                break
            }
        }
        return .visitChildren
    }
}

private extension DataCachingVisitor {
    func handleURLCacheAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Consider implementing a custom URLCache with appropriate memory and disk capacity limits for your app's needs. This will help manage memory usage and improve performance. Current value is: \(booleanLiteral.literal.text)"
            ))
        } else if let sharedAccess = parentNode.last?.as(MemberAccessExprSyntax.self),
                  sharedAccess.declName.baseName.text == "shared" {
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Using shared URLCache. Consider implementing a custom URLCache with appropriate memory and disk capacity limits. The default shared cache might not be optimal for your app's specific needs."
            ))
        } else {
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Custom URLCache configuration detected. Make sure to set appropriate memory and disk capacity limits."
            ))
        }
    }
    
    func handleRequestCachePolicyAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let policyAccess = parentNode.last?.as(MemberAccessExprSyntax.self) {
            let policyName = policyAccess.declName.baseName.text
            let recommendation = getCachePolicyRecommendation(policyName: policyName)
            
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: recommendation
            ))
        }
    }
    
    func handleURLCacheAccess(location: SourceLocation) {
        warnings.append(XcodeDiagnostic(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: "URLCache property is being accessed. Consider implementing a custom URLCache with appropriate memory and disk capacity limits."
        ))
    }
    
    func handleRequestCachePolicyAccess(node: MemberAccessExprSyntax, location: SourceLocation) {
        if let parent = node.parent?.as(InfixOperatorExprSyntax.self),
           let right = parent.rightOperand.as(MemberAccessExprSyntax.self) {
            let policyName = right.declName.baseName.text
            let recommendation = getCachePolicyRecommendation(policyName: policyName)
            
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: recommendation
            ))
        }
    }
    
    func getCachePolicyRecommendation(policyName: String) -> String {
        return switch policyName {
        case "returnCacheDataDontLoad":
            "Using .returnCacheDataDontLoad may result in stale data. Make sure this is intended for your use case."
        case "reloadIgnoringCacheData":
            "Using .reloadIgnoringCacheData will always fetch from the network, which may increase data usage and reduce performance. Use only if fresh data is critical."
        default:
            ""
        }
    }
}
