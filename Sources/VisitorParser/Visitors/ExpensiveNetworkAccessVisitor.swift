import SwiftSyntax

class ExpensiveNetworkAccessVisitor: SyntaxVisitor {
    var foundAllowsExpensiveNetworkAccess = false

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text

        if memberName == "allowsExpensiveNetworkAccess" {
            foundAllowsExpensiveNetworkAccess = true
        }

        return .visitChildren
    }
}