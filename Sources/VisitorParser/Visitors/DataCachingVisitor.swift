import SwiftSyntax

class DataCachingVisitor: SyntaxVisitor {
    var foundUrlCache = false
    var foundRequestCachePolicy = false

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text

        if memberName == "urlCache" {
            foundUrlCache = true
        } else if memberName == "requestCachePolicy" {
            foundRequestCachePolicy = true
        }

        return .visitChildren
    }
}
