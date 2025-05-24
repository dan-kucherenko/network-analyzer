struct AntipatternWarning {
    let filePath: String
    let line: Int
    let column: Int
    let message: String
    let type: DiagnosticType = .warning
    
    enum DiagnosticType: String {
        case warning = "warning"
        case error = "error"
    }
    
    func format() -> String {
        return "\(filePath):\(line):\(column): \(type.rawValue): \(message)"
    }
}
