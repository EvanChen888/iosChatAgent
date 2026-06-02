import Foundation

public class ChatStorage {
    public static let shared = ChatStorage()
    private let fileName = "chats.json"
    
    private init() {}
    
    private var fileURL: URL {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[0].appendingPathComponent(fileName)
    }
    
    public func saveSessions(_ sessions: [ChatSession]) {
        // Snapshots the value-type array on the calling thread, then
        // encodes + writes entirely off the main actor to avoid UI stalls.
        let sessionsCopy = sessions
        Task.detached(priority: .utility) { [weak self] in
            guard let self = self else { return }
            do {
                let data = try JSONEncoder().encode(sessionsCopy)
                try data.write(to: self.fileURL, options: [.atomic, .completeFileProtection])
            } catch {
                print("Failed to save chat sessions: \(error)")
            }
        }
    }
    
    public func loadSessions() -> [ChatSession] {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return [] }
        
        do {
            let data = try Data(contentsOf: fileURL)
            let sessions = try JSONDecoder().decode([ChatSession].self, from: data)
            return sessions
        } catch {
            print("Failed to load chat sessions: \(error)")
            return []
        }
    }
}
