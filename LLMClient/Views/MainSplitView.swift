import SwiftUI

public struct MainSplitView: View {
    @StateObject private var viewModel = ChatViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationSplitView {
            SidebarView(viewModel: viewModel)
        } detail: {
            ChatView(viewModel: viewModel)
        }
    }
}
