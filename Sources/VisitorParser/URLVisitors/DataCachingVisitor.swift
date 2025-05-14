import SwiftSyntax

class DataCachingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "urlCache": PropertyImpact(),
        "requestCachePolicy": PropertyImpact()
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
                        propertyImpact.value = booleanLiteral.literal.text
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
                        propertyImpact.recommendation = "Consider implementing a custom URLCache with appropriate memory and disk capacity limits for your app's needs. This will help manage memory usage and improve performance."
                    } else if property == "urlCache" {
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))
                        propertyImpact.recommendation = "Implement a custom URLCache with appropriate memory and disk capacity limits. The default shared cache might not be optimal for your app's specific needs."
                    } else if property == "requestCachePolicy" {
                        propertyImpact.hasNetworkImpact = true
                        propertyImpact.location.append((line: location.line, column: location.column))

                        if let policyAccess = parentNode.last?.as(MemberAccessExprSyntax.self) {
                            let policyName = policyAccess.declName.baseName.text
                            propertyImpact.value = policyName
                            if policyName == "returnCacheDataDontLoad" {
                                propertyImpact.recommendation = "Using .returnCacheDataDontLoad may result in stale data. Make sure this is intended for your use case."
                            } else if policyName == "reloadIgnoringCacheData" {
                                propertyImpact.recommendation = "Using .reloadIgnoringCacheData will always fetch from the network, which may increase data usage and reduce performance. Use only if fresh data is critical."
                            }
                        }
                    }
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let property = node.declName.baseName.text
        if properties.keys.contains(property) {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            let propertyImpact = properties[property]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.location.append((line: location.line, column: location.column))
            
            if property == "urlCache" {
                propertyImpact?.recommendation = "Consider implementing a custom URLCache with appropriate memory and disk capacity limits. The default shared cache might not be optimal for your app's specific needs."
            } else if property == "requestCachePolicy" {
                if let parent = node.parent?.as(InfixOperatorExprSyntax.self),
                   let right = parent.rightOperand.as(MemberAccessExprSyntax.self) {
                    let policyName = right.declName.baseName.text
                    propertyImpact?.value = policyName
                    if policyName == "returnCacheDataDontLoad" {
                        propertyImpact?.recommendation = "Using .returnCacheDataDontLoad may result in stale data. Make sure this is intended for your use case."
                    } else if policyName == "reloadIgnoringCacheData" {
                        propertyImpact?.recommendation = "Using .reloadIgnoringCacheData will always fetch from the network, which may increase data usage and reduce performance. Use only if fresh data is critical"
                    }
                }
            }
        }
        return .visitChildren
    }
}
