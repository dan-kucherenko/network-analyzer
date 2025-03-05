import SwiftSyntax

class ContentDeliveryVisitor: SyntaxVisitor {
    var foundHttpMaximumConnectionsPerHost = false
    var foundAllowsExpensiveNetworkAccess = false

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text

        switch memberName {
        case "httpMaximumConnectionsPerHost":
            foundHttpMaximumConnectionsPerHost = true
        case "allowsExpensiveNetworkAccess":
            foundAllowsExpensiveNetworkAccess = true
        default:
            break
        }

        return .visitChildren
    }
}