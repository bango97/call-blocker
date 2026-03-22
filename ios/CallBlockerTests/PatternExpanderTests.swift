import XCTest
@testable import CallBlocker

final class PatternExpanderTests: XCTestCase {

    // MARK: - Exact

    func test_exact_returnsOneNumber() {
        let rule = BlockRule(pattern: "0912345678", type: .exact)
        let result = PatternExpander.expand(rule)
        XCTAssertEqual(result, [912345678])
    }

    // MARK: - Prefix

    func test_prefix_8digits_returns100Numbers() {
        let rule = BlockRule(pattern: "09123456", type: .prefix)
        let result = PatternExpander.expand(rule)
        XCTAssertEqual(result?.count, 100)
        // First and last
        XCTAssertEqual(result?.first, 9123456_00)
        XCTAssertEqual(result?.last,  9123456_99)
    }

    func test_prefix_sorted() {
        let rule = BlockRule(pattern: "091234567", type: .prefix)
        let result = PatternExpander.expand(rule)!
        XCTAssertEqual(result, result.sorted())
    }

    func test_prefix_4digits_exceeds_cap_returnsNil() {
        // 4-digit prefix → 10^6 numbers > singleRuleCap(10_000)
        let rule = BlockRule(pattern: "0900", type: .prefix)
        XCTAssertNil(PatternExpander.expand(rule))
    }

    // MARK: - Wildcard

    func test_wildcard_2x_returns100Numbers() {
        let rule = BlockRule(pattern: "09xx1234", type: .wildcard)
        let result = PatternExpander.expand(rule)
        XCTAssertEqual(result?.count, 100)
    }

    func test_wildcard_sorted() {
        let rule = BlockRule(pattern: "09xx1234", type: .wildcard)
        let result = PatternExpander.expand(rule)!
        XCTAssertEqual(result, result.sorted())
    }

    func test_wildcard_0x_returns1Number() {
        let rule = BlockRule(pattern: "0912345678", type: .wildcard)
        let result = PatternExpander.expand(rule)
        XCTAssertEqual(result?.count, 1)
    }

    func test_wildcard_caseInsensitive() {
        let lower = BlockRule(pattern: "09xx1234", type: .wildcard)
        let upper = BlockRule(pattern: "09XX1234", type: .wildcard)
        XCTAssertEqual(PatternExpander.expand(lower), PatternExpander.expand(upper))
    }
}
