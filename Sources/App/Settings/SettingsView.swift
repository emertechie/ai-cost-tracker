import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var appState: AppState

    @State private var username: String = ""
    @State private var token: String = ""
    @State private var allowance: String = ""
    @State private var refreshMinutes: String = ""
    @State private var showToken = false
    @State private var validationStatus: ValidationStatus = .idle

    enum ValidationStatus: Equatable {
        case idle
        case validating
        case success
        case failure(String)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // GitHub Copilot section
            VStack(alignment: .leading, spacing: 12) {
                Text("GitHub Copilot")
                    .font(.headline)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Username")
                        .font(.subheadline.weight(.medium))
                    TextField("github-username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.leading)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Personal Access Token")
                        .font(.subheadline.weight(.medium))
                    HStack {
                        if showToken {
                            TextField("ghp_...", text: $token)
                                .textFieldStyle(.roundedBorder)
                                .multilineTextAlignment(.leading)
                        } else {
                            SecureField("ghp_...", text: $token)
                                .textFieldStyle(.roundedBorder)
                        }
                        Button(showToken ? "Hide" : "Show") {
                            showToken.toggle()
                        }
                        .buttonStyle(.borderless)
                    }
                    Text("Fine-grained PAT with User \u{2192} Plan (read) permission")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Usage Settings section
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage Settings")
                    .font(.headline)

                HStack {
                    Text("Included allowance")
                    Spacer()
                    TextField("300", text: $allowance)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Refresh interval (minutes)")
                    Spacer()
                    TextField("15", text: $refreshMinutes)
                        .frame(width: 60)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                }
            }

            Divider()

            // Actions
            HStack {
                Button("Save") {
                    save()
                }
                .keyboardShortcut(.defaultAction)

                Button("Test Connection") {
                    testConnection()
                }
                .disabled(username.isEmpty || token.isEmpty)

                Spacer()

                switch validationStatus {
                case .idle:
                    EmptyView()
                case .validating:
                    ProgressView()
                        .controlSize(.small)
                case .success:
                    Label("Connected", systemImage: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                        .font(.caption)
                case .failure(let msg):
                    Label(msg, systemImage: "xmark.circle.fill")
                        .foregroundStyle(.red)
                        .font(.caption)
                }
            }
        }
        .padding(20)
        .frame(width: 420)
        .fixedSize(horizontal: false, vertical: true)
        .onAppear {
            username = appState.username
            token = appState.token
            allowance = String(appState.includedAllowance)
            refreshMinutes = String(appState.refreshIntervalMinutes)
        }
    }

    private func save() {
        appState.username = username
        appState.token = token
        if let a = Int(allowance), a > 0 {
            appState.includedAllowance = a
        }
        if let r = Int(refreshMinutes), r > 0 {
            appState.refreshIntervalMinutes = r
        }
        Task {
            await appState.refresh()
        }
    }

    private func testConnection() {
        validationStatus = .validating
        let provider = GitHubCopilotProvider(username: username, token: token)
        Task {
            do {
                let _ = try await provider.fetchUsage(period: Period.currentUTC())
                validationStatus = .success
            } catch {
                validationStatus = .failure(error.localizedDescription)
            }
        }
    }
}
