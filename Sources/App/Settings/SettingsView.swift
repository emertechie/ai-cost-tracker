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
        Form {
            Section("GitHub Copilot") {
                TextField("Username", text: $username)
                    .textFieldStyle(.roundedBorder)

                HStack {
                    if showToken {
                        TextField("Personal Access Token", text: $token)
                            .textFieldStyle(.roundedBorder)
                    } else {
                        SecureField("Personal Access Token", text: $token)
                            .textFieldStyle(.roundedBorder)
                    }
                    Button(showToken ? "Hide" : "Show") {
                        showToken.toggle()
                    }
                    .buttonStyle(.borderless)
                }

                Text("Fine-grained PAT with User → Plan (read) permission")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Usage Settings") {
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

            Section {
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
        }
        .formStyle(.grouped)
        .frame(width: 420, height: 340)
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
