import SwiftSyntax

class LifecycleVisitorService: VisitableService {
    private let filePath: String
    private let outputPath: String
    var visitors: [Visitable]

    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        self.visitors = [
            LifecycleMethodsVisitor(filePath: filePath),
        ]
    }
}
