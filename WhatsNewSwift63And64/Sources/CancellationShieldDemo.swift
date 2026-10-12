import SwiftUI

@MainActor
@Observable
final class CancellationShieldDemo {
    private(set) var events: [String] = []
    private(set) var isRunning = false

    @ObservationIgnored private var task: Task<Void, Never>?

    private let fileURL = URL.temporaryDirectory.appending(path: "journal.log")

    func start() {
        events.removeAll()
        isRunning = true

        task = Task {
            await writeJournal()
            reportFileContents()
            isRunning = false
        }
    }

    func cancel() {
        task?.cancel()
    }

    private func writeJournal() async {
        FileManager.default.createFile(atPath: fileURL.path(), contents: nil)

        let handle: FileHandle
        do {
            handle = try FileHandle(forWritingTo: fileURL)
        } catch {
            events.append("Could not open journal: \(error.localizedDescription)")
            return
        }

        defer {
            events.append("Cleanup starts, isCancelled = \(Task.isCancelled)")

            if #available(iOS 27.0, *) {
                withTaskCancellationShield {
                    events.append("Inside the shield, isCancelled = \(Task.isCancelled)")
                    try? handle.synchronize()
                    try? handle.close()
                }
            } else {
                try? handle.synchronize()
                try? handle.close()
            }

            events.append("File flushed and closed")
        }

        for entry in 1...12 {
            do {
                try await Task.sleep(for: .milliseconds(400))
            } catch {
                events.append("Cancelled after \(entry - 1) entries")
                return
            }

            try? handle.write(contentsOf: Data("entry \(entry)\n".utf8))
            events.append("Wrote entry \(entry)")
        }
    }

    private func reportFileContents() {
        let contents = (try? String(contentsOf: fileURL, encoding: .utf8)) ?? ""
        let lines = contents.split(separator: "\n").count
        events.append("journal.log contains \(lines) lines on disk")
    }
}

struct CancellationShieldView: View {
    @State private var demo = CancellationShieldDemo()

    var body: some View {
        List {
            Section {
                Text("""
                defer {
                    withTaskCancellationShield {
                        try? handle.synchronize()
                        try? handle.close()
                    }
                }
                """)
                .font(.system(.footnote, design: .monospaced))
            } footer: {
                Text("Start writing the journal and cancel it partway. Task.isCancelled reads true before the shield and false inside it.")
            }

            Section {
                if demo.isRunning {
                    Button("Cancel", role: .destructive, action: demo.cancel)
                } else {
                    Button("Write Journal", action: demo.start)
                }
            } footer: {
                if #unavailable(iOS 27.0) {
                    Text("withTaskCancellationShield requires iOS 27. On this device the cleanup runs without a shield.")
                }
            }

            EventLogSection(events: demo.events)
        }
        .navigationTitle("Cancellation Shields")
    }
}