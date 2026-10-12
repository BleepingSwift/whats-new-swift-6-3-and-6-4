import Foundation

struct SyncError: LocalizedError {
    let folder: String

    var errorDescription: String? {
        "The server rejected FETCH for \(folder)"
    }
}

/// A simulated IMAP client. Every call suspends for a moment the way a real
/// network round trip would.
@MainActor
final class IMAPClient {
    private let record: (String) -> Void

    init(record: @escaping (String) -> Void) {
        self.record = record
    }

    func connect() async throws -> MailSession {
        record("Connecting to imap.example.com")
        try await Task.sleep(for: .milliseconds(400))
        record("Logged in")
        return MailSession(record: record)
    }
}

@MainActor
final class MailSession {
    private let record: (String) -> Void
    private(set) var isLoggedIn = true

    init(record: @escaping (String) -> Void) {
        self.record = record
    }

    func folders() async throws -> [String] {
        try await Task.sleep(for: .milliseconds(300))
        return ["INBOX", "Archive", "Receipts", "Newsletters"]
    }

    /// Sends LOGOUT and waits for the server to acknowledge it. If the task has
    /// already been cancelled, the sleep throws right away and the server never
    /// hears from us, which is the problem a cancellation shield fixes.
    func logout() async {
        record("Sending LOGOUT")
        do {
            try await Task.sleep(for: .milliseconds(500))
            isLoggedIn = false
            record("Server acknowledged LOGOUT")
        } catch {
            record("LOGOUT abandoned because the task is cancelled")
        }
    }
}