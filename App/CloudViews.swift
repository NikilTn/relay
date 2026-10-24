import SwiftUI
import UniformTypeIdentifiers
import RelayCore

struct CloudView: View {
    @ObservedObject var model: RelayModel
    @EnvironmentObject private var cloud: CloudModel
    @FocusState private var editing: Bool
    @State private var localID = ""
    @State private var cloudID = ""
    @State private var inboxID = ""
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                RelayCard {
                    Label("Cloud connection", systemImage: "cloud").font(.headline)
                    Text(cloud.status).font(.subheadline)
                    if cloud.profile == nil {
                        TextField("HTTPS API address", text: $cloud.endpoint).textFieldStyle(.roundedBorder).focused($editing)
                            .autocorrectionDisabled()
                            #if os(iOS)
                            .textInputAutocapitalization(.never).keyboardType(.URL)
                            #endif
                        Button("Sign in securely") { Task { await cloud.connect(signIn: true) } }.buttonStyle(.borderedProminent).disabled(cloud.busy || cloud.endpoint.isEmpty)
                        Text("An enrolled account and hosted API are required. Nearby messages and saved requests work without signing in.").font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text("\(cloud.profile!.role.capitalized) · \(cloud.profile!.incident_id)").font(.caption)
                        HStack {
                            Button("Sync now") { Task { await cloud.sync() } }.disabled(cloud.busy)
                            Button("Sign out") { cloud.signOut() }.disabled(cloud.busy || cloud.audioBusy)
                        }.buttonStyle(.bordered)
                    }
                    if cloud.busy { ProgressView() }
                    if !cloud.problem.isEmpty { Text(cloud.problem).font(.caption).foregroundStyle(.orange).textSelection(.enabled) }
                }
                if cloud.profile != nil {
                    RelayCard {
                        Text("Link a saved shelter").font(.headline)
                        Text("Choose which authorized cloud inbox corresponds to a shelter saved on this device. Existing peer addresses stay the same.").font(.subheadline).foregroundStyle(.secondary)
                        Picker("Saved on this device", selection: $localID) {
                            Text("Choose local shelter").tag("")
                            ForEach(model.shelters) { Text($0.name).tag($0.id) }
                        }
                        Picker("Cloud inbox", selection: $cloudID) {
                            Text("Choose cloud shelter").tag("")
                            ForEach(cloud.directory) { Text($0.display_name).tag($0.id) }
                        }
                        Button("Link destination") { Task { await cloud.bind(localID: localID, cloudID: cloudID) } }.disabled(localID.isEmpty || cloudID.isEmpty)
                        ForEach(cloud.bindings, id: \.localID) { binding in
                            Text("\(model.shelters.first { $0.id == binding.localID }?.name ?? String(binding.localID.prefix(8))) → \(cloud.directory.first { $0.shelter_id == binding.shelterID }?.display_name ?? binding.shelterID)").font(.caption)
                        }
                    }
                    NavigationLink { VoiceInputView() } label: { Label("Record a request", systemImage: "mic.fill") }.buttonStyle(.borderedProminent)
                    RelayCard {
                        Text(cloud.isDispatcher ? "Operations inbox" : "Cloud requests").font(.headline)
                        if cloud.isDispatcher {
                            Picker("Shelter", selection: $inboxID) {
                                Text("Choose a shelter").tag("")
                                ForEach(cloud.directory) { Text($0.display_name).tag($0.shelter_id) }
                            }
                            Button("Load shelter requests") { Task { await cloud.loadInbox(shelterID: inboxID) } }.disabled(inboxID.isEmpty || cloud.busy)
                        }
                        Button("Load my cloud requests") { Task { await cloud.loadInbox() } }.disabled(cloud.busy)
                        Text("Local requests can be queued from Requests → request → Cloud delivery. Future requests offer cloud delivery during review.").font(.caption).foregroundStyle(.secondary)
                    }
                    ForEach(cloud.records.sorted { $0.submission.created_at > $1.submission.created_at }) { record in
                        NavigationLink { CloudRequestDetail(id: record.id) } label: {
                            RelayCard {
                                Text(record.submission.original_text).lineLimit(3)
                                Text(record.result == nil ? "Saved locally for cloud · \(record.state)" : "Cloud accepted · \(record.result!.analysis_state.replacingOccurrences(of: "_", with: " "))").font(.caption).foregroundStyle(RelayTheme.accent)
                                if let problem = record.problem { Text(problem).font(.caption).foregroundStyle(.orange) }
                            }.multilineTextAlignment(.leading)
                        }.buttonStyle(.plain)
                    }
                }
            }.padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("Cloud")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } } }
    }
}
struct CloudRequestPanel: View {
    @EnvironmentObject private var cloud: CloudModel
    let message: RelayMessage
    var body: some View {
        RelayCard {
            Label("Cloud delivery", systemImage: "cloud").font(.headline)
            if let record = cloud.records.first(where: { $0.id == message.id }) {
                Text(record.result == nil ? "Queued on this device" : "Accepted by cloud")
                NavigationLink("Open analysis and replies") { CloudRequestDetail(id: message.id) }
            } else {
                Text("Nearby delivery and cloud acceptance are tracked separately.").font(.caption).foregroundStyle(.secondary)
                Button("Queue this request for cloud") { Task { await cloud.queue(message) } }.disabled(!cloud.canUseCloud)
            }
            if !cloud.problem.isEmpty { Text(cloud.problem).font(.caption).foregroundStyle(.orange) }
        }
    }
}
struct CloudRequestDetail: View {
    @EnvironmentObject private var cloud: CloudModel
    let id: String
    @FocusState private var editing: Bool
    @State private var reply = ""
    @State private var progress = ""
    private var record: CloudQueueRecord? { cloud.records.first { $0.id == id } }
    var body: some View {
        ScrollView {
            if let record {
                VStack(alignment: .leading, spacing: 20) {
                    RelayCard {
                        Text("Original request").font(.headline); Text(record.submission.original_text)
                        Text(record.id).font(.caption.monospaced()).textSelection(.enabled)
                        Text(record.result == nil ? "Queued for cloud" : "Cloud accepted").foregroundStyle(RelayTheme.accent)
                        if let problem = record.problem { Text(problem).foregroundStyle(.orange) }
                        Button("Refresh / retry") { Task { await cloud.retry(id) } }.disabled(cloud.busy)
                    }
                    if let result = record.result {
                        RelayCard {
                            Text("AI proposal · review required").font(.headline)
                            Text(result.analysis_state.replacingOccurrences(of: "_", with: " "))
                            if let proposal = result.result?.proposal {
                                Text(proposal.summary)
                                Text("Item: \(proposal.item_id ?? "Unknown") · Amount: \(proposal.quantity.map(String.init) ?? "Unknown") \(proposal.unit ?? "")").font(.subheadline)
                            }
                            ForEach(result.result?.review_reasons ?? [], id: \.self) { Text($0).font(.caption).foregroundStyle(.orange) }
                            if let error = result.error { Text(error.message).font(.caption) }
                            Text("A proposal does not reserve supplies or authorize an assignment.").font(.caption).foregroundStyle(.secondary)
                        }
                        RelayCard {
                            Text("Request conversation").font(.headline)
                            Text("Progress: \(record.history?.status.replacingOccurrences(of: "_", with: " ") ?? "new")")
                            ForEach(record.history?.events ?? []) { event in
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(event.author_role.capitalized).font(.caption.bold())
                                    if let status = event.status { Text(status.replacingOccurrences(of: "_", with: " ")).font(.subheadline.bold()) }
                                    if !event.text.isEmpty { Text(event.text) }
                                    Text(event.created_at, format: .dateTime.hour().minute()).font(.caption).foregroundStyle(.secondary)
                                }.padding(.vertical, 6)
                            }
                            TextField("Reply about this request", text: $reply, axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder).focused($editing)
                            Picker("Progress update", selection: $progress) {
                                Text("Reply only").tag("")
                                if cloud.isDispatcher {
                                    Text("Accepted by staff").tag("accepted")
                                    Text("In progress").tag("in_progress")
                                    Text("Reported completed").tag("completed")
                                    Text("Unable to help").tag("rejected")
                                } else { Text("Cancel request").tag("cancelled") }
                            }
                            Button("Queue update") { Task {
                                await cloud.sendEvent(id, text: reply, status: progress.isEmpty ? nil : progress)
                                if cloud.records.first(where: { $0.id == id })?.pendingEvent != nil || cloud.problem.isEmpty { reply = ""; progress = "" }
                            } }.disabled(cloud.busy || record.pendingEvent != nil || (reply.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && progress.isEmpty))
                            if record.pendingEvent != nil {
                                Text("An update is queued. Its ID stays the same on retry.").font(.caption)
                                if record.state == "needs_attention" {
                                    Button("Discard unsent update and refresh") { Task { await cloud.discardConflictingEvent(id) } }
                                }
                            }
                            Text("Progress is reported by people. Inventory allocation and independent fulfillment verification are not implemented.").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }.padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
            }
        }.background(RelayTheme.canvas).navigationTitle("Cloud request")
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } } }
    }
}
struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var cloud: CloudModel
    @FocusState private var editing: Bool
    @StateObject private var recorder = VoiceRecorder()
    @State private var importingWAV = false
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                WorkflowHeader(eyebrow: "Voice request", title: "Speak. Review. Send.", subtitle: "Say what you need. You'll check the words before anything is sent to a shelter.")
                RelayCard {
                    WorkflowSection(title: "1. Record your request", symbol: "mic.fill", subtitle: "Up to 60 seconds · English · internet needed")
                    Image(systemName: recorder.recording ? "waveform" : "waveform.circle.fill")
                        .font(.system(size: 58)).foregroundStyle(recorder.recording ? .red : RelayTheme.accent)
                        .frame(maxWidth: .infinity).padding(.vertical, 12).accessibilityHidden(true)
                    Button {
                        if recorder.recording { recorder.stop() }
                        else { Task { await recorder.start { url in Task { await cloud.saveRecording(url: url) } } } }
                    } label: { Label(recorder.recording ? "Stop recording" : "Start recording", systemImage: recorder.recording ? "stop.fill" : "mic.fill") }
                        .buttonStyle(PrimaryButton()).disabled(cloud.audioBusy)
                    Button("Import WAV recording") { importingWAV = true }.buttonStyle(WorkflowSecondaryButton()).disabled(recorder.recording || cloud.audioBusy)
                    if recorder.recording { Label("Recording…", systemImage: "record.circle").font(.subheadline).foregroundStyle(.red) }
                    if !recorder.problem.isEmpty { WorkflowNotice(text: recorder.problem) }
                }
                if cloud.audioJob != nil {
                    RelayCard {
                        WorkflowSection(title: "2. Turn speech into text", symbol: "text.quote", subtitle: "Processed by Amazon Transcribe")
                        Button { Task { await cloud.transcribe() } } label: {
                            HStack { if cloud.audioBusy { ProgressView().controlSize(.small) }; Text(cloud.audioBusy ? "Transcribing…" : "Transcribe / resume") }
                        }.buttonStyle(WorkflowSecondaryButton()).disabled(recorder.recording || cloud.audioBusy)
                        Text(cloud.audioStatus).font(.subheadline).foregroundStyle(.secondary)
                        if cloud.audioBusy { Text("This can take a little time. Your recording is saved for retry.").font(.caption).foregroundStyle(.secondary) }
                    }
                }
                if cloud.audioJob?.transcript != nil {
                    RelayCard {
                        WorkflowSection(title: "3. Check the words", symbol: "checkmark.bubble.fill", subtitle: "Review names, quantities and locations.")
                        TextField("Review transcript", text: $cloud.transcript, axis: .vertical).lineLimit(5...12).textFieldStyle(WorkflowInput()).focused($editing)
                        Button("Prepare request from this text") { cloud.applyTranscript(); dismiss(); Task { await cloud.previewRequest() } }.buttonStyle(PrimaryButton())
                    }
                }
                if !cloud.problem.isEmpty { WorkflowNotice(text: cloud.problem) }
                Text("Use synthetic test data. Audio stays separate from nearby text messaging.").font(.caption).foregroundStyle(.secondary).padding(.horizontal, 4)
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(RelayTheme.canvas).navigationTitle("Voice input")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .scrollDismissesKeyboard(.interactively)
            #endif
            .fileImporter(isPresented: $importingWAV, allowedContentTypes: [.audio]) { result in
                do {
                    let source = try result.get()
                    let copy = try VoiceRecorder.importWAV(source)
                    Task { await cloud.saveRecording(url: copy) }
                } catch { if (error as NSError).code != NSUserCancelledError { cloud.problem = error.localizedDescription } }
            }
            .toolbar { ToolbarItem(placement: .primaryAction) { if editing { Button("Done") { editing = false } } } }
            .onDisappear { if recorder.recording { recorder.stop() } }
    }
}
struct LocalRequestThread: View {
    @ObservedObject var model: RelayModel
    let request: RelayMessage
    @FocusState private var editing: Bool
    @State private var text = ""
    @State private var progress = ""
    var body: some View {
        RelayCard {
            Text("Nearby replies and progress").font(.headline)
            ForEach(LocalRequestUpdate.thread(model.messages, request: request), id: \.0.id) { row, update in
                VStack(alignment: .leading, spacing: 5) {
                    Text(row.message.originID == model.deviceID ? "You" : model.peerTitle(row.message.originID)).font(.caption.bold())
                    if let progress = update.progress { Text(progress.replacingOccurrences(of: "_", with: " ")).font(.subheadline.bold()) }
                    if !update.text.isEmpty { Text(update.text) }
                    Text(row.status(deviceID: model.deviceID)).font(.caption).foregroundStyle(.secondary)
                }.padding(.vertical, 6)
            }
            TextField("Reply about this request", text: $text, axis: .vertical).lineLimit(2...5).textFieldStyle(.roundedBorder).focused($editing)
            Picker("Progress", selection: $progress) {
                Text("Reply only").tag("")
                if request.destinationID == model.deviceID {
                    Text("Accepted").tag("accepted"); Text("In progress").tag("in_progress")
                    Text("Reported completed").tag("completed"); Text("Unable to help").tag("rejected")
                } else { Text("Request cancellation").tag("cancelled") }
            }
            Button("Send via nearby relay") {
                model.sendRequestUpdate(request, text: text, progress: progress.isEmpty ? nil : progress) { text = ""; progress = "" }
            }.disabled(model.sending || (text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && progress.isEmpty))
            if editing { Button("Done") { editing = false } }
            Text("Device-reported updates; staff identity is unverified. A cancellation note does not recall messages already carried by other devices.").font(.caption).foregroundStyle(.secondary)
        }
    }
}
