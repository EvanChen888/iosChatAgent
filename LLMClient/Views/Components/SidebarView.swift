import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: ChatViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ViewBuilder
    private var listContent: some View {
        ForEach(viewModel.sessions) { session in
            NavigationLink(value: session.id) {
                VStack(alignment: .leading) {
                    Text(session.title)
                        .lineLimit(1)
                        .font(.headline)
                    Text(session.createdAt, style: .date)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .onDelete(perform: viewModel.deleteChat)
    }
    
    public var body: some View {
        Group {
            if horizontalSizeClass == .compact {
                List {
                    listContent
                }
            } else {
                List(selection: $viewModel.selectedSessionId) {
                    listContent
                }
            }
        }
        .navigationTitle("History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    viewModel.createNewChat()
                }) {
                    Image(systemName: "square.and.pencil")
                }
            }
        }
    }
}
