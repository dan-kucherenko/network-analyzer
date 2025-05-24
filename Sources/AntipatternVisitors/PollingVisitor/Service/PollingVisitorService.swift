import SwiftSyntax

class PollingVisitorService: VisitableService {
    private let filePath: String
    private let outputPath: String
    var visitors: [Visitable]

    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        visitors = [
            PollingVisitor(filePath: filePath),
        ]
    }
}
