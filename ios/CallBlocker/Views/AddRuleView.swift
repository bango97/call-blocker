import SwiftUI

struct AddRuleView: View {
    let onSave: (BlockRule) -> Void

    @StateObject private var vm = AddRuleViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Type", selection: $vm.type) {
                        ForEach(PatternType.allCases) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                } header: {
                    Text("Pattern Type")
                } footer: {
                    patternTypeFooter
                }

                Section("Pattern") {
                    TextField(vm.type.placeholder, text: $vm.pattern)
                        .keyboardType(.phonePad)
                        .autocorrectionDisabled()

                    if vm.expansionCount > 1 {
                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundColor(.secondary)
                            Text("Matches ~\(vm.expansionCount.formatted()) numbers")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }

                    if let error = vm.validationError {
                        Label(error, systemImage: "exclamationmark.triangle.fill")
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                }

                Section("Label (optional)") {
                    TextField("e.g. Spam calls", text: $vm.label)
                }
            }
            .navigationTitle("New Rule")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        if let rule = vm.buildRule() {
                            onSave(rule)
                            dismiss()
                        }
                    }
                    .disabled(!vm.canSave)
                }
            }
        }
    }

    @ViewBuilder
    private var patternTypeFooter: some View {
        switch vm.type {
        case .exact:
            Text("Blocks an exact phone number.")
        case .prefix:
            Text("Blocks all numbers starting with this prefix. Use 6+ digits to stay within limits.")
        case .wildcard:
            Text("Use 'x' as a single-digit wildcard, e.g. 09xx1234 blocks 0900–0999 1234. Up to 4 wildcards.")
        }
    }
}
