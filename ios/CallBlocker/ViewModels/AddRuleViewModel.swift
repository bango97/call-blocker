import Foundation
import Combine

@MainActor
final class AddRuleViewModel: ObservableObject {

    @Published var label: String = ""
    @Published var pattern: String = ""
    @Published var type: PatternType = .exact
    @Published var validationError: String?
    @Published var expansionCount: Int = 0

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Live validation and expansion count as user types
        Publishers.CombineLatest($pattern, $type)
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] pattern, type in
                self?.updateValidation(pattern: pattern, type: type)
            }
            .store(in: &cancellables)
    }

    var canSave: Bool {
        !pattern.isEmpty && validationError == nil
    }

    /// Build a BlockRule from current inputs. Nil if inputs are invalid.
    func buildRule() -> BlockRule? {
        guard canSave else { return nil }
        let clean = normalizePattern(pattern, type: type)
        return BlockRule(
            label: label.isEmpty ? defaultLabel(for: clean, type: type) : label,
            pattern: clean,
            type: type
        )
    }

    // MARK: - Private

    private func updateValidation(pattern: String, type: PatternType) {
        guard !pattern.isEmpty else {
            validationError = nil
            expansionCount = 0
            return
        }

        let clean = normalizePattern(pattern, type: type)
        let draft = BlockRule(pattern: clean, type: type)

        if let err = ExpansionLimiter.validate(draft) {
            validationError = err.localizedDescription
            expansionCount = draft.expansionCount
        } else if !isValidPattern(clean, type: type) {
            validationError = patternFormatHint(for: type)
            expansionCount = 0
        } else {
            validationError = nil
            expansionCount = draft.expansionCount
        }
    }

    private func normalizePattern(_ raw: String, type: PatternType) -> String {
        switch type {
        case .exact, .prefix:
            return raw.filter(\.isNumber)
        case .wildcard:
            return raw.lowercased().filter { $0.isNumber || $0 == "x" }
        }
    }

    private func isValidPattern(_ pattern: String, type: PatternType) -> Bool {
        switch type {
        case .exact:
            return pattern.count >= 7 && pattern.count <= 15
        case .prefix:
            return pattern.count >= 3 && pattern.count <= 9
        case .wildcard:
            return pattern.count >= 7 && pattern.count <= 15
        }
    }

    private func patternFormatHint(for type: PatternType) -> String {
        switch type {
        case .exact:    return "Enter a valid phone number (7–15 digits)."
        case .prefix:   return "Enter 3–9 leading digits (e.g. 0900)."
        case .wildcard: return "Use digits and 'x' as wildcard (e.g. 09xx1234). Length must be 7–15."
        }
    }

    private func defaultLabel(for pattern: String, type: PatternType) -> String {
        switch type {
        case .exact:    return "Block \(pattern)"
        case .prefix:   return "Block prefix \(pattern)"
        case .wildcard: return "Block pattern \(pattern)"
        }
    }
}
