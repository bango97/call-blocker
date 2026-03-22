import Foundation

/// Converts prefix and wildcard BlockRules into sorted arrays of concrete Int64 phone numbers
/// suitable for feeding to CXCallDirectoryExtensionContext.
///
/// CallKit requirement: numbers must be passed in ascending sorted order.
enum PatternExpander {

    // MARK: - Public

    /// Expand a rule into concrete numbers, or return nil if the rule
    /// would exceed ExpansionLimiter.singleRuleCap.
    static func expand(_ rule: BlockRule) -> [Int64]? {
        guard rule.expansionCount <= ExpansionLimiter.singleRuleCap else { return nil }
        switch rule.type {
        case .exact:
            return expandExact(rule.pattern)
        case .prefix:
            return expandPrefix(rule.pattern)
        case .wildcard:
            return expandWildcard(rule.pattern)
        }
    }

    // MARK: - Private

    private static func expandExact(_ pattern: String) -> [Int64]? {
        guard let n = Int64(pattern) else { return nil }
        return [n]
    }

    private static func expandPrefix(_ pattern: String) -> [Int64]? {
        guard let base = Int64(pattern) else { return nil }
        let suffixLen = max(0, 10 - pattern.count)
        if suffixLen == 0 { return [base] }
        let count = Int64(pow(10.0, Double(suffixLen)))
        let start = base * count
        return (0..<count).map { start + $0 }   // already ascending
    }

    private static func expandWildcard(_ pattern: String) -> [Int64]? {
        var results = [Int64]()
        expandWildcardRecursive("", pattern[...], &results)
        results.sort()
        return results.isEmpty ? nil : results
    }

    private static func expandWildcardRecursive(
        _ current: String,
        _ remaining: Substring,
        _ out: inout [Int64]
    ) {
        if remaining.isEmpty {
            if let n = Int64(current) { out.append(n) }
            return
        }
        let ch = remaining.first!
        let rest = remaining.dropFirst()
        if ch == "x" || ch == "X" {
            for d in 0...9 {
                expandWildcardRecursive(current + "\(d)", rest, &out)
            }
        } else {
            expandWildcardRecursive(current + String(ch), rest, &out)
        }
    }
}
