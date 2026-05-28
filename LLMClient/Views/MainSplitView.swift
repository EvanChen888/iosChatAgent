import SwiftUI

public struct MainSplitView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                NavigationStack(path: Binding(
                    get: {
                        if let id = viewModel.selectedSessionId {
                            return [id]
                        }
                        return [] as [UUID]
                    },
                    set: { (newPath: [UUID]) in
                        viewModel.selectedSessionId = newPath.last
                    }
                )) {
                    SidebarView(viewModel: viewModel)
                        .navigationDestination(for: UUID.self) { _ in
                            ChatView(viewModel: viewModel)
                        }
                }
            } else {
                NavigationSplitView {
                    SidebarView(viewModel: viewModel)
                } detail: {
                    ChatView(viewModel: viewModel)
                }
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { viewModel.previewImage != nil },
            set: { if !$0 { viewModel.previewImage = nil } }
        )) {
            if let img = viewModel.previewImage {
                FullScreenImageView(image: img)
            }
        }
        .sheet(item: $viewModel.selectedAttachment) { attachment in
            FilePreviewView(attachment: attachment)
        }
    }
}
