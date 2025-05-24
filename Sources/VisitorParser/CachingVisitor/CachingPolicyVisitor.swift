import SwiftSyntax

class CachingPolicyVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "urlCacheConfig",
        "cachePolicy"
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
                let modifier = parentNode.last?.as(MemberAccessExprSyntax.self)
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                
                if property == "urlCache" {
                    detectUrlCache(node: modifier, at: location)
                }
                
                if property == "requestCachePolicy" {
                    detectRequestCachePolicy(node: modifier, at: location)
                }
            }
        }
        
        return .visitChildren
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let type = node.calledExpression.as(DeclReferenceExprSyntax.self),
           type.baseName.text == "URLCache" {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Custom URLCache initialized. Make sure to set appropriate memory and disk capacity limits."
            ))
        }
        
        return .visitChildren
    }
}

private extension CachingPolicyVisitor {
    func detectUrlCache(node: MemberAccessExprSyntax?, at location: SourceLocation) {
        if node?.declName.baseName.text == "shared" {
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Using URLCache.shared. Consider implementing a custom URLCache with appropriate memory and disk capacity limits for your app's needs."
            ))
        } else {
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Using custom URLCache configuration. Make sure to set appropriate memory and disk capacity limits."
            ))
        }
    }
    
    func detectRequestCachePolicy(node: MemberAccessExprSyntax?, at location: SourceLocation) {
        let policyName = node?.declName.baseName.text
        let recognizedPolicies = [
            "useProtocolCachePolicy",
            "returnCacheDataElseLoad",
            "returnCacheDataDontLoad"
        ]
        
        if recognizedPolicies.contains(policyName ?? "") {
            var recommendation: String = ""
            switch policyName {
            case "useProtocolCachePolicy":
                recommendation = "useProtocolCachePolicy is the default. It uses the protocol cache if available. Consider if this is optimal for your app's needs."
            case "returnCacheDataElseLoad":
                recommendation = "returnCacheDataElseLoad will use the cache if available, otherwise it will load from the server. Good for offline support."
            case "returnCacheDataDontLoad":
                recommendation = "returnCacheDataDontLoad will only use the cache if available, otherwise it will not load from the server. Use with caution to avoid stale data."
            default:
                break
            }
            
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "\(recommendation). Using cache policy: \(policyName)"
            ))
        }
    }
}
