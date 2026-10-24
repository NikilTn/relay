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
            Label("Welcome to RELAY", systemImage: "hands.sparkles.fill").font(.title2.bold())
            Text("Sign in once to send requests or coordinate your shelter. Your account opens the right workspace.").foregroundStyle(.secondary)
            if cloud.signInNeedsCode {
                TextField("Six-digit authenticator code", text: $code).textFieldStyle(.roundedBorder).focused($editing)
                    .accessibilityIdentifier("loginCode")
                    #if os(iOS)
                    .keyboardType(.numberPad).textContentType(.oneTimeCode)
                    #endif
            } else {
                TextField("Email", text: $email).textFieldStyle(.roundedBorder).focused($editing).autocorrectionDisabled()
                    .accessibilityIdentifier("loginEmail")
                    #if os(iOS)
                    .textInputAutocapitalization(.never).keyboardType(.emailAddress).textContentType(.username)
                    #endif
                SecureField("Password", text: $password).textFieldStyle(.roundedBorder).focused($editing).accessibilityIdentifier("loginPassword")
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
            Image(systemName: cloud.status.contains("unavailable") ? "clock" : "cloud.fill")
            Text(cloud.status.contains("unavailable") ? "Waiting for connection · requests stay saved" : cloud.profile == nil ? "Your requests start here" : "Cloud delivery is automatic")
                .font(.caption)
        }.foregroundStyle(.secondary)
    }
}
struct LocationFacts: View {
    let location: RequestLocation
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Label(location.precision == "approximate" ? "Approximate location" : "Location attached", systemImage: "location.fill").font(.subheadline.bold())
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
            VStack(alignment: .leading, spacing: 20) {
                Text("What do you need?").font(.largeTitle.bold())
                WorkflowStatus()
                if cloud.profile == nil { AccountSignInView() }
                else {
                    RelayCard {
                        Text("Send to a shelter").font(.headline)
                        Picker("Shelter", selection: $cloud.draft.shelterID) {
                            Text("Choose shelter").tag("")
                            ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) }
                        }.accessibilityIdentifier("destinationShelter")
                        if cloud.directory.isEmpty { Text("No authorized shelter is available. Your draft stays saved.").foregroundStyle(.secondary) }
                    }
                    RelayCard {
                        NavigationLink { VoiceInputView() } label: {
                            Label("Speak your request", systemImage: "mic.fill").font(.headline).frame(maxWidth: .infinity, minHeight: 46)
                        }.buttonStyle(.borderedProminent).disabled(cloud.audioBusy)
                        TextField("Or type what you need", text: $cloud.draft.text, axis: .vertical).lineLimit(3...7).textFieldStyle(.roundedBorder).focused($editing).accessibilityIdentifier("requestText")
                        Button { editing = false; Task { await cloud.previewRequest() } } label: {
                            Label(cloud.interpreting ? "Preparing your request…" : "Prepare structured request", systemImage: "sparkles")
                        }.buttonStyle(.bordered).disabled(cloud.interpreting || cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || cloud.draft.shelterID.isEmpty)
                        if cloud.interpreting { ProgressView() }
                        if let result = cloud.interpretation, cloud.draft.interpretationText == cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines) {
                            Text(result.result?.proposal?.summary ?? "Review the fields below.").font(.subheadline)
                            ForEach(result.result?.review_reasons ?? [], id: \.self) { Text($0).font(.caption).foregroundStyle(.orange) }
                            Text("AI prepared these fields. Check and edit them before sending.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    RelayCard {
                        Text("Request details").font(.headline)
                        Picker("Item", selection: $cloud.draft.item) {
                            ForEach(["water_packs", "food_packs", "blankets", "other"], id: \.self) { Text(InventoryItem.title($0)).tag($0) }
                        }
                        HStack {
                            TextField("Quantity (optional)", text: $cloud.draft.quantity).textFieldStyle(.roundedBorder).focused($editing).accessibilityLabel("Quantity")
                            Text(cloud.draft.unit).foregroundStyle(.secondary)
                        }
                        TextField("People affected (optional)", text: $cloud.draft.people).textFieldStyle(.roundedBorder).focused($editing)
                    }
                    RelayCard {
                        Text("Where is help needed?").font(.headline)
                        TextField("Landmark, entrance or room (optional)", text: $cloud.draft.landmark, axis: .vertical).lineLimit(1...3).textFieldStyle(.roundedBorder).focused($editing)
                        Button { editing = false; locator.capture { cloud.draft.location = $0; cloud.persistDraft() } } label: {
                            Label(locator.busy ? "Finding location…" : cloud.draft.location == nil ? "Use current location" : "Refresh location", systemImage: "location")
                        }.buttonStyle(.bordered).disabled(locator.busy)
                        if let location = cloud.draft.location {
                            LocationFacts(location: location)
                            Button("Remove location") { cloud.draft.location = nil }
                        }
                        if !locator.problem.isEmpty { Text(locator.problem).font(.caption).foregroundStyle(.orange) }
                        Text("Optional. Your location snapshot is sent to the authorized shelter with this request.").font(.caption).foregroundStyle(.secondary)
                    }
                    if !cloud.problem.isEmpty { Text(cloud.problem).foregroundStyle(.orange).font(.callout) }
                    Button { editing = false; reviewing = true } label: { Label("Review and send", systemImage: "arrow.right") }
                        .buttonStyle(PrimaryButton()).disabled(cloud.submitting || cloud.interpreting || locator.busy || cloud.draft.shelterID.isEmpty || cloud.draft.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    Text("Saved on this phone while you compose. Sending does not guarantee staff acceptance.").font(.caption).foregroundStyle(.secondary)
                }
            }.padding(20).frame(maxWidth: 660).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("Help")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } else { NavigationLink { WorkflowSettings(model: model) } label: { Image(systemName: "gearshape") } } } }
            .onChange(of: cloud.draft) { _, _ in cloud.persistDraft() }
            .sheet(isPresented: $reviewing) { WorkflowReview { id in reviewing = false; sent(id) } }
            #if os(iOS)
            .scrollDismissesKeyboard(.interactively)
            #endif
    }
}
struct WorkflowReview: View {
    @EnvironmentObject private var cloud: CloudModel
    @Environment(\.dismiss) private var dismiss
    let sent: (String) -> Void
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("Check your request").font(.title2.bold())
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
    private var rows: [CloudQueueRecord] {
        cloud.records.filter { !staff || $0.submission.destination_shelter_id == cloud.staffShelterID }.sorted { $0.submission.created_at > $1.submission.created_at }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(staff ? "Shelter inbox" : "My requests").font(.largeTitle.bold())
                    Spacer()
                    Button { Task { await cloud.loadInbox(shelterID: staff ? cloud.staffShelterID : nil) } } label: { Image(systemName: "arrow.clockwise") }.disabled(cloud.busy)
                }
                if cloud.profile == nil { AccountSignInView() }
                else {
                    if staff {
                        Picker("Shelter", selection: $cloud.staffShelterID) { ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) } }
                            .onChange(of: cloud.staffShelterID) { _, value in Task { await cloud.loadInbox(shelterID: value) } }
                    }
                    WorkflowStatus()
                    if rows.isEmpty { ContentUnavailableView(staff ? "No requests yet" : "Your requests will appear here", systemImage: "tray", description: Text(staff ? "New requests arrive automatically. Refresh to check now." : "Create a request in Help.")) }
                    ForEach(rows) { record in
                        NavigationLink { WorkflowRequestDetail(id: record.id) } label: {
                            RelayCard {
                                HStack {
                                    Text(InventoryItem.title(record.submission.structured_fields?.item_id ?? record.result?.result?.proposal?.item_id ?? "other")).font(.headline)
                                    Spacer(); Image(systemName: "chevron.right").font(.caption)
                                }
                                Text(record.submission.original_text).lineLimit(2).foregroundStyle(.primary)
                                Text(Self.progress(record)).font(.subheadline.weight(.medium)).foregroundStyle(RelayTheme.accent)
                                Text(record.result == nil ? "Saved on phone · waiting to send" : "Received by RELAY").font(.caption).foregroundStyle(.secondary)
                                Text(record.submission.created_at, format: .dateTime.month().day().hour().minute()).font(.caption).foregroundStyle(.secondary)
                            }.multilineTextAlignment(.leading)
                        }.buttonStyle(.plain)
                    }
                    if !cloud.problem.isEmpty { Text(cloud.problem).font(.caption).foregroundStyle(.orange) }
                }
            }.padding(20).frame(maxWidth: 780).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle(staff ? "Inbox" : "Requests")
            .toolbar { ToolbarItem(placement: .primaryAction) { NavigationLink { WorkflowSettings(model: model) } label: { Image(systemName: "gearshape") } } }
            .task { if cloud.canUseCloud { await cloud.loadInbox(shelterID: staff ? cloud.staffShelterID : nil) } }
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
                        Text(WorkflowRequestsView.progress(record)).font(.title2.bold())
                        Text(record.submission.original_text)
                        if let fields = record.submission.structured_fields {
                            LabeledContent("Item", value: InventoryItem.title(fields.item_id ?? "other"))
                            LabeledContent("Amount", value: fields.quantity.map { "\($0) \(fields.unit ?? "")" } ?? "Unknown")
                            LabeledContent("People", value: fields.people.map(String.init) ?? "Unknown")
                            if !fields.landmark.isEmpty { Text("Landmark: " + fields.landmark) }
                        }
                        if let location = record.submission.location { LocationFacts(location: location) }
                        Text(record.id).font(.caption.monospaced()).foregroundStyle(.secondary).textSelection(.enabled)
                        Button("Refresh / retry") { Task { await cloud.retry(id); if cloud.isDispatcher { await cloud.refreshInventory() } } }.disabled(cloud.busy)
                    }
                    if let proposal = record.result?.result?.proposal {
                        RelayCard {
                            Label("AI interpretation", systemImage: "sparkles").font(.headline)
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
                        Text("Conversation").font(.headline)
                        ForEach(record.history?.events ?? []) { event in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(event.author_role == "dispatcher" ? "Shelter coordinator" : "Requester").font(.caption.bold())
                                if !event.text.isEmpty { Text(event.text) }
                                if let status = event.status { Text(status.replacingOccurrences(of: "_", with: " ")).font(.caption).foregroundStyle(.secondary) }
                            }.padding(.vertical, 5)
                        }
                        TextField("Reply", text: $reply, axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder).focused($editing)
                        Button("Send reply") { let text = reply; editing = false; Task { await cloud.sendEvent(id, text: text, status: nil); if cloud.problem.isEmpty { reply = "" } } }.disabled(cloud.busy || reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || record.result == nil || record.pendingEvent != nil)
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
                Text("Reservation ready").font(.headline)
                Button("Mark supplies handed over") { confirmingHandover = true }.buttonStyle(.borderedProminent).disabled(cloud.busy || record.pendingInventory != nil)
                Button("Release reservation", role: .destructive) { Task { await cloud.inventoryAction(id, action: "release") } }.disabled(cloud.busy || record.pendingInventory != nil)
            }
        } else if !["completed", "cancelled", "rejected"].contains(record.history?.status ?? "new") {
            RelayCard {
                Text("Approve supplies").font(.headline)
                Picker("Item", selection: $item) { ForEach(["water_packs", "food_packs", "blankets"], id: \.self) { Text(InventoryItem.title($0)).tag($0) } }
                TextField("Quantity to reserve", text: $amount).textFieldStyle(.roundedBorder).focused($editing)
                if let stock = cloud.inventory?.items.first(where: { $0.id == item }) { Text("Available: \(stock.available) \(stock.unit) · already reserved: \(stock.reserved)").font(.subheadline) }
                Button("Approve and reserve") { editing = false; Task { await cloud.inventoryAction(id, action: "reserve", item: item, quantity: Int(amount)) } }
                    .buttonStyle(.borderedProminent).disabled(cloud.busy || cloud.inventoryBusy || record.pendingInventory != nil || (Int(amount) ?? 0) <= 0 || cloud.inventory == nil)
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
    @FocusState private var editing: Bool
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Shelter inventory").font(.largeTitle.bold())
                Picker("Shelter", selection: $cloud.staffShelterID) { ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) } }
                    .onChange(of: cloud.staffShelterID) { _, _ in Task { await cloud.refreshInventory() } }
                Button("Refresh stock") { Task { await cloud.refreshInventory() } }.disabled(cloud.inventoryBusy)
                ForEach(cloud.inventory?.items ?? []) { row in
                    RelayCard {
                        Text(row.title).font(.headline)
                        HStack {
                            stat("Available", value: row.available)
                            Spacer(); stat("Reserved", value: row.reserved)
                            Spacer(); stat("On hand", value: row.on_hand)
                        }
                        Text("Unit: \(row.unit)").font(.caption).foregroundStyle(.secondary)
                    }
                }
                RelayCard {
                    Text("Record stock change").font(.headline)
                    Picker("Item", selection: $item) { ForEach(["water_packs", "food_packs", "blankets"], id: \.self) { Text(InventoryItem.title($0)).tag($0) } }
                    TextField("Amount to add (negative to remove)", text: $amount).textFieldStyle(.roundedBorder).focused($editing)
                    TextField("Reason", text: $note).textFieldStyle(.roundedBorder).focused($editing)
                    Button(cloud.pendingAdjustment ? "Retry saved stock change" : "Save stock change") {
                        editing = false; Task { await cloud.adjustInventory(item: item, amount: Int(amount) ?? 0, note: note); if !cloud.pendingAdjustment && cloud.problem.isEmpty { amount = "" } }
                    }.buttonStyle(.borderedProminent).disabled(cloud.inventoryBusy || (!cloud.pendingAdjustment && (Int(amount) ?? 0) == 0))
                    Text("Use synthetic stock for this demonstration. Stock is shared by authorized coordinators and persists in AWS.").font(.caption).foregroundStyle(.secondary)
                }
                if cloud.inventoryBusy { ProgressView() }
                if !cloud.problem.isEmpty { Text(cloud.problem).foregroundStyle(.orange) }
            }.padding(20).frame(maxWidth: 700).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("Inventory")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } else { NavigationLink { WorkflowSettings(model: model) } label: { Image(systemName: "gearshape") } } } }
            .task { await cloud.refreshInventory() }
    }
    private func stat(_ title: String, value: Int) -> some View { VStack(alignment: .leading, spacing: 4) { Text("\(value)").font(.title2.bold()); Text(title).font(.caption).foregroundStyle(.secondary) } }
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
