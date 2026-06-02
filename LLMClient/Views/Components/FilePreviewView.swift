import SwiftUI
import PDFKit

public struct FilePreviewView: View {
    let attachment: ChatAttachment
    @Environment(\.dismiss) private var dismiss
    
    public init(attachment: ChatAttachment) {
        self.attachment = attachment
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if attachment.type == .pdf {
                    if let data = attachment.data {
                        PDFKitView(data: data)
                    } else if let url = attachment.url {
                        PDFKitView(url: url)
                    } else {
                        Text("PDF data not available")
                            .foregroundColor(.gray)
                    }
                } else {
                    if let data = attachment.data, let text = String(data: data, encoding: .utf8) {
                        ScrollView {
                            Text(text)
                                .font(.system(.body, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    } else {
                        VStack(spacing: 16) {
                            Image(systemName: "doc.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("Preview not available for this file type")
                                .font(.headline)
                        }
                    }
                }
            }
            .navigationTitle(attachment.fileName ?? "File Preview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Text("Done")
                            .fontWeight(.bold)
                    }
                }
            }
        }
    }
}

struct PDFKitView: UIViewRepresentable {
    var url: URL?
    var data: Data?
    
    func makeUIView(context: Context) -> PDFView {
        let pdfView = PDFView()
        pdfView.autoScales = true
        pdfView.displayMode = .singlePageContinuous
        pdfView.displayDirection = .vertical
        return pdfView
    }
    
    func updateUIView(_ pdfView: PDFView, context: Context) {
        if let data = data {
            pdfView.document = PDFDocument(data: data)
        } else if let url = url {
            pdfView.document = PDFDocument(url: url)
        }
    }
}
