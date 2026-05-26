import SwiftUI

public struct ModelPicker: View {
    @ObservedObject var viewModel: ChatViewModel
    
    public init(viewModel: ChatViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Menu {
            ForEach(AIModel.availableModels) { model in
                Button(action: {
                    if let sessionId = viewModel.selectedSessionId {
                        viewModel.setModel(for: sessionId, modelId: model.id)
                    }
                }) {
                    HStack {
                        Text(model.name)
                        if viewModel.activeModel?.id == model.id {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(viewModel.activeModel?.name ?? "Select Model")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption)
            }
            .foregroundColor(.primary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color(uiColor: .systemGray6))
            .cornerRadius(8)
        }
    }
}
