import SwiftSyntax
import SwiftParser

class NotificationHandlingVisitor: SyntaxVisitor, Visitable {
    private let filePath: String
    var properties: [String] = [
        "notificationHandling"
    ]
    var warnings: [AntipatternWarning] = []
    private var currentClass: String?
    private var currentFunction: String?
    private var currentLocation: SourceLocation?
    private var currentValue: String?

    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .sourceAccurate)
    }

    override func visit(_ node: ClassDeclSyntax) -> SyntaxVisitorContinueKind {
        currentClass = node.name.text
        return .visitChildren
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        currentFunction = node.name.text
        return .visitChildren
    }

    override func visit(_ node: StringLiteralExprSyntax) -> SyntaxVisitorContinueKind {
        currentValue = node.segments.description
        return .visitChildren
    }

    override func visit(_ node: FunctionCallExprSyntax) -> SyntaxVisitorContinueKind {
        guard let calledExpression = node.calledExpression.as(MemberAccessExprSyntax.self) else {
            return .visitChildren
        }

        let functionName = calledExpression.declName.baseName.text
        if functionName == "addObserver" || functionName == "removeObserver" {
            currentLocation = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
            checkNotificationUsage(
                functionName: functionName,
                location: currentLocation,
                value: currentValue
            )
        }

        return .visitChildren
    }

    private func checkNotificationUsage(functionName: String, location: SourceLocation?, value: String?) {
        guard let location = location, let value = value else { return }

        let recommendation: String

        switch functionName {
        case "addObserver":
            recommendation = "Consider using Combine framework for reactive programming instead of NotificationCenter"
        case "removeObserver":
            recommendation = "Consider using Combine framework for reactive programming instead of NotificationCenter"
        default:
            return
        }

        warnings.append(
            AntipatternWarning(
                filePath: filePath,
                line: location.line,
                column: location.column,
                message: "\(recommendation) Current value is: \(value)"
            )
        )
    }
}
