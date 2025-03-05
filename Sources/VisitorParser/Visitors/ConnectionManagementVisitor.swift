import SwiftSyntax

class ConnectionManagementVisitor: SyntaxVisitor {
    var foundAllowsCellularAccess = false
    var foundNetworkServiceType = false
    var foundWaitsForConnectivity = false

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        let memberName = node.declName.baseName.text

        switch memberName {
        case "allowsCellularAccess":
            foundAllowsCellularAccess = true
        case "networkServiceType":
            foundNetworkServiceType = true
        case "waitsForConnectivity":
            foundWaitsForConnectivity = true
        default:
            break
        }

        return .visitChildren
    }
}
