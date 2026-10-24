import XCTest
@testable import RelayCore

final class RequestWorkflowTests: XCTestCase {
    private let scope = String(repeating: "a", count: 64)
    private var shelter: CloudShelter { CloudShelter(shelter_id: "shelter-a", incident_id: "synthetic-demo-01", display_name: "Demo shelter") }
    private func draft() throws -> RequestDraft {
        var d = RequestDraft(); d.shelterID = shelter.shelter_id; d.text = "Shelter A needs 2 water packs."
        d.item = "water_packs"; d.quantity = "2"; d.landmark = "Synthetic test point"
        d.location = try RequestLocation(latitude: 0, longitude: 0, accuracy: 100, precision: "approximate", source: "manual")
        return d
    }
    func testLocationAndStructuredRequestSurviveRestartWithoutPlaintextPeerCopy() throws {
        let folder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? FileManager.default.removeItem(at: folder) }
        let path = folder.appendingPathComponent("relay.sqlite").path
        var store: RelayStore? = try .open(path: path)
        let identity = store!.deviceID, d = try draft()
        try store!.saveRequestDraft(d, scope: scope)
        let saved = try store!.submitCloudDraft(d, scope: scope, shelter: shelter)
        store = nil; store = try .open(path: path)
        let record = try XCTUnwrap(store!.cloudRecords(scope: scope).first)
        XCTAssertEqual(record.submission, saved.submission)
        XCTAssertEqual(record.submission.location, d.location)
        XCTAssertEqual(record.submission.structured_fields?.quantity, 2)
        XCTAssertEqual(store!.deviceID, identity)
        XCTAssertNil(try store!.message(d.id), "Precise location must not enter the plaintext P2P store")
        XCTAssertNotEqual(try store!.requestDraft(scope: scope).id, d.id)
        XCTAssertTrue(try store!.cloudRecords(scope: String(repeating: "b", count: 64)).isEmpty)
    }
    func testExactReplayDoesNotDuplicateAndChangedContentIsRejected() throws {
        let store = try RelayStore.open(path: ":memory:")
        var d = try draft(); let first = try store.submitCloudDraft(d, scope: scope, shelter: shelter)
        let replay = try store.submitCloudDraft(d, scope: scope, shelter: shelter, now: Date().addingTimeInterval(40))
        XCTAssertEqual(first.submission, replay.submission); XCTAssertEqual(try store.cloudRecords(scope: scope).count, 1)
        d.quantity = "9"
        XCTAssertThrowsError(try store.submitCloudDraft(d, scope: scope, shelter: shelter))
        try store.saveRequestDraft(d, scope: scope)
        XCTAssertNotEqual(try store.requestDraft(scope: scope).id, d.id)
    }
    func testInvalidCloudSubmissionDoesNotClearDraft() throws {
        let store = try RelayStore.open(path: ":memory:"); var d = try draft(); d.quantity = "-2"
        try store.saveRequestDraft(d, scope: scope)
        XCTAssertThrowsError(try store.submitCloudDraft(d, scope: scope, shelter: shelter))
        XCTAssertEqual(try store.requestDraft(scope: scope).id, d.id)
        XCTAssertTrue(try store.cloudRecords(scope: scope).isEmpty)
    }
    func testLocationBoundsAndUnknownCounts() throws {
        XCTAssertThrowsError(try RequestLocation(latitude: .nan, longitude: 0, accuracy: 1))
        XCTAssertThrowsError(try RequestLocation(latitude: 91, longitude: 0, accuracy: 1))
        XCTAssertThrowsError(try RequestLocation(latitude: 0, longitude: 0, accuracy: -1))
        var d = try draft(); d.quantity = ""; d.people = ""
        XCTAssertNil(try d.fields().quantity); XCTAssertNil(try d.fields().people); XCTAssertNil(try d.fields().unit)
        d.quantity = "10001"; XCTAssertThrowsError(try d.fields())
    }
    func testEditedTextCannotReuseOldInterpretation() throws {
        var d = try draft(); d.interpretationReady = true; d.interpretationID = UUID().uuidString.lowercased()
        d.interpretationText = d.text; d.interpretationShelter = d.shelterID
        let device = UUID().uuidString.lowercased()
        XCTAssertEqual(try CloudSubmission(draft: d, shelter: shelter, deviceID: device).interpretation_id, d.interpretationID)
        d.text = "Now need food"
        XCTAssertNil(try CloudSubmission(draft: d, shelter: shelter, deviceID: device).interpretation_id)
    }
    func testInventoryOperationPersistsAcrossLostResponse() throws {
        let store = try RelayStore.open(path: ":memory:")
        var record = try store.submitCloudDraft(draft(), scope: scope, shelter: shelter)
        record.pendingInventory = InventoryCommand(action: "reserve", item: "water_packs", quantity: 2, revision: 1)
        record.failed("Connection lost after commit", retryable: true)
        try store.saveCloudRecord(record)
        let recovered = try XCTUnwrap(store.cloudRecords(scope: scope).first)
        XCTAssertEqual(recovered.pendingInventory, record.pendingInventory)
        XCTAssertEqual(recovered.submission, record.submission)
    }
}
