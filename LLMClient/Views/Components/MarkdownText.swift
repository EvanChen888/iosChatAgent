import SwiftUI
import MarkdownUI

public struct MarkdownText: View {
    let content: String
    
    public init(_ content: String) {
        self.content = content
    }
    
    public var body: some View {
        Markdown(content)
            .markdownTheme(
                Theme()
                    .codeBlock { configuration in
                        ScrollView(.horizontal) {
                            configuration.label
                                .padding(12)
                        }
                        .background(Color(uiColor: .tertiarySystemFill))
                        .cornerRadius(8)
                        .padding(.vertical, 8)
                    }
            )
            .textSelection(.enabled)
    }
}
