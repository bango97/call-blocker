import SwiftUI

struct RuleRowView: View {
    let rule: BlockRule
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Toggle("", isOn: .init(get: { rule.isEnabled }, set: { _ in onToggle() }))
                .labelsHidden()
                .tint(.red)

            VStack(alignment: .leading, spacing: 2) {
                Text(rule.label.isEmpty ? rule.pattern : rule.label)
                    .font(.body)
                    .foregroundColor(rule.isEnabled ? .primary : .secondary)

                HStack(spacing: 6) {
                    typeBadge
                    Text(rule.pattern)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if rule.type != .exact {
                        Text("≈ \(rule.expansionCount.formatted()) numbers")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var typeBadge: some View {
        Text(rule.type.displayName)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(badgeColor.opacity(0.15))
            .foregroundColor(badgeColor)
            .clipShape(Capsule())
    }

    private var badgeColor: Color {
        switch rule.type {
        case .exact:    return .blue
        case .prefix:   return .orange
        case .wildcard: return .purple
        }
    }
}
