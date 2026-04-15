import Foundation

enum ChatMessageDirection {
    case incoming
    case outgoing
    case system
}

struct ChatMessageItem: Identifiable, Equatable {
    let id: String
    let text: String
    let senderName: String
    let timeStamp: String
    let direction: ChatMessageDirection
    let statusText: String?
}
