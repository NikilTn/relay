import Foundation
import AVFoundation
import SwiftUI

@MainActor final class VoiceRecorder: NSObject, ObservableObject, AVAudioRecorderDelegate {
    @Published var recording = false
    @Published var problem = ""
    private var recorder: AVAudioRecorder?
    private var finished: ((URL) -> Void)?
    static func folder() throws -> URL {
        let path = try FileManager.default.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true).appendingPathComponent("RELAY/Recordings", isDirectory: true)
        try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
        return path
    }
    func start(done: @escaping (URL) -> Void) async {
        guard !recording else { return }
        let allowed: Bool
        #if os(iOS)
        allowed = await AVAudioApplication.requestRecordPermission()
        #else
        allowed = await AVCaptureDevice.requestAccess(for: .audio)
        #endif
        guard allowed else { problem = "Allow microphone access in Settings to record. Typed requests remain available."; return }
        do {
            #if os(iOS)
            try AVAudioSession.sharedInstance().setCategory(.record, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
            #endif
            let file = try Self.folder().appendingPathComponent(UUID().uuidString.lowercased() + ".wav")
            let recorder = try AVAudioRecorder(url: file, settings: [AVFormatIDKey: kAudioFormatLinearPCM, AVSampleRateKey: 16000.0,
                AVNumberOfChannelsKey: 1, AVLinearPCMBitDepthKey: 16, AVLinearPCMIsFloatKey: false, AVLinearPCMIsBigEndianKey: false])
            recorder.delegate = self; self.recorder = recorder; finished = done
            guard recorder.record(forDuration: 60) else { throw NSError(domain: "RELAY", code: 1, userInfo: [NSLocalizedDescriptionKey: "Could not start recording"]) }
            recording = true; problem = ""
        } catch { problem = error.localizedDescription }
    }
    func stop() { recorder?.stop() }
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        let url = recorder.url
        Task { @MainActor in
            self.recording = false
            #if os(iOS)
            try? AVAudioSession.sharedInstance().setActive(false)
            #endif
            if flag { self.finished?(url) } else { self.problem = "Recording did not finish. Please try again." }
            self.finished = nil
        }
    }
}
