import SwiftSyntax

class CachingPolicyVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "urlCacheConfig": PropertyImpact(),
        "cachePolicy": PropertyImpact(),
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

                if property == "urlCache" {
                    let propertyImpact = properties["urlCacheConfig"]
                    propertyImpact?.found = true
                    propertyImpact?.hasNetworkImpact = true

                    if let sharedAccess = parentNode.last?.as(MemberAccessExprSyntax.self),
                       sharedAccess.declName.baseName.text == "shared" {
                        propertyImpact?.recommendation = "Using URLCache.shared"
                    } else {
                        propertyImpact?.recommendation = "Using custom URLCache configuration"
                    }
                    propertyImpact?.location.append((line: location.line, column: location.column))
                }

                if property == "requestCachePolicy" {
                    if let policyAccess = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let policyName = policyAccess.declName.baseName.text
                        let propertyImpact = properties["cachePolicy"]

                        let recognizedPolicies = [
                            "useProtocolCachePolicy",
                            "returnCacheDataElseLoad",
                            "returnCacheDataDontLoad"
                        ]
                        if recognizedPolicies.contains(policyName) {
                            propertyImpact?.found = true
                            propertyImpact?.hasNetworkImpact = true
                            propertyImpact?.value = "Using cache policy: \(policyName)"
                            propertyImpact?.location.append((line: location.line, column: location.column))
                            switch policyName {
                            case "useProtocolCachePolicy":
                                propertyImpact?.recommendation = "UseProtocolCachePolicy is the default. It uses the protocol cache if available. Consider if this is optimal for your app's needs."
                            case "returnCacheDataElseLoad":
                                propertyImpact?.recommendation = "ReturnCacheDataElseLoad will use the cache if available, otherwise it will load from the server. Good for offline support."
                            case "returnCacheDataDontLoad":
                                propertyImpact?.recommendation = "ReturnCacheDataDontLoad will only use the cache if available, otherwise it will not load from the server. Use with caution to avoid stale data."
                            default:
                                break
                            }
                        }
                    }
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let type = node.calledExpression.as(DeclReferenceExprSyntax.self),
           type.baseName.text == "URLCache" {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            let propertyImpact = properties["urlCacheConfig"]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.value = "Custom URLCache initialized"
            propertyImpact?.location.append((line: location.line, column: location.column))
        }

        return .visitChildren
    }
}
