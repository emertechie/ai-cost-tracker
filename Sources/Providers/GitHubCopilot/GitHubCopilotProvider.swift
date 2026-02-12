import Foundation

enum GitHubCopilotError: LocalizedError {
    case invalidResponse(Int)
    case unauthorized
    case decodingFailed(String)
    case networkError(String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse(let code):
            return "GitHub API returned status \(code)"
        case .unauthorized:
            return "Unauthorized. Check your GitHub token has 'Plan (read)' permission."
        case .decodingFailed(let detail):
            return "Failed to parse GitHub response: \(detail)"
        case .networkError(let detail):
            return "Network error: \(detail)"
        }
    }
}

/// Fetches GitHub Copilot premium request usage for a personal account.
final class GitHubCopilotProvider: UsageProvider {

    let id = "github-copilot"
    let displayName = "GitHub Copilot"

    private let username: String
    private let token: String
    private let session: URLSession

    init(username: String, token: String, session: URLSession = .shared) {
        self.username = username
        self.token = token
        self.session = session
    }

    func fetchUsage(period: Period) async throws -> UsageSnapshot {
        let url = buildURL(period: period)
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            throw GitHubCopilotError.networkError(error.localizedDescription)
        }

        guard let http = response as? HTTPURLResponse else {
            throw GitHubCopilotError.networkError("Invalid response type")
        }

        switch http.statusCode {
        case 200:
            break
        case 401, 403:
            throw GitHubCopilotError.unauthorized
        default:
            throw GitHubCopilotError.invalidResponse(http.statusCode)
        }

        let ghResponse: GitHubUsageResponse
        do {
            ghResponse = try JSONDecoder().decode(GitHubUsageResponse.self, from: data)
        } catch {
            throw GitHubCopilotError.decodingFailed(error.localizedDescription)
        }

        return aggregate(ghResponse, period: period)
    }

    // MARK: - Private

    private func buildURL(period: Period) -> URL {
        var components = URLComponents(string: "https://api.github.com/users/\(username)/settings/billing/premium_request/usage")!
        components.queryItems = [
            URLQueryItem(name: "year", value: String(period.year)),
            URLQueryItem(name: "month", value: String(period.month)),
        ]
        return components.url!
    }

    private func aggregate(_ response: GitHubUsageResponse, period: Period) -> UsageSnapshot {
        let includedConsumed = response.usageItems.reduce(0) { sum, item in
            sum + Int((item.discountQuantity ?? 0).rounded())
        }

        let billedQuantity = response.usageItems.reduce(0) { sum, item in
            sum + Int((item.netQuantity ?? 0).rounded())
        }

        let billedAmount = response.usageItems.reduce(0.0) { sum, item in
            sum + (item.netAmount ?? 0.0)
        }

        // Build per-model breakdowns
        var byModel: [String: (gross: Int, discount: Int, net: Int, amount: Double)] = [:]
        for item in response.usageItems {
            let key = item.model ?? "unknown"
            var entry = byModel[key, default: (0, 0, 0, 0.0)]
            entry.gross += Int((item.grossQuantity ?? 0).rounded())
            entry.discount += Int((item.discountQuantity ?? 0).rounded())
            entry.net += Int((item.netQuantity ?? 0).rounded())
            entry.amount += item.netAmount ?? 0.0
            byModel[key] = entry
        }

        let breakdowns = byModel.map { key, val in
            ModelBreakdown(
                model: key,
                grossQuantity: val.gross,
                discountQuantity: val.discount,
                netQuantity: val.net,
                netAmount: val.amount
            )
        }.sorted { $0.grossQuantity > $1.grossQuantity }

        return UsageSnapshot(
            providerId: id,
            period: period,
            includedConsumed: includedConsumed,
            includedAllowance: 300, // Will be overridden by AppState
            billedAmount: billedAmount,
            billedQuantity: billedQuantity,
            breakdowns: breakdowns,
            fetchedAt: Date()
        )
    }
}
