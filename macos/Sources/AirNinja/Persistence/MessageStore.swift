import Foundation

/// Persists received SMS to Application Support so the menu-bar list survives restarts.
final class MessageStore {
    private let url = AppSupport.directory().appendingPathComponent("messages.json")

    func load() -> [ReceivedSms] {
        guard let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([ReceivedSms].self, from: data) else {
            return []
        }
        return decoded
    }

    func save(_ messages: [ReceivedSms]) {
        guard let data = try? JSONEncoder().encode(messages) else { return }
        try? data.write(to: url, options: .atomic)
    }
}
