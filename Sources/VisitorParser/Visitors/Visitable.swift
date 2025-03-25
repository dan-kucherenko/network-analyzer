import SwiftSyntax

protocol Visitable: SyntaxVisitor {
    func getImpactingSummary() -> [String]
}
