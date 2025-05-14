class PropertyImpact {
    var found: Bool = false
    var value: String?
    var hasNetworkImpact: Bool = false
    var location: [(line: Int, column: Int)] = []
    var recommendation: String?
    
    var description: String {
    """
        \(location.map { "\($0.line): \($0.column)" }):  
        Value: \(value ?? "No information"), 
        Network Impact: \(hasNetworkImpact)
        Recommendation: \(recommendation ?? "No recommendation")
    """
    }
}
