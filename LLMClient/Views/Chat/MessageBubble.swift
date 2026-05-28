import SwiftUI

public struct MessageBubble: View, Equatable {
    public let message: ChatMessage
    public var onImageTap: ((UIImage) -> Void)?
    public var onAttachmentTap: ((ChatAttachment) -> Void)?
    
    public static func == (lhs: MessageBubble, rhs: MessageBubble) -> Bool {
        lhs.message == rhs.message
    }
    
    public var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .user { Spacer(minLength: 40) }
            
            VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
                if let attachments = message.attachments, !attachments.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(attachments) { attachment in
                                if attachment.type == .image, let data = attachment.data, let uiImage = UIImage(data: data) {
                                    Image(uiImage: uiImage)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 120, height: 120)
                                        .clipped()
                                        .cornerRadius(8)
                                        .onTapGesture {
                                            onImageTap?(uiImage)
                                        }
                                } else if attachment.type == .pdf {
                                    VStack {
                                        Image(systemName: "doc.fill")
                                            .font(.title)
                                            .foregroundColor(.red)
                                        Text(attachment.fileName ?? "PDF")
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80, height: 120)
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        onAttachmentTap?(attachment)
                                    }
                                } else {
                                    VStack {
                                        Image(systemName: "doc.text.fill")
                                            .font(.title)
                                            .foregroundColor(.blue)
                                        Text(attachment.fileName ?? "File")
                                            .font(.caption2)
                                            .lineLimit(1)
                                    }
                                    .frame(width: 80, height: 120)
                                    .background(Color(uiColor: .systemGray6))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        onAttachmentTap?(attachment)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.bottom, 4)
                }
                
                if let reasoning = message.reasoningContent, !reasoning.isEmpty {
                    DisclosureGroup {
                        MarkdownText(reasoning)
                            .padding(.top, 4)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "brain.head.profile")
                            Text("Thinking Process")
                        }
                        .font(.caption)
                        .foregroundColor(.gray)
                    }
                    .padding(8)
                    .background(Color(uiColor: .systemGray6))
                    .cornerRadius(8)
                    .padding(.bottom, 4)
                }
                
                MarkdownText(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.role == .user {
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.blue.opacity(0.85), Color.indigo]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            } else {
                                Color(uiColor: .secondarySystemGroupedBackground)
                            }
                        }
                    )
                    .foregroundColor(message.role == .user ? .white : .primary)
                    .clipShape(ChatBubbleShape(isUser: message.role == .user))
                    .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: 1)
                
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

struct FullScreenImageView: View {
    let image: UIImage
    @Environment(\.dismiss) private var dismiss
    @State private var scale: CGFloat = 1.0
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .scaleEffect(scale)
                .gesture(
                    MagnificationGesture()
                        .onChanged { value in
                            scale = value.magnitude
                        }
                        .onEnded { _ in
                            withAnimation {
                                scale = 1.0
                            }
                        }
                )
            
            VStack {
                HStack {
                    Spacer()
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundColor(.white)
                            .padding()
                    }
                }
                Spacer()
            }
        }
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
