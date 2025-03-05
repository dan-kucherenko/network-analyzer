import SwiftSyntax

class PrefetchingAndBackgroundDataVisitor: SyntaxVisitor {
    var foundSessionSendsLaunchEvents = false
    var foundMultipathServiceType = false

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text

        switch memberName {
        case "sessionSendsLaunchEvents":
            foundSessionSendsLaunchEvents = true
        case "multipathServiceType":
            foundMultipathServiceType = true
        default:
            break
        }

        return .visitChildren
    }
}