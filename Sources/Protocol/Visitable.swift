import SwiftSyntax

protocol Visitable: SyntaxVisitor {
    var properties: [String] { get set }
    var warnings: [AntipatternWarning] { get set }
//    func getImpactingSummary(properties: [String: PropertyImpact]) -> [String]
}

//extension Visitable {
//    func getImpactingSummary(properties: [String: PropertyImpact]) -> [String] {
//        properties.compactMap { property, impactInfo -> String? in
//            "Property: \(property), impact info: \n\(impactInfo.description)"
//        }
//    }
//}
