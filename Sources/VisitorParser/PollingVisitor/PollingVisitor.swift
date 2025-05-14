import SwiftSyntax

class PollingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "timerPolling": PropertyImpact(),
        "recursiveDispatchPolling": PropertyImpact(),
        "infiniteLoopPolling": PropertyImpact(),
    ]
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "scheduledTimer",
           let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
           base.baseName.text == "Timer" {
            let hasRepeatsTrue = node.arguments.contains { arg in
                if arg.label?.text == "repeats",
                   let boolExpr = arg.expression.as(BooleanLiteralExprSyntax.self),
                   boolExpr.literal.text == "true" {
                    return true
                }
                return false
            }

            if hasRepeatsTrue {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                let propertyImpact = properties["timerPolling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.location.append((line: location.line, column: location.column))
                propertyImpact?.recommendation = "Consider using a more appropriate polling mechanism or setting a more appropriate timeout value"
            }
        }

        if let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
           memberAccess.declName.baseName.text == "asyncAfter" {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            let propertyImpact = properties["recursiveDispatchPolling"]
            propertyImpact?.found = true
            propertyImpact?.hasNetworkImpact = true
            propertyImpact?.recommendation = "Doing some heavy stuff on the main thread may be impacting how the app responds"
            propertyImpact?.location.append((line: location.line, column: location.column))
        }

        return .visitChildren
    }

    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        for statement in node.body.statements {
            if let funcCall = statement.item.as(FunctionCallExprSyntax.self),
               let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
               memberAccess.declName.baseName.text == "sleep",
               let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
               base.baseName.text == "Thread" {
                let location = statement.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: statement.root))
                let propertyImpact = properties["infiniteLoopPolling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.recommendation = "Thread.sleep command completely blocks the executing thread, preventing it from performing any other work. If run on the main thread, this would freeze the UI entirely."
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }

        return .visitChildren
    }
}
