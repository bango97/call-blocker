import Foundation

/// The kind of pattern a BlockRule uses to match phone numbers.
enum PatternType: String, Codable, CaseIterable, Identifiable {
    /// Exact 10-digit number (e.g. "0912345678")
    case exact
    /// Leading digits that must match (e.g. "0900" matches any 0900xxxxxx)
    case prefix
    /// Fixed-length pattern where 'x' matches any single digit (e.g. "09xx1234")
    case wildcard

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .exact:    return "Exact"
        case .prefix:   return "Prefix"
        case .wildcard: return "Wildcard"
        }
    }

    var placeholder: String {
        switch self {
        case .exact:    return "0912345678"
        case .prefix:   return "0900  (blocks 0900xxxxxx)"
        case .wildcard: return "09xx1234  (x = any digit)"
        }
    }
}
