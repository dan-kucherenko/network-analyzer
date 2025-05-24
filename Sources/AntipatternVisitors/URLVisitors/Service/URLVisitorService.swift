import SwiftSyntax

class URLVisitorService: VisitableService {
    private let filePath: String
    private let outputPath: String
    var visitors: [Visitable]
    
    init(filePath: String, outputPath: String) {
        self.filePath = filePath
        self.outputPath = outputPath
        self.visitors = [
            HttpVisitor(filePath: filePath),
            ConnectionVisitor(filePath: filePath),
            ContentDeliveryVisitor(filePath: filePath),
            DataCachingVisitor(filePath: filePath),
            PrefetchingAndBackgroundDataVisitor(filePath: filePath),
            TimeoutAndRetryVisitor(filePath: filePath)
        ]
    }
}
