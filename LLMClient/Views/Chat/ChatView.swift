import SwiftUI
import PhotosUI

@MainActor
public struct ChatView: View {
    @ObservedObject var viewModel: ChatViewModel
    @State private var showingSettings = false
    @State private var selectedPhotoItem: PhotosPickerItem? = nil
    @State private var showingPhotoPicker = false
    @State private var showingFileImporter = false
    @State private var showingDeepSeekAlert = false
    @State private var showingCamera = false
    @State private var previewImage: UIImage? = nil
    
    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    private var activeSession: ChatSession? {
        if let index = viewModel.activeSessionIndex {
            return viewModel.sessions[index]
        }
        return nil
    }
    
    private func processSelectedPhoto(_ item: PhotosPickerItem?) {
        guard let item = item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self) {
                if let uiImage = UIImage(data: data) {
                    let maxDimension: CGFloat = 1024
                    var size = uiImage.size
                    if size.width > maxDimension || size.height > maxDimension {
                        let ratio = min(maxDimension / size.width, maxDimension / size.height)
                        size = CGSize(width: size.width * ratio, height: size.height * ratio)
                    }
                    
                    UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                    uiImage.draw(in: CGRect(origin: .zero, size: size))
                    let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uiImage
                    UIGraphicsEndImageContext()
                    
                    if let jpegData = resizedImage.jpegData(compressionQuality: 0.6) {
                        let attachment = ChatAttachment(type: .image, data: jpegData)
                        DispatchQueue.main.async {
                            viewModel.pendingAttachments.append(attachment)
                        }
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.selectedPhotoItem = nil
            }
        }
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
                    
                    if !viewModel.pendingAttachments.isEmpty {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(viewModel.pendingAttachments.indices, id: \.self) { index in
                                    let attachment = viewModel.pendingAttachments[index]
                                    ZStack(alignment: .topTrailing) {
                                        if attachment.type == .image, let data = attachment.data, let uiImage = UIImage(data: data) {
                                            Image(uiImage: uiImage)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .onTapGesture {
                                                    previewImage = uiImage
                                                }
                                        } else if attachment.type == .pdf {
                                            VStack {
                                                Image(systemName: "doc.fill")
                                                    .font(.title)
                                                    .foregroundColor(.red)
                                                Text("PDF")
                                                    .font(.caption2)
                                            }
                                            .frame(width: 60, height: 60)
                                            .background(Color(uiColor: .systemGray6))
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                        }
                                        
                                        Button(action: {
                                            viewModel.pendingAttachments.remove(at: index)
                                        }) {
                                            Image(systemName: "xmark.circle.fill")
                                                .foregroundColor(.gray)
                                                .background(Color.white.clipShape(Circle()))
                                        }
                                        .offset(x: 5, y: -5)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 8)
                        }
                    }
                    
                    HStack(alignment: .bottom, spacing: 8) {
                        Menu {
                            Button(action: { showingCamera = true }) {
                                Label("Take Photo", systemImage: "camera")
                            }
                            
                            Button(action: { showingPhotoPicker = true }) {
                                Label("Photo Library", systemImage: "photo")
                            }
                            
                            Button(action: { showingFileImporter = true }) {
                                Label("Choose File", systemImage: "folder")
                            }
                            
                            Toggle(isOn: $viewModel.pdfVisionMode) {
                                Label("PDF Vision Mode", systemImage: "eye")
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .resizable()
                                .frame(width: 28, height: 28)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 6)
                        .onChange(of: selectedPhotoItem) { newItem in
                            processSelectedPhoto(newItem)
                        }
                        
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
                            if viewModel.activeModel?.provider == .deepseek && viewModel.pendingAttachments.contains(where: { $0.type == .image || (viewModel.pdfVisionMode && $0.type == .pdf) }) {
                                showingDeepSeekAlert = true
                            } else {
                                viewModel.sendMessage()
                            }
                        }) {
                            Image(systemName: "arrow.up.circle.fill")
                                .resizable()
                                .frame(width: 32, height: 32)
                                .foregroundColor(viewModel.isGenerating || (viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.pendingAttachments.isEmpty) ? .gray : .blue)
                        }
                        .disabled(viewModel.isGenerating || (viewModel.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && viewModel.pendingAttachments.isEmpty))
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
        .fileImporter(isPresented: $showingFileImporter, allowedContentTypes: [.pdf, .plainText]) { result in
            switch result {
            case .success(let url):
                if url.startAccessingSecurityScopedResource() {
                    defer { url.stopAccessingSecurityScopedResource() }
                    let ext = url.pathExtension.lowercased()
                    let type: ChatAttachment.AttachmentType = (ext == "pdf") ? .pdf : .text
                    
                    if let data = try? Data(contentsOf: url) {
                        let attachment = ChatAttachment(type: type, url: url, data: data, fileName: url.lastPathComponent)
                        DispatchQueue.main.async {
                            viewModel.pendingAttachments.append(attachment)
                        }
                    } else {
                        print("Failed to read data from URL: \(url)")
                    }
                }
            case .failure(let error):
                print("File import failed: \(error.localizedDescription)")
            }
        }
        .alert(isPresented: $showingDeepSeekAlert) {
            Alert(
                title: Text("Unsupported Model"),
                message: Text("DeepSeek models currently do not support image attachments. Please remove the image or switch to a vision-capable model like GPT or Claude."),
                dismissButton: .default(Text("OK"))
            )
        }
        .photosPicker(isPresented: $showingPhotoPicker, selection: $selectedPhotoItem, matching: .images)
        .fullScreenCover(isPresented: $showingCamera) {
            ImagePicker(sourceType: .camera) { uiImage in
                // Process and compress captured image
                let maxDimension: CGFloat = 1024
                var size = uiImage.size
                if size.width > maxDimension || size.height > maxDimension {
                    let ratio = min(maxDimension / size.width, maxDimension / size.height)
                    size = CGSize(width: size.width * ratio, height: size.height * ratio)
                }
                
                UIGraphicsBeginImageContextWithOptions(size, false, 1.0)
                uiImage.draw(in: CGRect(origin: .zero, size: size))
                let resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? uiImage
                UIGraphicsEndImageContext()
                
                if let jpegData = resizedImage.jpegData(compressionQuality: 0.6) {
                    let attachment = ChatAttachment(type: .image, data: jpegData)
                    DispatchQueue.main.async {
                        viewModel.pendingAttachments.append(attachment)
                    }
                }
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: Binding(
            get: { previewImage != nil },
            set: { if !$0 { previewImage = nil } }
        )) {
            if let img = previewImage {
                FullScreenImageView(image: img)
            }
        }
    }
}
