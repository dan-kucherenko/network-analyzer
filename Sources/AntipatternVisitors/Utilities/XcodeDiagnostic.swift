struct XcodeDiagnostic {
    let filePath: String
    let line: Int
    let column: Int
    let message: String
    
    func format() -> String {
        return "\(filePath):\(line):\(column): warning : \(message)"
    }
}
