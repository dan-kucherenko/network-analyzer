import SwiftSyntax

class LifecycleMethodsVisitor: SyntaxVisitor, Visitable {
    var properties: [String] = [
        "backgroundOperations",
        "resignActiveHandling"
    ]
    var warnings: [AntipatternWarning] = []
    
    private let filePath: String
    private let suspiciousFunctionNames = [
        "URLSession",
        "dataTask",
        "downloadTask",
        "uploadTask",
        "fetch",
        "download",
        "upload",
        "request",
        "performLongTask",
        "process",
        "calculate",
        "compute",
    ]
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.name.text
        let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))

        switch functionName {
        case "applicationDidEnterBackground":
            handleBackgroundMethod(node: node, location: location)
        case "applicationWillResignActive":
            handleResignActiveMethod(node: node, location: location)
        default:
            break
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let functionDecl = findParentFunction(node),
           functionDecl.name.text == "applicationDidEnterBackground",
           let calledFunction = node.calledExpression.as(MemberAccessExprSyntax.self) {
            handleBackgroundFunctionCall(node: node, functionName: calledFunction.declName.baseName.text)
        }

        return .visitChildren
    }
}

private extension LifecycleMethodsVisitor {
    func handleBackgroundMethod(node: FunctionDeclSyntax, location: SourceLocation) {
        let hasSuspiciousOperations = node.body?.statements.contains { statement in
            suspiciousFunctionNames.contains { suspicious in
                statement.description.contains(suspicious)
            }
        } ?? false

        if hasSuspiciousOperations {
            warnings.append(AntipatternWarning(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Heavy operations detected in applicationDidEnterBackground. Consider moving these operations to a more appropriate lifecycle method or using background tasks."
            ))
        }
    }
    
    func handleResignActiveMethod(node: FunctionDeclSyntax, location: SourceLocation) {
        let hasPauseOperations = node.body?.statements.contains { statement in
            let content = statement.description.lowercased()
            return content.contains("pause") || content.contains("stop")
                || content.contains("suspend") || content.contains("cancel")
        } ?? false

        if !hasPauseOperations {
            warnings.append(AntipatternWarning(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "No pause/stop operations found in applicationWillResignActive. Consider adding appropriate pause/stop operations for network tasks and heavy computations."
            ))
        }
    }
    
    func handleBackgroundFunctionCall(node: FunctionCallExprSyntax, functionName: String) {
        if suspiciousFunctionNames.contains(functionName) {
            let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            warnings.append(AntipatternWarning(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "Network call or heavy computation '\(functionName)' detected in background. Consider moving this operation to a more appropriate lifecycle method or using background tasks."
            ))
        }
    }
    
    func findParentFunction(_ node: SyntaxProtocol) -> FunctionDeclSyntax? {
        var currentNode = node.parent
        while let parent = currentNode {
            if let functionDecl = parent.as(FunctionDeclSyntax.self) {
                return functionDecl
            }
            currentNode = parent.parent
        }
        return nil
    }
}
