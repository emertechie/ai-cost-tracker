import Foundation

/// Protocol for usage data providers. Each provider (GitHub Copilot, OpenAI, etc.)
/// implements this to fetch usage data from its respective API.
protocol UsageProvider {
    var id: String { get }
    var displayName: String { get }

    func fetchUsage(period: Period) async throws -> UsageSnapshot
}
