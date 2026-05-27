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
                                    .transition(.asymmetric(insertion: .scale(scale: 0.95).combined(with: .opacity), removal: .opacity))
                            }
                        }
                        .padding()
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: session.messages.count)
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
                
                VStack(spacing: 0) {
                    Divider()
                    HStack(alignment: .bottom) {
                        TextField("Message...", text: $viewModel.inputText, axis: .vertical)
                            .lineLimit(1...5)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(Color(uiColor: .systemBackground))
                            .cornerRadius(20)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                            )
                            .disabled(viewModel.isGenerating)
                        
                        Button(action: {
                            viewModel.sendMessage()
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(viewModel.isGenerating || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                        }
                        .disabled(viewModel.isGenerating || viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        .padding(.bottom, 4)
                        .padding(.leading, 4)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                    .background(.ultraThinMaterial)
                }
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
