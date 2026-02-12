import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    // MARK: - Published state
    @Published var snapshot: UsageSnapshot?
    @Published var isLoading = false
    @Published var lastError: String?
    @Published var lastFetchedAt: Date?

    // MARK: - Dependencies
    private let config = AppConfigStore()
    private let keychain = KeychainStore()
    private var provider: GitHubCopilotProvider?
    private var pollTimer: Timer?

    init() {
        loadCachedSnapshot()
        configureProvider()
        startPolling()
    }

    // MARK: - Configuration

    var username: String {
        get { config.username }
        set {
            config.username = newValue
            configureProvider()
        }
    }

    var token: String {
        get { keychain.gitHubToken ?? "" }
        set {
            keychain.gitHubToken = newValue.isEmpty ? nil : newValue
            configureProvider()
        }
    }

    var hasToken: Bool {
        keychain.gitHubToken != nil
    }

    var includedAllowance: Int {
        get { config.includedAllowance }
        set {
            config.includedAllowance = newValue
            if var snap = snapshot {
                snap = snap.withAllowance(newValue)
                self.snapshot = snap
            }
        }
    }

    var refreshIntervalMinutes: Int {
        get { config.refreshIntervalMinutes }
        set {
            config.refreshIntervalMinutes = newValue
            startPolling()
        }
    }

    var isConfigured: Bool {
        !username.isEmpty && hasToken
    }

    // MARK: - Fetching

    func refresh() async {
        guard let provider else {
            lastError = "Not configured. Set username and token in Settings."
            return
        }

        isLoading = true
        lastError = nil

        do {
            let period = Period.currentUTC()
            var snap = try await provider.fetchUsage(period: period)
            snap = snap.withAllowance(config.includedAllowance)
            self.snapshot = snap
            self.lastFetchedAt = snap.fetchedAt
            self.lastError = nil
            cacheSnapshot(snap)
        } catch {
            self.lastError = error.localizedDescription
        }

        isLoading = false
    }

    // MARK: - Private

    private func configureProvider() {
        guard !username.isEmpty, let token = keychain.gitHubToken, !token.isEmpty else {
            provider = nil
            return
        }
        provider = GitHubCopilotProvider(username: username, token: token)
    }

    private func startPolling() {
        pollTimer?.invalidate()
        let interval = TimeInterval(config.refreshIntervalMinutes * 60)
        pollTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor in
                await self.refresh()
            }
        }
        // Also do an initial fetch if configured
        if isConfigured {
            Task {
                await refresh()
            }
        }
    }

    // MARK: - Snapshot persistence

    private var cacheURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AICostTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("last_snapshot.json")
    }

    private func cacheSnapshot(_ snapshot: UsageSnapshot) {
        if let data = try? JSONEncoder().encode(snapshot) {
            try? data.write(to: cacheURL, options: .atomic)
        }
    }

    private func loadCachedSnapshot() {
        guard let data = try? Data(contentsOf: cacheURL),
              let cached = try? JSONDecoder().decode(UsageSnapshot.self, from: data) else { return }
        self.snapshot = cached
        self.lastFetchedAt = cached.fetchedAt
    }
}
