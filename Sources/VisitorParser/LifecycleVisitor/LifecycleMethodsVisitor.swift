import SwiftSyntax

class LifecycleMethodsVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "backgroundOperations": PropertyImpact(),
        "resignActiveHandling": PropertyImpact(),
    ]
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }

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

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        let functionName = node.name.text
        let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))

        if functionName == "applicationDidEnterBackground" {
            let propertyImpact = properties["backgroundOperations"]
            propertyImpact?.found = true

            let hasSuspiciousOperations =
                node.body?.statements.contains { statement in
                    suspiciousFunctionNames.contains { suspicious in
                        statement.description.contains(suspicious)
                    }
                } ?? false

            if hasSuspiciousOperations {
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "Heavy operations detected in applicationDidEnterBackground"
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }

        if functionName == "applicationWillResignActive" {
            let propertyImpact = properties["resignActiveHandling"]
            propertyImpact?.found = true

            let hasPauseOperations =
                node.body?.statements.contains { statement in
                    let content = statement.description.lowercased()
                    return content.contains("pause") || content.contains("stop")
                        || content.contains("suspend") || content.contains("cancel")
                } ?? false

            if !hasPauseOperations {
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "No pause/stop operations found in applicationWillResignActive"
                propertyImpact?.location.append((line: location.line, column: location.column))
            }
        }

        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        if let functionDecl = findParentFunction(node),
           functionDecl.name.text == "applicationDidEnterBackground"
        {
            if let calledFunction = node.calledExpression.as(MemberAccessExprSyntax.self) {
                let functionName = calledFunction.declName.baseName.text
                if suspiciousFunctionNames.contains(functionName) {
                    let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                    let propertyImpact = properties["backgroundOperations"]
                    propertyImpact?.found = true
                    propertyImpact?.hasNetworkImpact = true
                    propertyImpact?.value =
                        "Network call or heavy computation '\(functionName)' detected in background"
                    propertyImpact?.location.append((line: location.line, column: location.column))
                }
            }
        }

        return .visitChildren
    }
}

extension LifecycleMethodsVisitor {
    private func findParentFunction(_ node: SyntaxProtocol) -> FunctionDeclSyntax? {
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
