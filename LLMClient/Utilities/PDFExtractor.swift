import Foundation
import PDFKit
import Vision

public class PDFExtractor {
    
    public enum ExtractionMode {
        case textOnly
        case vision
    }
    
    public static func extractText(from url: URL) -> String? {
        guard let document = PDFDocument(url: url) else {
            return nil
        }
        
        var extractedText = ""
        
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            
            // First try standard text extraction
            if let pageText = page.string, !pageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                extractedText += pageText + "\n"
            } else {
                // If standard text extraction yields nothing (likely a scanned image PDF), fallback to OCR
                if let ocrText = performOCR(on: page) {
                    extractedText += ocrText + "\n"
                }
            }
        }
        
        return extractedText.isEmpty ? nil : extractedText
    }
    
    private static func performOCR(on page: PDFPage) -> String? {
        let pageRect = page.bounds(for: .mediaBox)
        let image = page.thumbnail(of: pageRect.size, for: .mediaBox)
        
        guard let cgImage = image.cgImage else { return nil }
        
        let requestHandler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        
        do {
            try requestHandler.perform([request])
            guard let observations = request.results else { return nil }
            
            let recognizedText = observations.compactMap { observation in
                observation.topCandidates(1).first?.string
            }.joined(separator: "\n")
            
            return recognizedText
        } catch {
            print("OCR Error: \(error)")
            return nil
        }
    }
    
    public static func convertToImages(from url: URL) -> [Data]? {
        guard let document = PDFDocument(url: url) else {
            return nil
        }
        
        var imagesData: [Data] = []
        for i in 0..<document.pageCount {
            guard let page = document.page(at: i) else { continue }
            let pageRect = page.bounds(for: .mediaBox)
            let image = page.thumbnail(of: pageRect.size, for: .mediaBox)
            if let data = image.jpegData(compressionQuality: 0.8) {
                imagesData.append(data)
            }
        }
        
        return imagesData.isEmpty ? nil : imagesData
    }
}
