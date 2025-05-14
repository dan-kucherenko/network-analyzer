import SwiftSyntax

class NotificationHandlingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "contentAvailableFlag": PropertyImpact(),
        "notificationHandling": PropertyImpact(),
    ]
    
    private let filePath: String
    
    init(filePath: String) {
        self.filePath = filePath
        super.init(viewMode: .all)
    }

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.text == "application" {
            let hasRemoteNotificationHandling = node.signature.parameterClause.parameters.contains { param in
                if param.firstName.text == "didReceiveRemoteNotification",
                   let type = param.type.as(IdentifierTypeSyntax.self),
                   type.name.text == "UIApplication" {
                    return true
                }
                return false
            }

            if hasRemoteNotificationHandling {
                let location = node.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: node.root))
                let propertyImpact = properties["notificationHandling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "Remote notification handling method found"
                propertyImpact?.location.append((line: location.line, column: location.column))
                propertyImpact?.recommendation = "Implement efficient background fetch logic in didReceiveRemoteNotification. Avoid heavy processing, always call the fetch completion handler promptly, and test for both foreground and background scenarios."
            }
        }

        return .visitChildren
    }

    override func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
        for element in node {
            if let key = element.key.as(StringLiteralExprSyntax.self),
               key.segments.first?.description.contains("content-available") == true
            {
                let location = element.startLocation(converter: SourceLocationConverter(fileName: filePath, tree: element.root))
                let propertyImpact = properties["contentAvailableFlag"]
                propertyImpact?.found = true

                if let value = element.value.as(IntegerLiteralExprSyntax.self) {
                    let contentAvailable = value.literal.text
                    propertyImpact?.hasNetworkImpact = contentAvailable == "1"
                    propertyImpact?.value = "content-available: \(contentAvailable) - " +
                        (contentAvailable == "1" ?
                            "App will be notified in foreground and background" :
                            "App will be notified only in foreground")
                    propertyImpact?.location.append((line: location.line, column: location.column))

                    if contentAvailable == "1" {
                        propertyImpact?.recommendation = "Use the content-available flag only when your app truly needs background fetch. Unnecessary use can negatively impact battery life. Minimize background work and always call the fetch completion handler promptly."
                    } else {
                        propertyImpact?.recommendation = "content-available: 0 means the notification will not wake your app in the background. Use this for foreground-only notifications."
                    }
                }
            }
        }

        return .visitChildren
    }
}
