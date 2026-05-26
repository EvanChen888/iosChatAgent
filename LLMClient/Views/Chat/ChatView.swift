import SwiftUI

public struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @State private var showingSettings = false
    
    public init() {}
    
    public var body: some View {
        VStack {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.session.messages) { message in
                        MessageBubble(message: message)
                    }
                }
                .padding()
            }
            
            HStack {
                TextField("Message...", text: $viewModel.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(viewModel.isGenerating)
                
                Button(action: {
                    viewModel.sendMessage()
                }) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(viewModel.isGenerating || viewModel.inputText.isEmpty ? .gray : .blue)
                }
                .disabled(viewModel.isGenerating || viewModel.inputText.isEmpty)
            }
            .padding()
        }
        .navigationTitle(viewModel.session.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ProviderSettingsView()
        }
    }
}
