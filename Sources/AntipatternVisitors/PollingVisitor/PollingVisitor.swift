import SwiftSyntax

class PollingVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "timerPolling",
        "recursiveDispatchPolling",
        "infiniteLoopPolling"
    ]
    var warnings: [XcodeDiagnostic] = []
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        checkTimerPolling(node)
        checkRecursiveDispatchPolling(node)
        return .visitChildren
    }
    
    override func visit(_ node: WhileStmtSyntax) -> SyntaxVisitorContinueKind {
        checkInfiniteLoopPolling(node)
        return .visitChildren
    }
}

// MARK: - Polling Detection
private extension PollingVisitor {
    func checkTimerPolling(_ node: FunctionCallExprSyntax) {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "scheduledTimer",
              let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
              base.baseName.text == "Timer" else {
            return
        }
        
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
            
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Consider using a more appropriate polling mechanism or setting a more appropriate timeout value"
            ))
        }
    }
    
    func checkRecursiveDispatchPolling(_ node: FunctionCallExprSyntax) {
        guard let memberAccess = node.calledExpression.as(MemberAccessExprSyntax.self),
              memberAccess.declName.baseName.text == "asyncAfter" else {
            return
        }
        
        let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
        
        warnings.append(XcodeDiagnostic(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: "Doing some heavy stuff on the main thread may be impacting how the app responds"
        ))
    }
    
    func checkInfiniteLoopPolling(_ node: WhileStmtSyntax) {
        for statement in node.body.statements {
            guard let funcCall = statement.item.as(FunctionCallExprSyntax.self),
                  let memberAccess = funcCall.calledExpression.as(MemberAccessExprSyntax.self),
                  memberAccess.declName.baseName.text == "sleep",
                  let base = memberAccess.base?.as(DeclReferenceExprSyntax.self),
                  base.baseName.text == "Thread" else {
                continue
            }
            
            let location = statement.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: statement.root))
            warnings.append(XcodeDiagnostic(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Thread.sleep command completely blocks the executing thread, preventing it from performing any other work. If run on the main thread, this would freeze the UI entirely."
            ))
        }
    }
}
