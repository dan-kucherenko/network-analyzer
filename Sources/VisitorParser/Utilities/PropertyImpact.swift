class PropertyImpact {
    var found: Bool = false
    var value: String?
    var hasNetworkImpact: Bool = false
    
    var description: String {
        return "Found: \(found), Value: \(value ?? "No information"), Network Impact: \(hasNetworkImpact)"
    }
}
