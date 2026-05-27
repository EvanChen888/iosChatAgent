import SwiftUI

public struct MessageBubble: View {
    public let message: ChatMessage
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 40) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                MarkdownText(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.role == .user {
                                LinearGradient(gradient: Gradient(colors: [Color.blue, Color.purple.opacity(0.8)]), startPoint: .topLeading, endPoint: .bottomTrailing)
                            } else {
                                Color(uiColor: .systemGray6)
                            }
                        }
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(ChatBubbleShape(isUser: message.role == .user))
                    .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
                
                if let usage = message.tokenUsage {
                    HStack(spacing: 4) {
                        Image(systemName: "dollarsign.circle")
                        if let cost = message.cost {
                            Text(String(format: "$%.4f", cost))
                        }
                        Text("(\(usage.promptTokens) In / \(usage.completionTokens) Out)")
                    }
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .padding(.horizontal, 4)
                }
            }
            
            if message.role != .user { Spacer(minLength: 40) }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }
}

struct ChatBubbleShape: Shape {
    let isUser: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: [
                .topLeft,
                .topRight,
                isUser ? .bottomLeft : .bottomRight
            ],
            cornerRadii: CGSize(width: 20, height: 20)
        )
        return Path(path.cgPath)
    }
}
