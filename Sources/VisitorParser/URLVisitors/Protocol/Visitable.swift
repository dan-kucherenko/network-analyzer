import SwiftSyntax

protocol Visitable: SyntaxVisitor {
    var properties: [String: PropertyImpact] { get set }
    func getImpactingSummary(properties: [String: PropertyImpact]) -> [String]
}

extension Visitable {
    func getImpactingSummary(properties: [String: PropertyImpact]) -> [String] {
        properties.compactMap { property, impactInfo -> String? in
            "Property: \(property), impact info: \n\(impactInfo.description)"
        }
    }
}
