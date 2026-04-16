import Foundation

enum ChatConnectionState {
    case idle
    case connecting
    case connected
    case ended
    case failed
}

enum ChatMessageDirection {
    case incoming
    case outgoing
    case system
}

struct ChatActionChip: Identifiable, Equatable {
    let id: String
    let title: String
    let prompt: String
}

struct HotelCardItem: Identifiable, Equatable, Codable {
    let id: String
    let name: String
    let location: String
    let nightlyPrice: String
    let ratingText: String
    let badgeText: String
    let summary: String
}

struct ChatEmbeddedComponent: Identifiable, Equatable {
    let id: String
    let componentKey: String
    let title: String
    let subtitle: String?
    let payload: [String: String]
}

enum ChatMessageContent: Equatable {
    case text(String)
    case embeddedComponent(ChatEmbeddedComponent)
}

struct ChatMessageItem: Identifiable, Equatable {
    let id: String
    let content: ChatMessageContent
    let senderName: String
    let timeStamp: String
    let direction: ChatMessageDirection
    let statusText: String?
    let actionChips: [ChatActionChip]

    init(
        id: String,
        text: String,
        senderName: String,
        timeStamp: String,
        direction: ChatMessageDirection,
        statusText: String? = nil,
        actionChips: [ChatActionChip] = []
    ) {
        self.id = id
        self.content = .text(text)
        self.senderName = senderName
        self.timeStamp = timeStamp
        self.direction = direction
        self.statusText = statusText
        self.actionChips = actionChips
    }

    init(
        id: String,
        content: ChatMessageContent,
        senderName: String,
        timeStamp: String,
        direction: ChatMessageDirection,
        statusText: String? = nil,
        actionChips: [ChatActionChip] = []
    ) {
        self.id = id
        self.content = content
        self.senderName = senderName
        self.timeStamp = timeStamp
        self.direction = direction
        self.statusText = statusText
        self.actionChips = actionChips
    }
}

enum ChatComponentPayloadCoder {
    static let encodedJSONKey = "encoded_json"

    static func encode<Value: Encodable>(_ value: Value) -> [String: String] {
        let encoder = JSONEncoder()
        guard
            let data = try? encoder.encode(value),
            let json = String(data: data, encoding: .utf8)
        else {
            return [:]
        }

        return [encodedJSONKey: json]
    }

    static func decode<Value: Decodable>(_ type: Value.Type, from component: ChatEmbeddedComponent) -> Value? {
        guard let json = component.payload[encodedJSONKey] else {
            return nil
        }

        let decoder = JSONDecoder()
        guard let data = json.data(using: .utf8) else {
            return nil
        }

        return try? decoder.decode(Value.self, from: data)
    }
}
