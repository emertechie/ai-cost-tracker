import SwiftUI

/// The popover shown when clicking the menu bar item.
struct UsagePopoverView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !appState.isConfigured {
                unconfiguredView
            } else if let snapshot = appState.snapshot {
                usageView(snapshot)
            } else if appState.isLoading {
                loadingView
            } else {
                emptyView
            }

            Divider()
            footerView
        }
        .padding(16)
        .frame(width: 280)
    }

    // MARK: - Subviews

    private var unconfiguredView: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Setup Required", systemImage: "gear.badge.questionmark")
                .font(.headline)
            Text("Configure your GitHub username and token in Settings to start tracking.")
                .font(.caption)
                .foregroundStyle(.secondary)
            Button("Open Settings…") {
                openSettings()
            }
        }
    }

    private func usageView(_ snapshot: UsageSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Text("Copilot")
                    .font(.headline)
                Text("·")
                    .foregroundStyle(.secondary)
                Text(snapshot.period.description)
                    .foregroundStyle(.secondary)
            }

            // Included usage
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("Included")
                        .font(.subheadline.weight(.medium))
                    Spacer()
                    Text("\(snapshot.includedConsumed) / \(snapshot.includedAllowance)")
                        .font(.subheadline.monospacedDigit())
                }

                ProgressView(value: min(snapshot.includedPercent, 1.0))
                    .tint(progressColor(snapshot.includedPercent))

                Text(String(format: "%.1f%% used", snapshot.includedPercent * 100))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            // Billed section
            if snapshot.isOverage {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("Billed (MTD)")
                            .font(.subheadline.weight(.medium))
                        Spacer()
                        Text(String(format: "$%.2f", snapshot.billedAmount))
                            .font(.subheadline.monospacedDigit().weight(.semibold))
                            .foregroundStyle(Color(red: 1.0, green: 0.35, blue: 0.25))
                    }
                    if snapshot.billedQuantity > 0 {
                        Text("\(snapshot.billedQuantity) premium requests")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            // Model breakdowns (if any)
            if !snapshot.breakdowns.isEmpty {
                DisclosureGroup("By Model") {
                    ForEach(snapshot.breakdowns) { item in
                        HStack {
                            Text(item.model)
                                .font(.caption)
                                .lineLimit(1)
                            Spacer()
                            Text("\(item.grossQuantity) req")
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .font(.caption)
            }

            // Reset countdown
            Text(snapshot.period.resetCountdown)
                .font(.caption)
                .foregroundStyle(.secondary)

            // Error display
            if let error = appState.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
    }

    private var loadingView: some View {
        HStack {
            ProgressView()
                .controlSize(.small)
            Text("Loading…")
                .foregroundStyle(.secondary)
        }
    }

    private var emptyView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("No data yet")
                .font(.subheadline)
            if let error = appState.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
            Button("Refresh") {
                Task { await appState.refresh() }
            }
        }
    }

    private var footerView: some View {
        HStack {
            if let fetched = appState.lastFetchedAt {
                Text("Updated \(fetched, style: .relative) ago")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            Spacer()

            Button {
                Task { await appState.refresh() }
            } label: {
                if appState.isLoading {
                    ProgressView()
                        .controlSize(.small)
                } else {
                    Image(systemName: "arrow.clockwise")
                }
            }
            .buttonStyle(.borderless)
            .disabled(appState.isLoading)
            .help("Refresh usage data")

            Button {
                openSettings()
            } label: {
                Image(systemName: "gear")
            }
            .buttonStyle(.borderless)
            .help("Settings")

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
            }
            .buttonStyle(.borderless)
            .help("Quit AI Cost Tracker")
        }
    }

    // MARK: - Helpers

    private func openSettings() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "settings")
        NSApp.activate(ignoringOtherApps: true)
    }

    private func progressColor(_ percent: Double) -> Color {
        if percent >= 1.0 { return .red }
        if percent >= 0.9 { return .orange }
        if percent >= 0.7 { return .yellow }
        return .green
    }
}
