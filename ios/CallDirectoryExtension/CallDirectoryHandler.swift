import Foundation
import CallKit

/// CXCallDirectoryProvider subclass — the core of iOS call blocking.
///
/// This runs in a separate extension process. It reads rules from the App Group
/// UserDefaults (written by the main app via RuleStore), expands patterns into
/// concrete Int64 phone numbers, and feeds them to CallKit.
///
/// Key requirements enforced here:
/// 1. Phone numbers must be added in ascending sorted order.
/// 2. Total numbers must stay within the global cap (~80,000).
/// 3. All work must complete before calling context.completeRequest().
class CallDirectoryHandler: CXCallDirectoryProvider {

    override func beginRequest(with context: CXCallDirectoryExtensionContext) {
        context.delegate = self

        let store = RuleStoreReader()
        let rules = store.loadRules()

        if context.isIncremental {
            addIncrementalBlockingEntries(to: context, rules: rules, store: store)
        } else {
            addAllBlockingEntries(to: context, rules: rules)
        }

        context.completeRequest()
    }

    // MARK: - Full reload

    private func addAllBlockingEntries(
        to context: CXCallDirectoryExtensionContext,
        rules: [BlockRule]
    ) {
        let activeRules = ExpansionLimiter.rulesWithinBudget(rules)
        var allNumbers = [Int64]()

        for rule in activeRules {
            guard let numbers = PatternExpander.expand(rule) else { continue }
            allNumbers.append(contentsOf: numbers)
        }

        // CallKit requires ascending order — mandatory.
        allNumbers.sort()

        // Deduplicate in case rules overlap
        var seen = Set<Int64>()
        for number in allNumbers {
            guard seen.insert(number).inserted else { continue }
            context.addBlockingEntry(withNextSequentialPhoneNumber: number)
        }
    }

    // MARK: - Incremental update

    private func addIncrementalBlockingEntries(
        to context: CXCallDirectoryExtensionContext,
        rules: [BlockRule],
        store: RuleStoreReader
    ) {
        // For simplicity, re-add all numbers. A production implementation would
        // compute the diff between the previous sync and current rules using
        // the lastSyncTimestamp stored in the App Group.
        addAllBlockingEntries(to: context, rules: rules)
    }
}

// MARK: - CXCallDirectoryExtensionContextDelegate

extension CallDirectoryHandler: CXCallDirectoryExtensionContextDelegate {
    func requestFailed(for extensionContext: CXCallDirectoryExtensionContext, withError error: Error) {
        // Log the error; nothing more we can do from the extension process.
        NSLog("[CallDirectoryExtension] Request failed: \(error)")
    }
}

// MARK: - RuleStoreReader (extension-side, read-only)

/// Lightweight reader for the App Group UserDefaults.
/// The full RuleStore (ObservableObject) is only needed in the main app.
private struct RuleStoreReader {
    private let defaults: UserDefaults?
    private let decoder = JSONDecoder()

    init() {
        self.defaults = UserDefaults(suiteName: SharedConstants.appGroupID)
    }

    func loadRules() -> [BlockRule] {
        guard let data = defaults?.data(forKey: SharedConstants.rulesKey),
              let rules = try? decoder.decode([BlockRule].self, from: data)
        else { return [] }
        return rules
    }
}
