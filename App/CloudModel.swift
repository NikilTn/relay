import SwiftUI
import RelayCore

@MainActor final class CloudModel: ObservableObject {
    @Published var endpoint = UserDefaults.standard.string(forKey: "relay.cloud.endpoint") ?? (Bundle.main.object(forInfoDictionaryKey: "RELAYCloudAPIURL") as? String ?? "")
    @Published var profile: CloudProfile?
    @Published var directory: [CloudShelter] = []
    @Published var records: [CloudQueueRecord] = []
    @Published var bindings: [CloudBinding] = []
    @Published var problem = ""
    @Published var status = "Cloud not configured"
    @Published var busy = false
    @Published var audioBusy = false
    @Published var audioStatus = ""
    @Published var audioJob: CloudAudioJob?
    @Published var transcript = ""
    private let auth = CloudAuth()
    private weak var model: RelayModel?
    private var api: CloudHTTPClient?
    private var scope: String?
    private var epoch = UUID()
    private var timer: Task<Void, Never>?
    var canUseCloud: Bool { profile != nil && api != nil && auth.hasSession }
    var isDispatcher: Bool { profile?.role == "dispatcher" }

    func attach(_ model: RelayModel) async {
        guard self.model == nil else { return }; self.model = model
        if auth.hasSession, let cached = auth.cachedProfile, let url = try? CloudCodec.apiURL(endpoint) {
            api = try? CloudHTTPClient(baseURL: url); scope = CloudCodec.scope(baseURL: url, subject: cached.subject)
            profile = cached
            if let scope {
                do {
                    let cachedData = try await model.withStore { store in
                        (try store.setting("cloud_bindings:" + scope), try store.setting("cloud_directory:" + scope))
                    }
                    if let value = cachedData.0 { bindings = try CloudCodec.decode([CloudBinding].self, Data(value.utf8)) }
                    if let value = cachedData.1 { directory = try CloudCodec.decode([CloudShelter].self, Data(value.utf8)) }
                    await reload(); status = "Saved account · connecting…"
                } catch { problem = error.localizedDescription }
            }
            await connect(signIn: false)
        }
        timer = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(10))
                guard !Task.isCancelled else { break }
                await self?.sync()
            }
        }
    }
    func connect(signIn: Bool) async {
        guard !busy, let model else { return }
        busy = true; defer { busy = false }; problem = ""
        do {
            let url = try CloudCodec.apiURL(endpoint)
            let client = try CloudHTTPClient(baseURL: url)
            if signIn { try await auth.signIn() }
            let token = try await auth.accessToken()
            let verified: CloudProfile = try await client.call("v1/me", token: token)
            let shelters: CloudDirectory = try await client.call("v1/shelters", token: token)
            let key = CloudCodec.scope(baseURL: url, subject: verified.subject)
            try auth.rememberProfile(verified)
            let directoryData = try CloudCodec.encode(shelters.items)
            try await model.withStore { try $0.setSetting("cloud_directory:" + key, String(decoding: directoryData, as: UTF8.self)) }
            let saved = try await model.withStore { store -> ([CloudQueueRecord], [CloudBinding], CloudAudioJob?) in
                let bindings = try store.setting("cloud_bindings:" + key).map { try CloudCodec.decode([CloudBinding].self, Data($0.utf8)) } ?? []
                let audio = try store.setting("cloud_audio:" + key).flatMap { try CloudCodec.decode(CloudAudioJob?.self, Data($0.utf8)) }
                return (try store.cloudRecords(scope: key), bindings, audio)
            }
            epoch = UUID(); api = client; scope = key; profile = verified; directory = shelters.items
            records = saved.0; bindings = saved.1; audioJob = saved.2; transcript = saved.2?.transcript ?? ""
            UserDefaults.standard.set(url.absoluteString, forKey: "relay.cloud.endpoint")
            status = "Signed in · \(verified.role.capitalized)"
        } catch { problem = error.localizedDescription; status = "Cloud unavailable; nearby delivery still works" }
    }
    func signOut() {
        epoch = UUID(); auth.signOut(); profile = nil; api = nil; scope = nil
        records = []; directory = []; bindings = []; audioJob = nil; transcript = ""; status = "Signed out"
    }
    func bind(localID: String, cloudID: String) async {
        guard let destination = directory.first(where: { $0.id == cloudID }), let scope, let model else { return }
        var updated = bindings.filter { $0.localID != localID }
        updated.append(CloudBinding(localID: localID, incidentID: destination.incident_id, shelterID: destination.shelter_id))
        do {
            let data = try CloudCodec.encode(updated)
            try await model.withStore { try $0.setSetting("cloud_bindings:" + scope, String(decoding: data, as: UTF8.self)) }
            bindings = updated
        } catch { problem = error.localizedDescription }
    }
    func prepared(_ draft: HelpRequestDraft) throws -> HelpRequestDraft {
        guard let scope, let profile, let binding = bindings.first(where: { $0.localID == draft.shelterID }) else { throw RelayError.invalid("Sign in and link this shelter first") }
        var copy = draft; copy.cloudScope = scope; copy.cloudBinding = binding
        if copy.transcriptionSubject != profile.subject || copy.transcriptionIncident != binding.incidentID { copy.transcriptionID = nil }
        return copy
    }
    func queue(_ message: RelayMessage, draft: HelpRequestDraft? = nil) async {
        guard let scope, let profile, let model else { problem = "Sign in and map this shelter first"; return }
        do {
            let request = try ShelterRequestCodec.decode(message)
            guard let binding = bindings.first(where: { $0.localID == request.shelter.id }),
                  directory.contains(where: { $0.shelter_id == binding.shelterID && $0.incident_id == binding.incidentID }) else { throw RelayError.invalid("Map this local shelter to an authorized cloud shelter first") }
            if records.contains(where: { $0.id == message.id }) { await sync(); return }
            let savedAudio = try await model.withStore { try $0.setting("request_audio:" + message.id) }
            let reference = savedAudio.flatMap { try? JSONSerialization.jsonObject(with: Data($0.utf8)) as? [String: String] }
            let transcription = reference?["subject"] == profile.subject && reference?["incident"] == binding.incidentID ? reference?["id"] : nil
            let submission = try CloudSubmission(message: message, binding: binding, localDeviceID: model.deviceID, transcriptionID: transcription)
            let record = CloudQueueRecord(scope: scope, submission: submission)
            try await model.withStore { try $0.saveCloudRecord(record) }
            await reload(); await sync()
        } catch { problem = error.localizedDescription }
    }
    func sync() async {
        guard !busy, let api, let scope, let model, profile != nil else { return }
        busy = true; defer { busy = false }
        let generation = epoch
        do {
            let token = try await auth.accessToken()
            let pending = try await model.withStore { try $0.cloudRecords(scope: scope) }
            for var record in pending.filter({ $0.retryAt <= Date() && $0.state != "needs_attention" }).prefix(20) {
                guard generation == epoch else { return }
                do {
                    let result: CloudResult
                    if record.state == "queued" {
                        result = try await api.call("v1/requests", token: token, method: "POST", body: CloudCodec.encode(record.submission))
                    } else { result = try await api.call("v1/requests/" + record.id, token: token) }
                    guard result.request_id == record.id, result.submission == record.submission, result.cloud_state == "accepted" else { throw RelayError.invalid("Cloud response does not match the saved request") }
                    record.result = result; record.state = "accepted"; record.problem = nil
                    if let event = record.pendingEvent {
                        record.history = try await api.call("v1/requests/\(record.id)/events", token: token, method: "POST", body: CloudCodec.encode(event))
                        record.pendingEvent = nil
                    } else { record.history = try await api.call("v1/requests/\(record.id)/history", token: token) }
                    record.retryAt = Date().addingTimeInterval(20)
                } catch {
                    let http = error as? CloudHTTPError
                    let retryable = http?.retryable ?? !(error is RelayError)
                    if record.state == "queued" { record.failed(error.localizedDescription, retryable: retryable) }
                    else { record.problem = error.localizedDescription; record.retryAt = Date().addingTimeInterval(30) }
                    if let http, !http.retryable { record.state = "needs_attention" }
                }
                guard generation == epoch else { return }
                try await model.withStore { try $0.saveCloudRecord(record) }
            }
            await reload(); status = "Cloud checked \(Date().formatted(date: .omitted, time: .shortened))"
        } catch { problem = error.localizedDescription; status = "Cloud unavailable · queued requests retained" }
    }
    func loadInbox(shelterID: String? = nil) async {
        guard !busy, let api, let scope, let model else { return }
        busy = true; defer { busy = false }; let generation = epoch
        do {
            let token = try await auth.accessToken()
            var cursor: String?
            repeat {
                var query = [URLQueryItem(name: "view", value: shelterID == nil ? "mine" : "shelter"), .init(name: "limit", value: "50")]
                if let shelterID { query.append(.init(name: "shelter_id", value: shelterID)) }
                if let cursor { query.append(.init(name: "cursor", value: cursor)) }
                let page: CloudPage = try await api.call("v1/requests", token: token, query: query)
                guard generation == epoch else { return }
                for result in page.items {
                    var record = records.first { $0.id == result.id } ?? CloudQueueRecord(scope: scope, submission: result.submission)
                    record.result = result; record.state = "accepted"
                    record.history = try await api.call("v1/requests/\(record.id)/history", token: token)
                    try await model.withStore { try $0.saveCloudRecord(record) }
                }
                cursor = page.next_cursor
                await reload()
            } while cursor != nil && records.count < 1000
        } catch { problem = error.localizedDescription }
    }
    func sendEvent(_ id: String, text: String, status: String?) async {
        guard var record = records.first(where: { $0.id == id }), let model else { return }
        guard record.pendingEvent == nil else { problem = "The previous update is still queued. Retry it before adding another."; return }
        problem = ""
        record.pendingEvent = CloudEventCommand(revision: record.history?.revision ?? 0, text: text, status: status)
        record.retryAt = .distantPast
        do { try await model.withStore { try $0.saveCloudRecord(record) }; await reload(); await sync() }
        catch { problem = error.localizedDescription }
    }
    func retry(_ id: String) async {
        guard var record = records.first(where: { $0.id == id }), let model else { return }
        record.state = record.result == nil ? "queued" : "accepted"; record.retryAt = .distantPast
        do { try await model.withStore { try $0.saveCloudRecord(record) }; await sync() } catch { problem = error.localizedDescription }
    }
    func discardConflictingEvent(_ id: String) async {
        guard var record = records.first(where: { $0.id == id }), let model else { return }
        record.pendingEvent = nil; record.state = "accepted"; record.retryAt = .distantPast
        do { try await model.withStore { try $0.saveCloudRecord(record) }; await sync() } catch { problem = error.localizedDescription }
    }
    private func reload() async {
        guard let scope, let model else { return }
        do { records = try await model.withStore { try $0.cloudRecords(scope: scope) } } catch { problem = error.localizedDescription }
    }
    func saveRecording(url: URL) async {
        guard let profile else { problem = "Sign in before cloud transcription"; return }
        do {
            let data = try Data(contentsOf: url)
            guard data.count > 44 && data.count <= 2_097_152 else { throw RelayError.invalid("Record up to 60 seconds of audio") }
            let job = CloudAudioJob(fileName: url.lastPathComponent, incidentID: profile.incident_id, data: data)
            try await persistAudio(job); audioJob = job; transcript = ""; audioStatus = "Recording saved on this device"
        } catch { problem = error.localizedDescription }
    }
    private func persistAudio(_ job: CloudAudioJob) async throws {
        guard let model, let scope else { throw RelayError.invalid("Sign in first") }
        let data = try CloudCodec.encode(job)
        try await model.withStore { try $0.setSetting("cloud_audio:" + scope, String(decoding: data, as: UTF8.self)) }
    }
    func transcribe() async {
        guard !audioBusy, var job = audioJob, let api else { return }
        audioBusy = true; defer { audioBusy = false }; let generation = epoch
        do {
            let token = try await auth.accessToken()
            let url = try VoiceRecorder.folder().appendingPathComponent(job.fileName)
            let data = try Data(contentsOf: url)
            audioStatus = "Preparing private upload…"
            var result: CloudTranscription = try await api.call("v1/transcriptions", token: token, method: "POST", body: job.allocation())
            if let grant = result.upload { try await api.upload(grant, wav: data, token: token) }
            if result.status != "completed" {
                result = try await api.call("v1/transcriptions/\(job.id)/start", token: token, method: "POST", body: JSONSerialization.data(withJSONObject: ["operation_id": job.startID]))
            }
            for _ in 0..<80 {
                guard generation == epoch else { return }
                if result.status == "completed" { break }
                if result.status == "failed" { throw RelayError.invalid(result.error?.message ?? "Transcription failed") }
                audioStatus = "Transcribing… You can continue using nearby messaging."
                try await Task.sleep(for: .seconds(3))
                result = try await api.call("v1/transcriptions/\(job.id)", token: token)
            }
            guard generation == epoch else { return }
            guard result.status == "completed", let text = result.transcript else { throw RelayError.invalid("Still processing. Retry later; the same job will be reused.") }
            job.transcript = text; try await persistAudio(job)
            audioJob = job; transcript = text; audioStatus = "Review and correct the transcript before using it"
        } catch { audioStatus = "Recording retained for retry"; problem = error.localizedDescription }
    }
    func applyTranscript() {
        guard let job = audioJob, job.transcript != nil, let profile, let model, !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        model.helpDraft.details = transcript
        model.helpDraft.transcriptionID = job.id; model.helpDraft.transcriptionSubject = profile.subject
        model.helpDraft.transcriptionIncident = job.incidentID
        model.persistHelpDraft(); audioStatus = "Copied to Help. Choose a shelter, complete the fields, then review and submit."
    }
}
