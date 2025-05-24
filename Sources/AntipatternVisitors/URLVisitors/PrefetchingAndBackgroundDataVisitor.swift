import SwiftSyntax

class PrefetchingAndBackgroundDataVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "sessionSendsLaunchEvents",
        "multipathServiceType"
    ]
    var warnings: [AntipatternWarning] = []
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }
    
    override func visit(_ node: AssignmentExprSyntax) -> SyntaxVisitorContinueKind {
        if let parentNode = node.parent?.as(ExprListSyntax.self),
           let memberAccessNode = parentNode.first?.as(MemberAccessExprSyntax.self) {
            let property = memberAccessNode.declName.baseName.text
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            
            if properties.contains(property) {
                switch property {
                case "sessionSendsLaunchEvents":
                    handleLaunchEventsAssignment(parentNode: parentNode, location: location)
                case "multipathServiceType":
                    handleMultipathServiceAssignment(parentNode: parentNode, location: location)
                default:
                    break
                }
            }
        }
        return .visitChildren
    }

    override func visit(_ node: MemberAccessExprSyntax) -> SyntaxVisitorContinueKind {
        if ((node.base?.as(DeclReferenceExprSyntax.self)) != nil) {
            let property = node.declName.baseName.text
            if properties.contains(property) {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                handlePropertyAccess(property: property, location: location)
            }
        }
        return .visitChildren
    }
}

private extension PrefetchingAndBackgroundDataVisitor {
    func handleLaunchEventsAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            let boolValue = booleanLiteral.literal.text == "true"
            if boolValue {
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider setting sessionSendsLaunchEvents to false if your app does not require access to launch events. Current value is: true"
                ))
            }
        }
    }
    
    func handleMultipathServiceAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
            let currentValue = enumCaseExpr.declName.baseName.text
            if currentValue == "aggregate" {
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider setting a more appropriate value for multipathServiceType. Aggregate may impact the network if not needed. Current type: \(currentValue)"
                ))
            }
        }
    }
    
    func handlePropertyAccess(property: String, location: SourceLocation) {
        let message = switch property {
        case "sessionSendsLaunchEvents":
            "Launch events property is being accessed. Consider setting it to false if your app does not require access to launch events."
        case "multipathServiceType":
            "Multipath service type is being accessed. Make sure to use appropriate service type for your app's needs."
        default:
            "Prefetching property '\(property)' is being accessed. Review its configuration for optimal network performance."
        }
        
        warnings.append(AntipatternWarning(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: message
        ))
    }
}
