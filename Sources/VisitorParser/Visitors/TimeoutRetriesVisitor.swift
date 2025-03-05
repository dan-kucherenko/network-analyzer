import SwiftSyntax

class TimeoutRetriesVisitor: SyntaxVisitor {
    var foundTimeoutRequest = false
    var foundTimeoutResource = false
    
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text
        
        if memberName == "timeoutIntervalForRequest" {
            foundTimeoutRequest = true
        } else if memberName == "timeoutIntervalForResource" {
            foundTimeoutResource = true
        }
        
        return .visitChildren
    }
}
