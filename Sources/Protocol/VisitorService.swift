import SwiftSyntax

protocol VisitableService {
    var visitors: [Visitable] { get set }
    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [AntipatternWarning]
}

extension VisitableService {
    func analyzeSyntaxTree(_ tree: SourceFileSyntax) -> [AntipatternWarning] {
        visitors.flatMap { visitor in
            visitor.walk(tree)
            return visitor.warnings
        }
    }
}
