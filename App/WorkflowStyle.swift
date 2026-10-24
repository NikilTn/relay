import SwiftUI
import RelayCore

// Shared presentation only; transport, request IDs and inventory rules are unchanged.
enum WorkflowPalette {
    static let navy = Color(red: 0.055, green: 0.12, blue: 0.17)
    static let mint = Color(red: 0.47, green: 0.91, blue: 0.77)
    static func symbol(_ item: String) -> String {
        switch item { case "water_packs": return "drop.fill"; case "food_packs": return "fork.knife"; case "blankets": return "bed.double.fill"; default: return "hands.sparkles.fill" }
    }
    static func color(_ item: String) -> Color {
        switch item { case "water_packs": return .blue; case "food_packs": return .orange; case "blankets": return .purple; default: return RelayTheme.accent }
    }
}
struct WorkflowHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: "point.3.connected.trianglepath.dotted").font(.subheadline.bold())
                Text("RELAY").tracking(2).font(.caption.bold())
                Spacer()
                Text(eyebrow.uppercased()).tracking(1).font(.caption2.weight(.semibold))
            }.foregroundStyle(WorkflowPalette.mint)
            Text(title).font(.largeTitle.weight(.bold)).foregroundStyle(.white).fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.subheadline).foregroundStyle(.white.opacity(0.80)).fixedSize(horizontal: false, vertical: true)
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(WorkflowPalette.navy, in: RoundedRectangle(cornerRadius: 24))
    }
}
struct WorkflowSection: View {
    let title: String
    let symbol: String
    var subtitle: String? = nil
    var body: some View {
        HStack(alignment: .top, spacing: 11) {
            Image(systemName: symbol).font(.subheadline.weight(.semibold)).foregroundStyle(RelayTheme.accent)
                .frame(width: 32, height: 32).background(RelayTheme.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(title).font(.headline)
                if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
            }.frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
struct WorkflowInput: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(.body).padding(12).frame(minHeight: 46)
            .background(RelayTheme.canvas, in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(.primary.opacity(0.08)))
    }
}
struct WorkflowSecondaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(enabled ? RelayTheme.accent : .secondary)
            .background(RelayTheme.accent.opacity(enabled ? 0.10 : 0.04), in: RoundedRectangle(cornerRadius: 13))
            .opacity(configuration.isPressed ? 0.65 : 1)
    }
}
struct SupplyIcon: View {
    let item: String
    var body: some View {
        Image(systemName: WorkflowPalette.symbol(item)).font(.title3.weight(.semibold))
            .foregroundStyle(WorkflowPalette.color(item)).frame(width: 44, height: 44)
            .background(WorkflowPalette.color(item).opacity(0.11), in: RoundedRectangle(cornerRadius: 14))
            .accessibilityHidden(true)
    }
}
struct WorkflowBadge: View {
    let text: String
    var symbol = "clock"
    var color: Color = RelayTheme.accent
    var body: some View {
        Label(text, systemImage: symbol).font(.caption.weight(.semibold))
            .fixedSize(horizontal: false, vertical: true).foregroundStyle(color)
            .padding(.horizontal, 10).padding(.vertical, 7)
            .background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
    }
}
struct WorkflowNotice: View {
    let text: String
    var body: some View {
        Label(text, systemImage: "exclamationmark.circle.fill").font(.callout)
            .foregroundStyle(.orange).padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.orange.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }
}
struct WorkflowField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            TextField(placeholder, text: $text).textFieldStyle(WorkflowInput()).focused(focus).accessibilityLabel(title)
        }
    }
}
struct WorkflowRequestCard: View {
    let record: CloudQueueRecord
    let shelter: String
    private var item: String { record.submission.structured_fields?.item_id ?? record.result?.result?.proposal?.item_id ?? "other" }
    private var quantity: String? {
        (record.submission.structured_fields?.quantity ?? record.result?.result?.proposal?.quantity).map(String.init)
    }
    var body: some View {
        RelayCard {
            HStack(spacing: 12) {
                SupplyIcon(item: item)
                VStack(alignment: .leading, spacing: 4) {
                    Text(InventoryItem.title(item)).font(.headline)
                    Text(shelter).font(.caption).foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if let quantity { Text(quantity).font(.title2.weight(.bold)).monospacedDigit() }
                Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary)
            }
            Text(record.submission.original_text).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            ViewThatFits(in: .horizontal) {
                HStack { status; Spacer(minLength: 10); time }
                VStack(alignment: .leading, spacing: 8) { status; time }
            }
        }.multilineTextAlignment(.leading)
    }
    private var status: some View {
        WorkflowBadge(text: WorkflowRequestsView.progress(record), symbol: ["accepted", "in_progress", "completed"].contains(record.history?.status ?? "") ? "checkmark.circle" : "clock",
                      color: ["cancelled", "rejected"].contains(record.history?.status ?? "") ? .secondary : RelayTheme.accent)
    }
    private var time: some View { Text(record.submission.created_at, format: .dateTime.month().day().hour().minute()).font(.caption2).foregroundStyle(.secondary) }
}
