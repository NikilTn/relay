import SwiftUI
import RelayCore

// A restrained field notebook: type, spacing and rules carry the hierarchy.
struct WorkflowHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("RELAY").font(.system(.caption, design: .monospaced).weight(.bold)).tracking(2)
                Spacer()
                Text(eyebrow.uppercased()).font(.system(.caption2, design: .monospaced)).tracking(1).foregroundStyle(.secondary)
            }
            Rectangle().fill(RelayTheme.accent).frame(width: 26, height: 3).accessibilityHidden(true)
            Text(title).font(.system(.largeTitle, design: .serif).weight(.medium)).tracking(-0.5)
                .fixedSize(horizontal: false, vertical: true)
            if !subtitle.isEmpty { Text(subtitle).font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true) }
        }.frame(maxWidth: .infinity, alignment: .leading).padding(.top, 8).padding(.bottom, 14)
    }
}
struct WorkflowSection: View {
    let title: String
    let symbol: String // Retains old call sites; decorative section symbols are intentionally not drawn.
    var subtitle: String? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.headline.weight(.semibold))
            if let subtitle { Text(subtitle).font(.caption).foregroundStyle(.secondary) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
struct WorkflowInput: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration.font(.body).padding(.horizontal, 12).padding(.vertical, 13).frame(minHeight: 46)
            .background(RelayTheme.incoming, in: RoundedRectangle(cornerRadius: 7))
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.primary.opacity(0.13)))
    }
}
struct WorkflowSecondaryButton: ButtonStyle {
    @Environment(\.isEnabled) private var enabled
    func makeBody(configuration: Configuration) -> some View {
        configuration.label.font(.subheadline.weight(.semibold)).frame(maxWidth: .infinity, minHeight: 46)
            .foregroundStyle(enabled ? Color.primary : .secondary)
            .overlay(RoundedRectangle(cornerRadius: 7).strokeBorder(.primary.opacity(enabled ? 0.25 : 0.08)))
            .opacity(configuration.isPressed ? 0.55 : 1)
    }
}
struct WorkflowBadge: View {
    let text: String
    var symbol = "clock"
    var color: Color = RelayTheme.accent
    var body: some View {
        Text(text).font(.caption.weight(.medium)).fixedSize(horizontal: false, vertical: true).foregroundStyle(color)
    }
}
struct WorkflowNotice: View {
    let text: String
    var body: some View {
        HStack(spacing: 12) {
            Rectangle().fill(RelayTheme.accent).frame(width: 2)
            Text(text).font(.callout).fixedSize(horizontal: false, vertical: true)
        }.fixedSize(horizontal: false, vertical: true).padding(.vertical, 8)
    }
}
struct WorkflowField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var focus: FocusState<Bool>.Binding
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            TextField(placeholder, text: $text).textFieldStyle(WorkflowInput()).focused(focus).accessibilityLabel(title)
        }
    }
}
struct WorkflowRequestCard: View {
    let record: CloudQueueRecord
    let shelter: String
    private var item: String { record.submission.structured_fields?.item_id ?? record.result?.result?.proposal?.item_id ?? "other" }
    private var quantity: String? { (record.submission.structured_fields?.quantity ?? record.result?.result?.proposal?.quantity).map(String.init) }
    private var closed: Bool { ["cancelled", "rejected", "completed"].contains(record.history?.status ?? "") }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text(shelter.uppercased()).font(.system(.caption2, design: .monospaced)).tracking(0.5).foregroundStyle(.secondary)
                Spacer()
                Text(record.submission.created_at, format: .dateTime.month().day().hour().minute()).font(.caption2).foregroundStyle(.secondary)
            }
            HStack(alignment: .firstTextBaseline) {
                Text(InventoryItem.title(item)).font(.title3.weight(.semibold))
                Spacer(minLength: 12)
                if let quantity { Text(quantity).font(.system(.title2, design: .monospaced).weight(.medium)) }
            }
            Text(record.submission.original_text).font(.subheadline).foregroundStyle(.secondary).lineLimit(2)
            HStack {
                WorkflowBadge(text: WorkflowRequestsView.progress(record), color: closed ? .secondary : RelayTheme.accent)
                Spacer()
                Image(systemName: "arrow.up.right").font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
            }
            Divider().padding(.top, 10)
        }.padding(.top, 14).multilineTextAlignment(.leading).contentShape(Rectangle())
    }
}
struct WorkflowFilter: View {
    @Binding var selection: String
    let options: [String]
    var body: some View {
        HStack(spacing: 24) {
            ForEach(options, id: \.self) { option in
                Button { selection = option } label: {
                    VStack(spacing: 10) {
                        Text(option).font(.subheadline.weight(selection == option ? .semibold : .regular))
                            .foregroundStyle(selection == option ? .primary : .secondary)
                        Rectangle().fill(selection == option ? RelayTheme.action : .clear).frame(height: 2)
                    }.frame(minHeight: 44)
                }.buttonStyle(.plain).accessibilityAddTraits(selection == option ? .isSelected : [])
            }
            Spacer(minLength: 0)
        }.overlay(alignment: .bottom) { Rectangle().fill(.primary.opacity(0.10)).frame(height: 0.5) }
    }
}
