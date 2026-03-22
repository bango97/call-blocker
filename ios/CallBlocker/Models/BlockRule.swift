import Foundation

/// A single call-blocking rule defined by the user.
struct BlockRule: Identifiable, Codable, Equatable {
    var id: UUID
    var label: String       // User-readable note (e.g. "Spam prefix")
    var pattern: String     // Raw digits (and optional 'x' for wildcard)
    var type: PatternType
    var isEnabled: Bool
    var createdAt: Date

    init(
        id: UUID = UUID(),
        label: String = "",
        pattern: String,
        type: PatternType,
        isEnabled: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.label = label
        self.pattern = pattern
        self.type = type
        self.isEnabled = isEnabled
        self.createdAt = createdAt
    }

    // MARK: - Expansion estimate

    /// Number of concrete phone numbers this rule expands to.
    /// Used for validation before saving and for UI feedback.
    var expansionCount: Int {
        switch type {
        case .exact:
            return 1
        case .prefix:
            // Assume Vietnamese 10-digit numbers; prefix is n digits → 10^(10-n) suffixes
            let suffixLen = max(0, 10 - pattern.count)
            return Int(pow(10.0, Double(suffixLen)))
        case .wildcard:
            let xCount = pattern.filter { $0 == "x" || $0 == "X" }.count
            return Int(pow(10.0, Double(xCount)))
        }
    }
}
