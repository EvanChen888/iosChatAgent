import SwiftUI

public struct SidebarView: View {
    @ObservedObject var viewModel: ChatViewModel
    
    public var body: some View {
        List(selection: $viewModel.selectedSessionId) {
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
