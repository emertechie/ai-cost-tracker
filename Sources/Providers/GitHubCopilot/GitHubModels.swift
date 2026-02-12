import Foundation

/// GitHub API response models for Copilot premium request usage.
struct GitHubUsageResponse: Codable {
    let usageItems: [GitHubUsageItem]
}

struct GitHubUsageItem: Codable {
    let date: String?
    let product: String?
    let sku: String?
    let model: String?
    let grossQuantity: Double?
    let discountQuantity: Double?
    let netQuantity: Double?
    let grossAmount: Double?
    let discountAmount: Double?
    let netAmount: Double?
    let unitType: String?
    let pricePerUnit: Double?
}
