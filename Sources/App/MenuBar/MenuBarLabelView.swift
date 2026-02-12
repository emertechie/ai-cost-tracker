import SwiftUI

/// The menu bar label showing a mini progress bar and optional billed amount.
struct MenuBarLabelView: View {
    @EnvironmentObject var appState: AppState

    var body: some View {
        HStack(spacing: 4) {
            if let snapshot = appState.snapshot {
                // Mini progress bar
                ProgressBarView(
                    percent: snapshot.includedPercent,
                    isOverage: snapshot.isOverage
                )
                .frame(width: 60, height: 8)

                // Show billed amount when in overage
                if snapshot.isOverage {
                    Text(formattedAmount(snapshot.billedAmount))
                        .font(.system(size: 10, weight: .medium, design: .monospaced))
                }
            } else if !appState.isConfigured {
                Image(systemName: "gear.badge.questionmark")
            } else {
                Image(systemName: "ellipsis")
            }
        }
    }

    private func formattedAmount(_ amount: Double) -> String {
        if amount < 10 {
            return String(format: "$%.2f", amount)
        } else {
            return String(format: "$%.0f", amount)
        }
    }
}

/// A small capsule-shaped progress bar for the menu bar.
struct ProgressBarView: View {
    let percent: Double
    let isOverage: Bool

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Background track
                Capsule()
                    .fill(Color.primary.opacity(0.2))

                // Filled portion
                Capsule()
                    .fill(barColor)
                    .frame(width: geo.size.width * min(max(percent, 0), 1.0))
            }
        }
    }

    private var barColor: Color {
        if isOverage {
            return .red
        } else if percent >= 0.9 {
            return .orange
        } else if percent >= 0.7 {
            return .yellow
        } else {
            return .green
        }
    }
}
