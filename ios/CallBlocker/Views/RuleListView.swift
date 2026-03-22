import SwiftUI
import CallKit

struct RuleListView: View {
    @StateObject private var vm = RuleListViewModel()
    @State private var showAddRule = false

    var body: some View {
        NavigationStack {
            List {
                statusSection
                if !vm.rules.isEmpty {
                    rulesSection
                }
            }
            .navigationTitle("Call Blocker")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showAddRule = true } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    if vm.isReloading {
                        ProgressView().scaleEffect(0.8)
                    }
                }
            }
            .sheet(isPresented: $showAddRule) {
                AddRuleView { newRule in
                    RuleStore.shared.addRule(newRule)
                    vm.reloadExtension()
                }
            }
            .alert("Reload Error", isPresented: .init(
                get: { vm.reloadError != nil },
                set: { if !$0 { vm.reloadError = nil } }
            )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(vm.reloadError ?? "")
            }
        }
    }

    // MARK: - Sections

    private var statusSection: some View {
        Section("Status") {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.subheadline)
            }
            if vm.isOverGlobalCap {
                Label(
                    "Total expansion (\(vm.totalExpansionCount.formatted())) exceeds limit (\(ExpansionLimiter.globalCap.formatted())). Some rules may be inactive.",
                    systemImage: "exclamationmark.triangle.fill"
                )
                .foregroundColor(.orange)
                .font(.footnote)
            }
        }
    }

    private var rulesSection: some View {
        Section("Rules (\(vm.rules.count))") {
            ForEach(vm.rules) { rule in
                RuleRowView(rule: rule) {
                    vm.toggleEnabled(rule)
                }
            }
            .onDelete { offsets in
                vm.deleteRules(at: offsets)
            }
        }
    }

    // MARK: - Helpers

    private var statusIcon: String {
        switch vm.extensionStatus {
        case .enabled:  return "shield.fill"
        case .disabled: return "shield.slash"
        default:        return "shield"
        }
    }

    private var statusColor: Color {
        switch vm.extensionStatus {
        case .enabled:  return .green
        case .disabled: return .red
        default:        return .secondary
        }
    }

    private var statusText: String {
        switch vm.extensionStatus {
        case .enabled:
            return "Call blocking active — \(vm.rules.filter(\.isEnabled).count) rule(s) enabled"
        case .disabled:
            return "Disabled — go to Settings → Phone → Call Blocking to enable"
        default:
            return "Status unknown"
        }
    }
}
