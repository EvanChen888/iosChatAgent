import SwiftUI

public struct ProviderSettingsView: View {
    @StateObject private var settingsViewModel = SettingsViewModel()
    @Environment(\.presentationMode) var presentationMode
    
    public init() {}
    
    public var body: some View {
        NavigationView {
            List {
                Section(header: Text("AI Providers")) {
                    ForEach(AIProvider.allCases) { provider in
                        NavigationLink(destination: APIKeyView(provider: provider).environmentObject(settingsViewModel)) {
                            HStack {
                                Text(provider.rawValue)
                                Spacer()
                                
                                if settingsViewModel.providerConfigured[provider] == true {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundColor(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
