import SwiftSyntax

class PollingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "timerPolling": PropertyImpact(),
        "recursivePolling": PropertyImpact(),
        "infiniteLoopPolling": PropertyImpact()
    ]
    
    // Detect infinite loop with delay polling
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        let condition = node.conditions
        let body = node.body
        let propertyImpact = properties["infiniteLoopPolling"]
        
        body.statements.forEach {
            if let funcCall = $0.item.as(FunctionCallExprSyntax.self),
               let functionName = funcCall.calledExpression.as(MemberAccessExprSyntax.self)?.declName.baseName.text, functionName == "sleep",
               let argument = funcCall.arguments.first, argument.label?.text == "forTimeInterval" {
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "timeIntervalFor: \(argument.expression.description)"
            }
        }
        
        return .visitChildren
    }
}
