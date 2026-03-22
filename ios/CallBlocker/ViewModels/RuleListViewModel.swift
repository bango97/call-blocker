import Foundation
import CallKit
import Combine

@MainActor
final class RuleListViewModel: ObservableObject {

    @Published var rules: [BlockRule] = []
    @Published var extensionStatus: CXCallDirectoryManager.EnabledStatus = .unknown
    @Published var reloadError: String?
    @Published var isReloading = false
    @Published var totalExpansionCount = 0
    @Published var isOverGlobalCap = false

    private let store = RuleStore.shared
    private var cancellables = Set<AnyCancellable>()

    init() {
        store.$rules
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rules in
                self?.rules = rules
                let total = ExpansionLimiter.totalExpansion(of: rules)
                self?.totalExpansionCount = total
                self?.isOverGlobalCap = total > ExpansionLimiter.globalCap
            }
            .store(in: &cancellables)

        checkExtensionStatus()
    }

    func delete(_ rule: BlockRule) {
        store.delete(rule)
        reloadExtension()
    }

    func deleteRules(at offsets: IndexSet) {
        store.deleteRules(at: offsets)
        reloadExtension()
    }

    func toggleEnabled(_ rule: BlockRule) {
        store.toggleEnabled(rule)
        reloadExtension()
    }

    func checkExtensionStatus() {
        CallDirectoryManager.shared.checkExtensionStatus { [weak self] status in
            Task { @MainActor in
                self?.extensionStatus = status
            }
        }
    }

    func reloadExtension() {
        isReloading = true
        reloadError = nil
        CallDirectoryManager.shared.reload { [weak self] error in
            Task { @MainActor in
                self?.isReloading = false
                self?.reloadError = error?.localizedDescription
                self?.checkExtensionStatus()
            }
        }
    }
}
