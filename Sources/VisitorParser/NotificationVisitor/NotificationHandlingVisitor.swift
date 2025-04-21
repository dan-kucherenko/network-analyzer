import SwiftSyntax

class NotificationHandlingVisitor: SyntaxVisitor, Visitable {
    var properties: [String: PropertyImpact] = [
        "contentAvailableFlag": PropertyImpact(),
        "notificationHandling": PropertyImpact(),
    ]

    override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
        if node.name.text == "application" {
            let hasRemoteNotificationHandling = node.signature.parameterClause.parameters.contains { param in
                if param.firstName.text == "didReceiveRemoteNotification",
                   let type = param.type.as(IdentifierTypeSyntax.self),
                   type.name.text == "UIApplication"
                {
                    return true
                }
                return false
            }

            if hasRemoteNotificationHandling {
                let propertyImpact = properties["notificationHandling"]
                propertyImpact?.found = true
                propertyImpact?.hasNetworkImpact = true
                propertyImpact?.value = "Remote notification handling method found"
            }
        }

        return .visitChildren
    }

    override func visit(_ node: DictionaryElementListSyntax) -> SyntaxVisitorContinueKind {
        for element in node {
            if let key = element.key.as(StringLiteralExprSyntax.self),
               key.segments.first?.description.contains("content-available") == true
            {
                let propertyImpact = properties["contentAvailableFlag"]
                propertyImpact?.found = true

                if let value = element.value.as(IntegerLiteralExprSyntax.self) {
                    let contentAvailable = value.literal.text
                    propertyImpact?.hasNetworkImpact = contentAvailable == "1"
                    propertyImpact?.value = "content-available: \(contentAvailable) - " +
                        (contentAvailable == "1" ?
                            "App will be notified in foreground and background" :
                            "App will be notified only in foreground")
                }
            }
        }

        return .visitChildren
    }
}
