import SwiftSyntax

class PollingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "timerPolling": PropertyImpact(),
        "recursiveDispatchPolling": PropertyImpact(),
        "infiniteLoopPolling": PropertyImpact(),
    ]

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "scheduledTimer",
           let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
           base.baseName.text == "Timer"
        {
            let hasRepeatsTrue = node.arguments.contains { arg in
                if arg.label?.text == "repeats",
                   let boolExpr = arg.expression.as(BooleanLiteralExprSyntax.self),
                   boolExpr.literal.text == "true"
                {
                    return true
                }
                return false
            }

            if hasRepeatsTrue {
                let propertyImpact = properties["timerPolling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "Timer.scheduledTimer with repeats: true detected"
            }
        }

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "asyncAfter"
        {
            let propertyImpact = properties["recursiveDispatchPolling"]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.value = "DispatchQueue.main.asyncAfter polling detected"
        }

        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        for statement in node.body.statements {
            if let funcCall = statement.item.as(FunctionCallExprSyntax.self),
               let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "sleep",
               let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
               base.baseName.text == "Thread"
            {
                let propertyImpact = properties["infiniteLoopPolling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "Infinite loop with Thread.sleep detected"
            }
        }

        return .visitChildren
    }
}
