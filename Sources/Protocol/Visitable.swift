import SwiftSyntax

protocol Visitable: SyntaxVisitor {
    var properties: [String] { get set }
    var warnings: [AntipatternWarning] { get set }
}
