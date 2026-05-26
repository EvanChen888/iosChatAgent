import SwiftUI

public struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingSettings = false
    
    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    private var activeSession: ChatSession? {
        if let index = viewModel.activeSessionIndex {
            return viewModel.sessions[index]
        }
        return nil
    }
    
    public var body: some View {
        VStack {
            if let session = activeSession {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(session.messages) { message in
                                MessageBubble(message: message)
                                    .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: session.messages.count) { _ in
                        if let lastMessage = session.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                    .onChange(of: session.messages.last?.content) { _ in
                        if let lastMessage = session.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
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
            } else {
                Text("Select or create a chat to begin.")
                    .foregroundColor(.gray)
            }
        }
        .navigationTitle(activeSession?.title ?? "Chat")
        .toolbar {
            ToolbarItem(placement: .principal) {
                ModelPicker(viewModel: viewModel)
            }
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
