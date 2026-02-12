import Foundation

/// Stores non-secret application settings to a JSON file in Application Support.
final class AppConfigStore {

    private struct Config: Codable {
        var username: String = ""
        var includedAllowance: Int = 300
        var refreshIntervalMinutes: Int = 15
    }

    private var config: Config
    private let fileURL: URL

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("AICostTracker", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.fileURL = dir.appendingPathComponent("config.json")

        if let data = try? Data(contentsOf: fileURL),
           let loaded = try? JSONDecoder().decode(Config.self, from: data) {
            self.config = loaded
        } else {
            self.config = Config()
        }
    }

    var username: String {
        get { config.username }
        set { config.username = newValue; save() }
    }

    var includedAllowance: Int {
        get { config.includedAllowance }
        set { config.includedAllowance = newValue; save() }
    }

    var refreshIntervalMinutes: Int {
        get { config.refreshIntervalMinutes }
        set { config.refreshIntervalMinutes = newValue; save() }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(config) {
            try? data.write(to: fileURL, options: .atomic)
        }
    }
}
