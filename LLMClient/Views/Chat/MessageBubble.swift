import SwiftUI

public struct MessageBubble: View {
    public let message: ChatMessage
    
    public var body: some View {
        HStack {
            if message.role == .user { Spacer() }
            
            Text(message.content)
                .padding(12)
                .background(message.role == .user ? Color.blue : Color.gray.opacity(0.2))
                .foregroundColor(message.role == .user ? .white : .primary)
                .cornerRadius(16)
                .textSelection(.enabled)
            
            if message.role != .user { Spacer() }
        }
    }
}
