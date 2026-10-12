import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            List {
                Section {
                    NavigationLink {
                        ModuleSelectorView()
                    } label: {
                        DemoRow(title: "Module Selectors", subtitle: "OSLog::Logger vs. your own Logger", version: "Swift 6.3")
                    }
                }

                Section {
                    NavigationLink {
                        AsyncDeferView()
                    } label: {
                        DemoRow(title: "Async defer", subtitle: "await inside a defer block", version: "Swift 6.4")
                    }

                    NavigationLink {
                        CancellationShieldView()
                    } label: {
                        DemoRow(title: "Cancellation Shields", subtitle: "Cleanup that ignores cancellation", version: "Swift 6.4")
                    }
                }
            }
            .navigationTitle("Swift 6.3 & 6.4")
        }
    }
}

struct DemoRow: View {
    let title: String
    let subtitle: String
    let version: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(version)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(.orange.opacity(0.2), in: .capsule)
            }
            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView()
}