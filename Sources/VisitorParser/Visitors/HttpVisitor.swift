import SwiftSyntax

class HttpVisitor: SyntaxVisitor {
    var foundHttpAdditionalHeaders = false
    var foundHttpShouldSetCookies = false
    var foundHttpCookieAcceptPolicy = false
    var foundHttpShouldUsePipelining = false
    
    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if let baseExpr = node.base?.as(DeclReferenceExprSyntax.self),
           baseExpr.baseName.text == "URLSessionConfiguration" {
            
            let property = node.declName.baseName.text
            
            switch property {
            case "httpAdditionalHeaders":
                foundHttpAdditionalHeaders = true
            case "httpShouldSetCookies":
                foundHttpShouldSetCookies = true
            case "httpCookieAcceptPolicy":
                foundHttpCookieAcceptPolicy = true
            case "httpShouldUsePipelining":
                foundHttpShouldUsePipelining = true
            default:
                break
            }
        }
        return .visitChildren
    }
}
