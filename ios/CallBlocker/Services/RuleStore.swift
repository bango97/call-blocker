import Foundation

/// Single source of truth for BlockRule persistence.
/// Uses App Group UserDefaults so the CallDirectoryExtension (a separate process)
/// can read the same data.
final class RuleStore: ObservableObject {
    static let shared = RuleStore()

    @Published private(set) var rules: [BlockRule] = []

    private let defaults: UserDefaults
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    private init() {
        guard let ud = UserDefaults(suiteName: SharedConstants.appGroupID) else {
            fatalError("App Group '\(SharedConstants.appGroupID)' not configured in Signing & Capabilities")
        }
        self.defaults = ud
        self.rules = loadRules()
    }

    // MARK: - Public API

    func loadRules() -> [BlockRule] {
        guard let data = defaults.data(forKey: SharedConstants.rulesKey),
              let decoded = try? decoder.decode([BlockRule].self, from: data)
        else { return [] }
        return decoded
    }

    func saveRules(_ rules: [BlockRule]) {
        guard let data = try? encoder.encode(rules) else { return }
        defaults.set(data, forKey: SharedConstants.rulesKey)
        defaults.set(Date().timeIntervalSince1970, forKey: SharedConstants.lastSyncKey)
        defaults.synchronize()
        DispatchQueue.main.async {
            self.rules = rules
        }
    }

    func addRule(_ rule: BlockRule) {
        var current = loadRules()
        current.append(rule)
        saveRules(current)
    }

    func deleteRules(at offsets: IndexSet) {
        var current = loadRules()
        current.remove(atOffsets: offsets)
        saveRules(current)
    }

    func delete(_ rule: BlockRule) {
        let updated = loadRules().filter { $0.id != rule.id }
        saveRules(updated)
    }

    func toggleEnabled(_ rule: BlockRule) {
        var current = loadRules()
        guard let idx = current.firstIndex(where: { $0.id == rule.id }) else { return }
        current[idx].isEnabled.toggle()
        saveRules(current)
    }

    func lastSyncDate() -> Date? {
        let ts = defaults.double(forKey: SharedConstants.lastSyncKey)
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }
}
