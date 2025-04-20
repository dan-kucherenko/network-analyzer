import SwiftSyntax

class CachingPolicyVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "urlCacheConfig": PropertyImpact(),
        "cachePolicy": PropertyImpact(),
    ]

    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self) {
            if let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
                let property = memberAccessNode.declName.baseName.text

                if property == "urlCache" {
                    let propertyImpact = properties["urlCacheConfig"]
                    propertyImpact?.found = true
                    propertyImpact?.hasNetworkImpact = true

                    if let sharedAccess = parentNode.last?.as(MemberAccessExprSyntax.self),
                       sharedAccess.declName.baseName.text == "shared"
                    {
                        propertyImpact?.value = "Using URLCache.shared"
                    } else {
                        propertyImpact?.value = "Using custom URLCache configuration"
                    }
                }

                // Check for requestCachePolicy assignments
                if property == "requestCachePolicy" {
                    if let policyAccess = parentNode.last?.as(MemberAccessExprSyntax.self) {
                        let policyName = policyAccess.declName.baseName.text
                        let propertyImpact = properties["cachePolicy"]

                        switch policyName {
                        case "useProtocolCachePolicy",
                             "returnCacheDataElseLoad",
                             "returnCacheDataDontLoad":
                            propertyImpact?.found = true
                            propertyImpact?.hasNetworkImpact = true
                            propertyImpact?.value = "Using cache policy: \(policyName)"
                        default:
                            break
                        }
                    }
                }
            }
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let type = node.calledExpression.as(DeclReferenceExprSyntax.self),
           type.baseName.text == "URLCache"
        {
            let propertyImpact = properties["urlCacheConfig"]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.value = "Custom URLCache initialized"
        }

        return .visitChildren
    }
}
