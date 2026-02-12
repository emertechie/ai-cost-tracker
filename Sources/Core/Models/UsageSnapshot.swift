import Foundation

struct UsageSnapshot: Codable, Equatable {
    let providerId: String
    let period: Period
    let includedConsumed: Int
    let includedAllowance: Int
    let billedAmount: Double
    let billedQuantity: Int
    let breakdowns: [ModelBreakdown]
    let fetchedAt: Date

    var includedPercent: Double {
        guard includedAllowance > 0 else { return 0 }
        return Double(includedConsumed) / Double(includedAllowance)
    }

    var isOverage: Bool {
        billedAmount > 0
    }

    func withAllowance(_ allowance: Int) -> UsageSnapshot {
        UsageSnapshot(
            providerId: providerId,
            period: period,
            includedConsumed: includedConsumed,
            includedAllowance: allowance,
            billedAmount: billedAmount,
            billedQuantity: billedQuantity,
            breakdowns: breakdowns,
            fetchedAt: fetchedAt
        )
    }
}

struct ModelBreakdown: Codable, Equatable, Identifiable {
    var id: String { model }
    let model: String
    let grossQuantity: Int
    let discountQuantity: Int
    let netQuantity: Int
    let netAmount: Double
}
