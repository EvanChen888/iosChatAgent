import SwiftUI

public struct APIKeyView: View {
    let provider: AIProvider
    @EnvironmentObject var settingsViewModel: SettingsViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var apiKey: String = ""

    public var body: some View {
        Form {
            Section(header: Text("\(provider.rawValue) API Key")) {
                SecureField("Enter API Key", text: $apiKey)
            }

            Section {
                Button("Save") {
                    settingsViewModel.saveKey(apiKey, for: provider)
                    dismiss()
                }
                .disabled(apiKey.isEmpty && settingsViewModel.getKey(for: provider).isEmpty)

                Button("Delete Key", role: .destructive) {
                    settingsViewModel.saveKey("", for: provider)
                    dismiss()
                }
                .disabled(settingsViewModel.getKey(for: provider).isEmpty)
            }
        }
        .navigationTitle(provider.rawValue)
        .onAppear {
            apiKey = settingsViewModel.getKey(for: provider)
        }
    }
}
