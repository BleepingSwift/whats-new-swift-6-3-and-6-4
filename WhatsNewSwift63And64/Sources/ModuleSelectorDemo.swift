import OSLog
import SwiftUI

@MainActor
@Observable
final class ModuleSelectorDemo {
    let store = LogStore()
    private(set) var messageCount = 0

    // Both OSLog and this app declare a type named `Logger`. The global `system`
    // logger is an OSLog::Logger; this one is the app's own type.
    private let network: WhatsNewSwift63And64::Logger

    init() {
        network = WhatsNewSwift63And64::Logger(category: "network", store: store)
    }

    func logRequest() {
        messageCount += 1
        let message = "GET /messages (request #\(messageCount))"

        system.info("\(message, privacy: .public)")
        network.log(message)
    }
}

struct ModuleSelectorView: View {
    @State private var demo = ModuleSelectorDemo()

    var body: some View {
        List {
            Section {
                Text("""
                let system = OSLog::Logger(...)
                let network = WhatsNewSwift63And64::Logger(...)
                """)
                .font(.system(.footnote, design: .monospaced))
            } footer: {
                Text("This app declares its own Logger type. Module selectors (Swift 6.3) pick between it and OSLog's Logger without a typealias.")
            }

            Section {
                Button("Log a Request", action: demo.logRequest)
                Button("Clear", role: .destructive, action: demo.store.clear)
                    .disabled(demo.store.entries.isEmpty)
            } footer: {
                Text("OSLog::Logger writes to the Xcode console. The app's Logger writes to the list below.")
            }

            Section("WhatsNewSwift63And64::Logger") {
                if demo.store.entries.isEmpty {
                    Text("No entries yet")
                        .foregroundStyle(.secondary)
                }

                ForEach(demo.store.entries) { entry in
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.message)
                            .font(.system(.body, design: .monospaced))
                        Text("[\(entry.category)] \(entry.date.formatted(date: .omitted, time: .standard))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle("Module Selectors")
    }
}