import Foundation
import Observation
import OSLog

/// Collects entries written by the app's own `Logger` so the UI can display them.
@MainActor
@Observable
final class LogStore {
    struct Entry: Identifiable {
        let id = UUID()
        let date: Date
        let category: String
        let message: String
    }

    private(set) var entries: [Entry] = []

    func append(category: String, message: String) {
        entries.insert(Entry(date: .now, category: category, message: message), at: 0)
    }

    func clear() {
        entries.removeAll()
    }
}

/// A stand-in for a third-party logging library. Its name collides with
/// `OSLog.Logger`, which is exactly the situation module selectors solve.
struct Logger {
    let category: String
    let store: LogStore

    @MainActor
    func log(_ message: String) {
        store.append(category: category, message: message)
    }
}

/// The system logger, picked out explicitly with a module selector.
/// Messages show up in Xcode's console and Console.app.
let system = OSLog::Logger(subsystem: "com.bleepingswift.whatsnewswift63and64", category: "sync")