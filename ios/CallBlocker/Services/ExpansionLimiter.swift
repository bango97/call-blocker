import Foundation

/// Enforces limits on how many concrete phone numbers can be registered with CallKit.
///
/// Background:
/// - CallKit's CXCallDirectoryExtension processes numbers synchronously and has an
///   undocumented but community-observed practical ceiling of ~80,000 entries before
///   performance degrades or the extension is terminated.
/// - A 4-digit prefix expands to 1,000,000 numbers — far beyond this limit.
///   Users must use prefixes of 6+ digits or wildcards with ≤4 'x' placeholders.
enum ExpansionLimiter {

    /// Maximum numbers a single rule may expand to.
    static let singleRuleCap = 10_000

    /// Total numbers registered across all enabled rules.
    static let globalCap = 80_000

    // MARK: - Validation

    enum ValidationError: LocalizedError {
        case tooManyExpansions(count: Int, cap: Int)

        var errorDescription: String? {
            switch self {
            case let .tooManyExpansions(count, cap):
                return "This pattern matches \(count.formatted()) numbers, which exceeds the limit of \(cap.formatted()). " +
                       "Use a more specific prefix (≥6 digits) or fewer than 5 wildcards."
            }
        }
    }

    /// Returns a validation error if the rule's expansion count exceeds singleRuleCap.
    static func validate(_ rule: BlockRule) -> ValidationError? {
        if rule.expansionCount > singleRuleCap {
            return .tooManyExpansions(count: rule.expansionCount, cap: singleRuleCap)
        }
        return nil
    }

    /// Total expansion of all enabled rules; used to check global cap.
    static func totalExpansion(of rules: [BlockRule]) -> Int {
        rules.filter(\.isEnabled).reduce(0) { $0 + $1.expansionCount }
    }

    /// Rules that fit within the global cap (preserves insertion order, newest rules may be dropped).
    static func rulesWithinBudget(_ rules: [BlockRule]) -> [BlockRule] {
        var used = 0
        var result = [BlockRule]()
        for rule in rules where rule.isEnabled {
            let count = rule.expansionCount
            if used + count > globalCap { break }
            result.append(rule)
            used += count
        }
        return result
    }
}
