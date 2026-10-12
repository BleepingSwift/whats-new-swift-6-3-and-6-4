import SwiftUI

@MainActor
@Observable
final class AsyncDeferDemo {
    private(set) var events: [String] = []
    private(set) var isRunning = false
    var failOnReceipts = false
    var shieldLogout = true

    @ObservationIgnored private var task: Task<Void, Never>?
    @ObservationIgnored private lazy var imap = IMAPClient { [weak self] message in
        self?.events.append(message)
    }

    func start() {
        events.removeAll()
        isRunning = true

        task = Task {
            do {
                if shieldLogout {
                    try await syncMailboxShielded()
                } else {
                    try await syncMailbox()
                }
                events.append("Sync finished")
            } catch is CancellationError {
                events.append("Sync cancelled")
            } catch {
                events.append("Sync failed: \(error.localizedDescription)")
            }
            isRunning = false
        }
    }

    func cancel() {
        task?.cancel()
    }

    // Swift 6.4 lets `defer` await, so the logout runs on every exit path:
    // success, a thrown error, or cancellation.
    func syncMailbox() async throws {
        let session = try await imap.connect()
        defer { await session.logout() }

        for folder in try await session.folders() {
            try await ingest(folder)
        }
    }

    // Same function, but the cleanup is shielded so a cancelled task still
    // finishes talking to the server.
    func syncMailboxShielded() async throws {
        let session = try await imap.connect()
        defer {
            if #available(iOS 27.0, *) {
                await withTaskCancellationShield {
                    await session.logout()
                }
            } else {
                await session.logout()
            }
        }

        for folder in try await session.folders() {
            try await ingest(folder)
        }
    }

    private func ingest(_ folder: String) async throws {
        events.append("Downloading \(folder)")
        try await Task.sleep(for: .milliseconds(700))

        if failOnReceipts && folder == "Receipts" {
            throw SyncError(folder: folder)
        }

        events.append("Ingested \(folder)")
    }
}

struct AsyncDeferView: View {
    @State private var demo = AsyncDeferDemo()

    var body: some View {
        List {
            Section {
                Text("""
                let session = try await imap.connect()
                defer { await session.logout() }
                """)
                .font(.system(.footnote, design: .monospaced))
            } footer: {
                Text("Run the sync, then try it again with a failure or by cancelling partway through. LOGOUT is always attempted.")
            }

            Section {
                Toggle("Fail on Receipts folder", isOn: $demo.failOnReceipts)
                Toggle("Shield logout from cancellation", isOn: $demo.shieldLogout)

                if demo.isRunning {
                    Button("Cancel Sync", role: .destructive, action: demo.cancel)
                } else {
                    Button("Sync Mailbox", action: demo.start)
                }
            } footer: {
                if #unavailable(iOS 27.0) {
                    Text("Cancellation shields need iOS 27, so the shield toggle has no effect on this device.")
                }
            }

            EventLogSection(events: demo.events)
        }
        .navigationTitle("Async defer")
    }
}

struct EventLogSection: View {
    let events: [String]

    var body: some View {
        Section("Events") {
            if events.isEmpty {
                Text("Nothing has run yet")
                    .foregroundStyle(.secondary)
            }

            ForEach(Array(events.enumerated()), id: \.offset) { _, event in
                Text(event)
                    .font(.system(.callout, design: .monospaced))
            }
        }
    }
}