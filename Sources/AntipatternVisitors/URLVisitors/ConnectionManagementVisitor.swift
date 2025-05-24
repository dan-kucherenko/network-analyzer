import SwiftSyntax

class ConnectionVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "allowsCellularAccess",
        "networkServiceType",
        "waitsForConnectivity"
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
                case "allowsCellularAccess":
                    handleCellularAccessAssignment(parentNode: parentNode, location: location)
                case "waitsForConnectivity":
                    handleConnectivityAssignment(parentNode: parentNode, location: location)
                case "networkServiceType":
                    handleNetworkServiceAssignment(parentNode: parentNode, location: location)
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

private extension ConnectionVisitor {
    func handleCellularAccessAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            let boolValue = booleanLiteral.literal.text == "true"
            if boolValue {
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider setting allowsCellularAccess to false if your app does not require access to cellular networks. Current value is: true"
                ))
            }
        }
    }
    
    func handleConnectivityAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let booleanLiteral = parentNode.last?.as(BooleanLiteralExprSyntax.self) {
            let boolValue = booleanLiteral.literal.text == "true"
            if !boolValue {
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Consider setting waitsForConnectivity to true for better app performance. Current value is: false"
                ))
            }
        }
    }
    
    func handleNetworkServiceAssignment(parentNode: ExprListSyntax, location: SourceLocation) {
        if let enumCaseExpr = parentNode.last?.as(MemberAccessExprSyntax.self) {
            let enumCase = enumCaseExpr.declName.baseName.text
            if enumCase != "default" && enumCase != "background" {
                warnings.append(AntipatternWarning(
                    filePath: filePath,
                    line: location.line,
                    column: location.column,
                    message: "Check the usage of networkServiceType. Default value is 'default'. .video, .voice, .responsiveData, .avStreaming may impact the network if not needed. Current type: \(enumCase)"
                ))
            }
        }
    }
    
    func handlePropertyAccess(property: String, location: SourceLocation) {
        let message = switch property {
        case "allowsCellularAccess":
            "Cellular access property is being accessed. Consider setting it to false if your app does not require cellular network access."
        case "waitsForConnectivity":
            "Connectivity waiting property is being accessed. Consider setting it to true for better app performance."
        case "networkServiceType":
            "Network service type is being accessed. Make sure to use appropriate service type for your app's needs."
        default:
            "Connection property '\(property)' is being accessed. Review its configuration for optimal network performance."
        }
        
        warnings.append(AntipatternWarning(
            filePath: filePath,
            line: location.line,
            column: location.column,
            message: message
        ))
    }
}
