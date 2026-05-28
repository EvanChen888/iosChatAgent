import SwiftUI

public struct MainSplitView: View {
    @StateObject private var viewModel = ChatViewModel()
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    public init() {}
    
    public var body: some View {
        if horizontalSizeClass == .compact {
            NavigationStack(path: Binding(
                get: {
                    if let id = viewModel.selectedSessionId {
                        return [id]
                    }
                    return []
                },
                set: { newPath in
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
}
