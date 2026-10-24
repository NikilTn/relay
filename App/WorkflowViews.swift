import SwiftUI
import RelayCore

struct AccountSignInView: View {
    @EnvironmentObject private var cloud: CloudModel
    @State private var email = ""
    @State private var password = ""
    @State private var code = ""
    @FocusState private var editing: Bool
    var body: some View {
        RelayCard {
            Text("Sign in").font(.title2.weight(.medium))
            Text("Sign in once to send requests or coordinate your shelter. Your account opens the right workspace.").foregroundStyle(.secondary)
            if cloud.signInNeedsCode {
                TextField("Six-digit authenticator code", text: $code).textFieldStyle(WorkflowInput()).focused($editing)
                    .accessibilityIdentifier("loginCode")
                    #if os(iOS)
                    .keyboardType(.numberPad).textContentType(.oneTimeCode)
                    #endif
            } else {
                TextField("Email", text: $email).textFieldStyle(WorkflowInput()).focused($editing).autocorrectionDisabled()
                    .accessibilityIdentifier("loginEmail")
                    #if os(iOS)
                    .textInputAutocapitalization(.never).keyboardType(.emailAddress).textContentType(.username)
                    #endif
                SecureField("Password", text: $password).textFieldStyle(WorkflowInput()).focused($editing).accessibilityIdentifier("loginPassword")
            }
            Button(cloud.busy ? "Signing in…" : cloud.signInNeedsCode ? "Verify and continue" : "Sign in") {
                editing = false
                Task { await cloud.login(username: email, password: password, code: code); password = ""; code = "" }
            }.buttonStyle(PrimaryButton()).disabled(cloud.busy || (cloud.signInNeedsCode ? code.count != 6 : email.isEmpty || password.isEmpty))
                .accessibilityIdentifier("accountSignIn")
            if cloud.signInNeedsCode { Button("Use another account") { cloud.cancelLogin(); code = "" } }
            if cloud.busy { ProgressView() }
            if !cloud.problem.isEmpty { Text(cloud.problem).font(.callout).foregroundStyle(.orange) }
            Text("Use your RELAY test account, not your Apple or AWS console login. The demo organizer provides accounts.").font(.caption).foregroundStyle(.secondary)
            if editing { Button("Done") { editing = false } }
        }
    }
}
struct WorkflowStatus: View {
    @EnvironmentObject private var cloud: CloudModel
    var body: some View {
        HStack(spacing: 8) {
            Rectangle().fill(.secondary).frame(width: 4, height: 4).accessibilityHidden(true)
            Text(cloud.status.contains("unavailable") ? "Waiting to reconnect · your request stays saved" : "Saved locally · sent when cloud is available")
                .font(.caption)
        }.foregroundStyle(.secondary).padding(.horizontal, 4)
    }
}
struct LocationFacts: View {
    let location: RequestLocation
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(location.precision == "approximate" ? "Approximate location" : "Location attached").font(.subheadline.weight(.medium))
            Text(String(format: "%.5f, %.5f · accuracy ±%.0f m", location.latitude, location.longitude, location.horizontal_accuracy)).font(.caption.monospaced())
            Text("Captured \(location.captured_at.formatted(date: .abbreviated, time: .shortened))").font(.caption).foregroundStyle(.secondary)
            if Date().timeIntervalSince(location.captured_at) > 300 { Text("This is an earlier location snapshot. Refresh if you have moved.").font(.caption).foregroundStyle(.orange) }
            if let url = URL(string: "https://maps.apple.com/?ll=\(location.latitude),\(location.longitude)&q=Request%20location") { Link("Open location in Maps", destination: url).font(.subheadline) }
        }
    }
}
struct PublicHelpView: View {
    @ObservedObject var model: RelayModel
    @EnvironmentObject private var cloud: CloudModel
    @StateObject private var locator = RequestLocationModel()
    @State private var reviewing = false
    @FocusState private var editing: Bool
    let sent: (String) -> Void
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                WorkflowHeader(eyebrow: "New request", title: "Get help.", subtitle: "Send a request to your shelter.")
                if cloud.profile == nil { AccountSignInView() }
                else {
                    HStack {
                        Text("To").font(.subheadline).foregroundStyle(.secondary)
                        Spacer()
                        Picker("Shelter", selection: $cloud.draft.shelterID) {
                            Text("Choose shelter").tag("")
                            ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) }
                        }.labelsHidden().accessibilityLabel("Destination shelter").accessibilityIdentifier("destinationShelter")
                    }.padding(.vertical, 4)
                    Divider()
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("What do you need?", text: $cloud.draft.text, axis: .vertical)
                            .font(.title3).lineLimit(4...8).textFieldStyle(.plain).padding(.vertical, 8)
                            .focused($editing).accessibilityLabel("Describe your request").accessibilityIdentifier("requestText")
                        HStack {
                            NavigationLink { VoiceInputView() } label: { Text("Record voice").underline() }
                                .font(.subheadline).disabled(cloud.audioBusy).frame(minHeight: 44)
                            Spacer()
                            Button { editing = false; Task { await cloud.previewRequest() } } label: {
                                HStack(spacing: 7) { if cloud.interpreting { ProgressView().controlSize(.small) }; Text(cloud.interpreting ? "Reading request…" : "Extract details") }
                            }.font(.subheadline.weight(.medium)).buttonStyle(.plain).frame(minHeight: 44)
                                .disabled(cloud.interpreting || cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cloud.draft.shelterID.isEmpty)
                        }
                        if let result = cloud.interpretation, cloud.draft.interpretationText == cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("AI suggestion — check the details below.").font(.caption.weight(.medium))
                                Text(result.result?.proposal?.summary ?? "Review your request details.").font(.subheadline).foregroundStyle(.secondary)
                                ForEach(result.result?.review_reasons ?? [], id: \.self) { WorkflowNotice(text: $0) }
                            }.padding(.vertical, 8)
                        }
                    }
                    Divider()
                    VStack(alignment: .leading, spacing: 14) {
                        Text("Supplies").font(.subheadline.weight(.semibold))
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 135), spacing: 10)], spacing: 10) {
                            ForEach(["water_packs", "food_packs", "blankets", "other"], id: \.self) { item in
                                Button { cloud.draft.item = item } label: {
                                    HStack {
                                        Text(InventoryItem.title(item)).font(.subheadline)
                                        Spacer(minLength: 4)
                                        if cloud.draft.item == item { Text("✓").font(.subheadline.weight(.medium)) }
                                    }.padding(.horizontal, 13).frame(maxWidth: .infinity, minHeight: 47)
                                        .foregroundStyle(cloud.draft.item == item ? RelayTheme.onAction : .primary)
                                        .background(cloud.draft.item == item ? RelayTheme.action : .clear, in: RoundedRectangle(cornerRadius: 6))
                                        .overlay(RoundedRectangle(cornerRadius: 6).strokeBorder(.primary.opacity(cloud.draft.item == item ? 0 : 0.18)))
                                }.buttonStyle(.plain).accessibilityAddTraits(cloud.draft.item == item ? .isSelected : [])
                            }
                        }
                        ViewThatFits(in: .horizontal) {
                            HStack(alignment: .top, spacing: 14) { quantity; people }
                            VStack(alignment: .leading, spacing: 14) { quantity; people }
                        }
                    }
                    Divider().padding(.top, 4)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Location").font(.subheadline.weight(.semibold))
                            Spacer()
                            Button(locator.busy ? "Locating…" : cloud.draft.location == nil ? "Use my location" : "Update") {
                                editing = false; locator.capture { cloud.draft.location = $0; cloud.persistDraft() }
                            }.font(.subheadline).frame(minHeight: 44).disabled(locator.busy)
                        }
                        TextField("Landmark, entrance or room (optional)", text: $cloud.draft.landmark, axis: .vertical)
                            .lineLimit(1...3).textFieldStyle(WorkflowInput()).focused($editing)
                        if let location = cloud.draft.location {
                            LocationFacts(location: location)
                            Button("Remove location") { cloud.draft.location = nil }.font(.caption)
                        }
                        if !locator.problem.isEmpty { WorkflowNotice(text: locator.problem) }
                    }
                    if !cloud.problem.isEmpty { WorkflowNotice(text: cloud.problem) }
                    WorkflowStatus().padding(.vertical, 8)
                }
            }.padding(.horizontal, 24).padding(.vertical, 16).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("")
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if cloud.profile != nil {
                    VStack(spacing: 0) {
                        Divider()
                        Button { editing = false; reviewing = true } label: {
                            HStack { Text("Review request"); Spacer(); Text("→") }.padding(.horizontal, 18)
                        }.buttonStyle(PrimaryButton()).disabled(cloud.submitting || cloud.interpreting || locator.busy || cloud.draft.shelterID.isEmpty || cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                            .padding(.horizontal, 24).padding(.vertical, 12)
                    }.frame(maxWidth: 660).frame(maxWidth: .infinity).background(RelayTheme.canvas)
                }
            }
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } else { NavigationLink("Settings") { WorkflowSettings(model: model) }.font(.caption) } } }
            .onChange(of: cloud.draft) { _, _ in cloud.persistDraft() }
            .sheet(isPresented: $reviewing) { WorkflowReview { id in reviewing = false; sent(id) } }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            #endif
    }
    private var quantity: some View { WorkflowField(title: "Quantity (\(cloud.draft.unit))", placeholder: "Unknown", text: $cloud.draft.quantity, focus: $editing).frame(minWidth: 115) }
    private var people: some View { WorkflowField(title: "People", placeholder: "Unknown", text: $cloud.draft.people, focus: $editing).frame(minWidth: 115) }
}
struct WorkflowReview: View {
    @EnvironmentObject private var cloud: CloudModel
    @Environment(\.dismiss) private var dismiss
    let sent: (String) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Before you send.").font(.system(.largeTitle, design: .serif).weight(.medium))
                    Text(cloud.draft.text)
                    LabeledContent("Shelter", value: cloud.directory.first(where: { $0.shelter_id == cloud.draft.shelterID })?.display_name ?? "Unknown")
                    LabeledContent("Item", value: InventoryItem.title(cloud.draft.item))
                    LabeledContent("Amount", value: cloud.draft.quantity.isEmpty ? "Unknown" : "\(cloud.draft.quantity) \(cloud.draft.unit)")
                    LabeledContent("People", value: cloud.draft.people.isEmpty ? "Unknown" : cloud.draft.people)
                    if !cloud.draft.landmark.isEmpty { Text("Landmark: " + cloud.draft.landmark) }
                    if let location = cloud.draft.location { LocationFacts(location: location) }
                    else { Text("No device location attached").foregroundStyle(.secondary) }
                    if let error = validation { Text(error).foregroundStyle(.orange) }
                    Text("Your request is saved first and sent automatically when the cloud is reachable. Staff will review availability before approving supplies.").font(.subheadline).foregroundStyle(.secondary)
                    Button(cloud.submitting ? "Saving…" : "Send request") {
                        Task { if let id = await cloud.submitRequest() { sent(id) } }
                    }.buttonStyle(PrimaryButton()).disabled(cloud.submitting || validation != nil).accessibilityIdentifier("sendReviewedRequest")
                    if !cloud.problem.isEmpty { Text(cloud.problem).foregroundStyle(.orange) }
                }.padding(24).frame(maxWidth: 620).frame(maxWidth: .infinity)
            }.navigationTitle("Review")
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Edit") { dismiss() }.disabled(cloud.submitting) } }
        }.interactiveDismissDisabled(cloud.submitting)
            #if os(macOS)
            .frame(minWidth: 550, minHeight: 600)
            #endif
    }
    private var validation: String? { do { _ = try cloud.draft.fields(); return nil } catch { return error.localizedDescription } }
}
struct WorkflowRequestsView: View {
    @ObservedObject var model: RelayModel
    @EnvironmentObject private var cloud: CloudModel
    let staff: Bool
    @State private var filter = "Open"
    private var rows: [CloudQueueRecord] {
        cloud.records.filter { !staff || $0.submission.destination_shelter_id == cloud.staffShelterID }.sorted { $0.submission.created_at > $1.submission.created_at }
    }
    private var visibleRows: [CloudQueueRecord] { rows.filter { filter == "All" || (filter == "Closed") == ["completed", "cancelled", "rejected"].contains($0.history?.status ?? "new") } }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkflowHeader(eyebrow: staff ? "Coordinator" : "Your requests", title: staff ? "Inbox" : "Requests", subtitle: staff ? "Requests awaiting your attention." : "Updates from your shelter.")
                if cloud.profile == nil { AccountSignInView() }
                else {
                    HStack {
                        if staff {
                            Picker("Shelter", selection: $cloud.staffShelterID) { ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) } }
                                .onChange(of: cloud.staffShelterID) { _, value in Task { await cloud.loadInbox(shelterID: value) } }
                        } else { Text("\(rows.count) saved request\(rows.count == 1 ? "" : "s")").font(.subheadline).foregroundStyle(.secondary) }
                        Spacer()
                        Button { Task { await cloud.loadInbox(shelterID: staff ? cloud.staffShelterID : nil) } } label: { Image(systemName: "arrow.clockwise").frame(width: 44, height: 44) }
                            .buttonStyle(.plain).disabled(cloud.busy).accessibilityLabel("Refresh requests")
                    }
                    WorkflowFilter(selection: $filter, options: ["Open", "All", "Closed"])
                    if visibleRows.isEmpty { ContentUnavailableView(filter == "Open" ? "No open requests" : "No requests here", systemImage: "tray", description: Text(staff ? "New requests appear here when they reach RELAY." : "Create a request in Help. Your shelter's replies will appear here.")) }
                    ForEach(visibleRows) { record in
                        NavigationLink { WorkflowRequestDetail(id: record.id) } label: {
                            WorkflowRequestCard(record: record, shelter: cloud.directory.first(where: { $0.shelter_id == record.submission.destination_shelter_id })?.display_name ?? "Shelter")
                        }.buttonStyle(.plain)
                    }
                    WorkflowStatus()
                    if !cloud.problem.isEmpty { WorkflowNotice(text: cloud.problem) }
                }
            }.padding(.horizontal, 24).padding(.vertical, 16).frame(maxWidth: 780).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("")
            .toolbar { ToolbarItem(placement: .primaryAction) { NavigationLink("Settings") { WorkflowSettings(model: model) }.font(.caption) } }
            .task { if cloud.canUseCloud { await cloud.loadInbox(shelterID: staff ? cloud.staffShelterID : nil) } }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
    }
    static func progress(_ record: CloudQueueRecord) -> String {
        switch record.history?.status {
        case "accepted": return record.reservation?.status == "reserved" ? "Approved · supplies reserved" : "Accepted by staff"
        case "in_progress": return "In progress"
        case "completed": return record.reservation?.status == "fulfilled" ? "Supplies marked handed over" : "Reported completed"
        case "cancelled": return "Cancelled"
        case "rejected": return "Unable to fulfill"
        default: return record.result == nil ? "Queued" : "Waiting for coordinator"
        }
    }
}
struct WorkflowRequestDetail: View {
    @EnvironmentObject private var cloud: CloudModel
    let id: String
    @State private var reply = ""
    @State private var item = "water_packs"
    @State private var amount = ""
    @State private var confirmingHandover = false
    @FocusState private var editing: Bool
    private var record: CloudQueueRecord? { cloud.records.first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let record {
                VStack(alignment: .leading, spacing: 18) {
                    RelayCard {
                        WorkflowBadge(text: WorkflowRequestsView.progress(record), symbol: ["accepted", "in_progress", "completed"].contains(record.history?.status ?? "") ? "checkmark.circle" : "clock")
                        Text(InventoryItem.title(record.submission.structured_fields?.item_id ?? record.result?.result?.proposal?.item_id ?? "other")).font(.title2.bold())
                        Text(record.submission.original_text)
                        if let fields = record.submission.structured_fields {
                            LabeledContent("Item", value: InventoryItem.title(fields.item_id ?? "other"))
                            LabeledContent("Amount", value: fields.quantity.map { "\($0) \(fields.unit ?? "")" } ?? "Unknown")
                            LabeledContent("People", value: fields.people.map(String.init) ?? "Unknown")
                            if !fields.landmark.isEmpty { Text("Landmark: " + fields.landmark) }
                        }
                        if let location = record.submission.location { LocationFacts(location: location) }
                        DisclosureGroup("Request reference") { Text(record.id).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled) }.font(.caption)
                        Button("Refresh / retry") { Task { await cloud.retry(id); if cloud.isDispatcher { await cloud.refreshInventory() } } }.buttonStyle(WorkflowSecondaryButton()).disabled(cloud.busy)
                    }
                    if let proposal = record.result?.result?.proposal {
                        RelayCard {
                            WorkflowSection(title: "AI interpretation", symbol: "sparkles", subtitle: "A suggestion for staff to review")
                            Text(proposal.summary)
                            Text("\(InventoryItem.title(proposal.item_id ?? "other")) · \(proposal.quantity.map(String.init) ?? "Unknown") \(proposal.unit ?? "")")
                            ForEach(record.result?.result?.review_reasons ?? [], id: \.self) { Text($0).font(.caption).foregroundStyle(.orange) }
                            Text("Staff approval controls inventory. AI cannot allocate supplies.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    if cloud.isDispatcher, record.result != nil { approval(record) }
                    if let reservation = record.reservation {
                        RelayCard {
                            Text("Supplies: \(reservation.status)").font(.headline)
                            Text("\(reservation.quantity) \(reservation.unit) · \(InventoryItem.title(reservation.item_id))")
                        }
                    }
                    RelayCard {
                        WorkflowSection(title: "Updates & replies", symbol: "bubble.left.and.bubble.right.fill")
                        ForEach(record.history?.events ?? []) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.author_role == "dispatcher" ? "Shelter coordinator" : "Requester").font(.caption.bold())
                                if !event.text.isEmpty { Text(event.text) }
                                if let status = event.status { Text(status.replacingOccurrences(of: "_", with: " ")).font(.caption).foregroundStyle(.secondary) }
                            }.padding(.vertical, 10).frame(maxWidth: .infinity, alignment: .leading).overlay(alignment: .bottom) { Divider() }
                        }
                        TextField("Write a reply…", text: $reply, axis: .vertical).lineLimit(2...5).textFieldStyle(WorkflowInput()).focused($editing)
                        Button("Send reply") { let text = reply; editing = false; Task { await cloud.sendEvent(id, text: text, status: nil); if cloud.problem.isEmpty { reply = "" } } }.buttonStyle(WorkflowSecondaryButton()).disabled(cloud.busy || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || record.result == nil || record.pendingEvent != nil)
                        if !cloud.isDispatcher, !["completed", "cancelled", "rejected"].contains(record.history?.status ?? "new") {
                            Button("Cancel request", role: .destructive) { Task { await cloud.sendEvent(id, text: "Requester cancelled this request.", status: "cancelled") } }.disabled(cloud.busy || record.result == nil)
                        }
                    }
                    if let problem = record.problem { Text(problem).foregroundStyle(.orange) }
                    if record.pendingInventory != nil {
                        Text("An inventory action is queued. Retry uses the same operation and cannot reserve stock twice.").font(.caption)
                        if record.state == "needs_attention" { Button("Clear declined action and refresh") { Task { await cloud.discardInventoryConflict(id) } } }
                    }
                    if !cloud.problem.isEmpty { Text(cloud.problem).foregroundStyle(.orange) }
                }.padding(20).frame(maxWidth: 730).frame(maxWidth: .infinity)
            } else { ContentUnavailableView("Request unavailable", systemImage: "tray") }
        }.background(RelayTheme.canvas).navigationTitle("Request")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } } }
            .onDisappear { cloud.focusedRequestID = nil }
            .task {
                cloud.focusedRequestID = id
                if let record {
                    item = record.submission.structured_fields?.item_id ?? record.result?.result?.proposal?.item_id ?? "water_packs"
                    amount = (record.submission.structured_fields?.quantity ?? record.result?.result?.proposal?.quantity).map(String.init) ?? ""
                    if cloud.isDispatcher { cloud.staffShelterID = record.submission.destination_shelter_id; await cloud.refreshInventory() }
                }
            }
            .confirmationDialog("Confirm the supplies were handed over?", isPresented: $confirmingHandover, titleVisibility: .visible) {
                Button("Confirm handover") { Task { await cloud.inventoryAction(id, action: "fulfill") } }
                Button("Cancel", role: .cancel) {}
            }
    }
    @ViewBuilder private func approval(_ record: CloudQueueRecord) -> some View {
        if record.reservation?.status == "reserved" {
            RelayCard {
                WorkflowSection(title: "Supplies reserved", symbol: "shippingbox.fill", subtitle: "Record the next step when it happens.")
                Button("Mark supplies handed over") { confirmingHandover = true }.buttonStyle(PrimaryButton()).disabled(cloud.busy || record.pendingInventory != nil)
                Button("Release reservation", role: .destructive) { Task { await cloud.inventoryAction(id, action: "release") } }.disabled(cloud.busy || record.pendingInventory != nil)
            }
        } else if !["completed", "cancelled", "rejected"].contains(record.history?.status ?? "new") {
            RelayCard {
                WorkflowSection(title: "Approve supplies", symbol: "checkmark.seal.fill")
                Picker("Item", selection: $item) { ForEach(["water_packs", "food_packs", "blankets"], id: \.self) { Text(InventoryItem.title($0)).tag($0) } }
                TextField("Quantity to reserve", text: $amount).textFieldStyle(WorkflowInput()).focused($editing)
                if let stock = cloud.inventory?.items.first(where: { $0.id == item }) { Text("Available: \(stock.available) \(stock.unit) · already reserved: \(stock.reserved)").font(.subheadline) }
                Button("Approve and reserve") { editing = false; Task { await cloud.inventoryAction(id, action: "reserve", item: item, quantity: Int(amount)) } }
                    .buttonStyle(PrimaryButton()).disabled(cloud.busy || cloud.inventoryBusy || record.pendingInventory != nil || (Int(amount) ?? 0) <= 0 || cloud.inventory == nil)
                Text("Approval reserves stock. Handover deducts it. Concurrent approvals cannot overbook available supplies.").font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}
struct InventoryView: View {
    @ObservedObject var model: RelayModel
    @EnvironmentObject private var cloud: CloudModel
    @State private var item = "water_packs"
    @State private var amount = ""
    @State private var note = "Synthetic demo stock"
    @State private var editingStock = false
    @FocusState private var editing: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkflowHeader(eyebrow: "Coordinator", title: "Inventory", subtitle: "Available stock at your shelter.")
                HStack {
                    Picker("Shelter", selection: $cloud.staffShelterID) { ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) } }
                        .onChange(of: cloud.staffShelterID) { _, _ in Task { await cloud.refreshInventory() } }
                    Spacer()
                    Button { Task { await cloud.refreshInventory() } } label: { Image(systemName: "arrow.clockwise").frame(width: 44, height: 44) }
                        .buttonStyle(.plain).disabled(cloud.inventoryBusy).accessibilityLabel("Refresh stock")
                }
                if cloud.inventory == nil && !cloud.inventoryBusy { ContentUnavailableView("Stock not loaded", systemImage: "shippingbox", description: Text("Refresh when your connection is available.")) }
                ForEach((cloud.inventory?.items ?? []).sorted { $0.available == $1.available ? $0.id < $1.id : $0.available > $1.available }) { row in
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(row.title).font(.title3.weight(.medium))
                            Spacer()
                            Text(row.unit.uppercased()).font(.system(.caption2, design: .monospaced)).foregroundStyle(.secondary)
                        }
                        HStack(alignment: .firstTextBaseline) {
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(row.available)").font(.system(.largeTitle, design: .monospaced).weight(.regular)).monospacedDigit()
                                Text("Available").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(row.reserved)").font(.system(.title3, design: .monospaced)).monospacedDigit()
                                Text("Reserved").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                            VStack(alignment: .leading, spacing: 5) {
                                Text("\(row.on_hand)").font(.system(.title3, design: .monospaced)).monospacedDigit()
                                Text("On hand").font(.caption).foregroundStyle(.secondary)
                            }.frame(maxWidth: .infinity, alignment: .leading)
                        }
                        Divider()
                    }.padding(.vertical, 12)
                }
                Text("Approval reserves supplies. Handover deducts stock.").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)
                RelayCard {
                    DisclosureGroup(isExpanded: $editingStock) {
                        VStack(alignment: .leading, spacing: 12) {
                            Picker("Item", selection: $item) { ForEach(["water_packs", "food_packs", "blankets"], id: \.self) { Text(InventoryItem.title($0)).tag($0) } }
                            WorkflowField(title: "Stock change", placeholder: "Add amount, or use − to remove", text: $amount, focus: $editing)
                            WorkflowField(title: "Reason", placeholder: "Why is stock changing?", text: $note, focus: $editing)
                            Button(cloud.pendingAdjustment ? "Retry saved stock change" : "Save stock change") {
                                editing = false; Task { await cloud.adjustInventory(item: item, amount: Int(amount) ?? 0, note: note); if !cloud.pendingAdjustment && cloud.problem.isEmpty { amount = "" } }
                            }.buttonStyle(PrimaryButton()).disabled(cloud.inventoryBusy || (!cloud.pendingAdjustment && (Int(amount) ?? 0) == 0))
                            Text("Use synthetic stock for this demonstration.").font(.caption).foregroundStyle(.secondary)
                        }.padding(.top, 12)
                    } label: { Text("Adjust stock").font(.headline) }
                }
                if cloud.inventoryBusy { ProgressView("Updating stock…").frame(maxWidth: .infinity) }
                if !cloud.problem.isEmpty { WorkflowNotice(text: cloud.problem) }
            }.padding(.horizontal, 24).padding(.vertical, 16).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } else { NavigationLink("Settings") { WorkflowSettings(model: model) }.font(.caption) } } }
            .task { await cloud.refreshInventory(); if cloud.pendingAdjustment { editingStock = true } }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            #endif
    }
    private func stat(_ title: String, value: Int) -> some View { HStack(spacing: 7) { Text(title).font(.caption).foregroundStyle(.secondary); Text("\(value)").font(.subheadline.bold()).monospacedDigit() } }
}
struct WorkflowSettings: View {
    @ObservedObject var model: RelayModel
    @EnvironmentObject private var cloud: CloudModel
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RelayCard {
                    Text("Account").font(.headline)
                    if let profile = cloud.profile {
                        Text(profile.role == "dispatcher" ? "Shelter coordinator" : "Public requester")
                        Text(profile.incident_id).font(.caption).foregroundStyle(.secondary)
                        Text("Switch accounts here to test the other workspace. Saved requests stay with the account that created them.").font(.subheadline)
                        Button("Sign out / switch account") { cloud.signOut() }.disabled(cloud.busy || cloud.audioBusy || cloud.interpreting || cloud.submitting)
                    } else { AccountSignInView() }
                }
                RelayCard {
                    Text("Nearby messaging").font(.headline)
                    Text("Nearby discovery runs while the app is open. Existing messages and receipts remain saved. Cloud requests with location currently use authenticated cloud delivery.").font(.subheadline)
                    NavigationLink("Nearby devices") { NearbyView(model: model, compose: { _ in }) }
                    NavigationLink("Saved offline requests") { HelpRequestsView(model: model) }
                }
                DisclosureGroup("Developer tools") {
                    VStack(alignment: .leading, spacing: 16) {
                        NavigationLink("Diagnostics and test routes") { ToolsView(model: model) }
                        NavigationLink("Offline shelter directory") { ShelterDirectoryView(model: model, choose: { _ in }) }
                        NavigationLink("Offline request form") { HelpHomeView(model: model, openChat: { _ in }, sent: { _ in }, chooseShelter: {}) }
                        NavigationLink("Cloud configuration") { CloudView(model: model) }
                        Text("Build \(Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?") · precise locations are not added to plaintext nearby messages.").font(.caption).foregroundStyle(.secondary)
                    }.padding(.vertical, 12)
                }
            }.padding(20).frame(maxWidth: 650).frame(maxWidth: .infinity)
        }.navigationTitle("Settings").background(RelayTheme.canvas)
            .onAppear { cloud.pollingPaused = true }
            .onDisappear { cloud.pollingPaused = false }
    }
}
