import XCTest
@testable import CallBlocker

final class ExpansionLimiterTests: XCTestCase {

    func test_exact_passes() {
        let rule = BlockRule(pattern: "0912345678", type: .exact)
        XCTAssertNil(ExpansionLimiter.validate(rule))
    }

    func test_prefix_6digits_passes() {
        let rule = BlockRule(pattern: "090012", type: .prefix)
        XCTAssertNil(ExpansionLimiter.validate(rule))
    }

    func test_prefix_4digits_fails() {
        let rule = BlockRule(pattern: "0900", type: .prefix)
        XCTAssertNotNil(ExpansionLimiter.validate(rule))
    }

    func test_wildcard_4x_passes() {
        let rule = BlockRule(pattern: "09xxxx78", type: .wildcard)  // 10^4 = 10_000 ≤ cap
        XCTAssertNil(ExpansionLimiter.validate(rule))
    }

    func test_wildcard_5x_fails() {
        let rule = BlockRule(pattern: "09xxxxx8", type: .wildcard)  // 10^5 = 100_000 > cap
        XCTAssertNotNil(ExpansionLimiter.validate(rule))
    }

    func test_totalExpansion_countOnlyEnabled() {
        let rules = [
            BlockRule(pattern: "0912345678", type: .exact, isEnabled: true),
            BlockRule(pattern: "0812345678", type: .exact, isEnabled: false),
        ]
        XCTAssertEqual(ExpansionLimiter.totalExpansion(of: rules), 1)
    }

    func test_rulesWithinBudget_truncatesWhenOverGlobalCap() {
        // Create rules that together exceed 80_000
        // prefix 6 digits = 10_000 each → 9 rules = 90_000 > 80_000
        let rules = (0..<9).map { i in
            BlockRule(pattern: "09001\(i)", type: .prefix, isEnabled: true)
        }
        let budget = ExpansionLimiter.rulesWithinBudget(rules)
        let total = ExpansionLimiter.totalExpansion(of: budget)
        XCTAssertLessThanOrEqual(total, ExpansionLimiter.globalCap)
        XCTAssertEqual(budget.count, 8)  // 8 × 10_000 = 80_000
    }
}
