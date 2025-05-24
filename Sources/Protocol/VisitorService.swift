import SwiftSyntax

protocol VisitableService {
    var visitors: [Visitable] { get set }
    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [XcodeDiagnostic]
}

extension VisitableService {
    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [XcodeDiagnostic] {
        visitors.flatMap { visitor in
            visitor.walk(tree)
            return visitor.warnings
        }
    }
}
