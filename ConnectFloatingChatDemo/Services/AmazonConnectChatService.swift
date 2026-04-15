import Foundation
import AmazonConnectChatIOS
import AWSCore

@MainActor
final class AmazonConnectChatService: ObservableObject {
    enum ConnectionState {
        case idle
        case connecting
        case connected
        case ended
        case failed
    }

    @Published var messages: [ChatMessageItem] = []
    @Published var draftMessage = ""
    @Published var connectionState: ConnectionState = .idle
    @Published var bannerText = "Mock mode ready. No Amazon Connect API calls are made."
    @Published var errorText: String?
    @Published var sessionTitle = "Mock Premium Support"

    private var chatSession: any ChatSessionProtocol = ChatSession.shared
    private var messageIndex = 0

    init() {
        let features = Features(messageReceipts: MessageReceipts(shouldSendMessageReceipts: true, throttleTime: 0.75))
        let config = GlobalConfig(region: .USEast1, features: features, disableCsm: true)
        chatSession.configure(config: config)
    }

    var isConnected: Bool {
        connectionState == .connected
    }

    func startMockChat() {
        guard connectionState != .connecting else { return }

        Task {
            connectionState = .connecting
            bannerText = "Starting mock transcript..."
            errorText = nil
            draftMessage = ""
            messages = []

            try? await Task.sleep(for: .milliseconds(650))

            let openingMessages = [
                makeMessage(
                    text: "Connected to the mock support session. The Amazon Connect SDK is linked in the app, but this transcript is locally simulated for POC review.",
                    senderName: "System",
                    direction: .system
                ),
                makeMessage(
                    text: "Hi Taylor, welcome back. I can help with order status, refunds, and delivery changes.",
                    senderName: "Ava",
                    direction: .incoming
                ),
                makeMessage(
                    text: "Try sending something like 'Where is my order?' or 'I want a refund' to see the floating chat behavior.",
                    senderName: "Ava",
                    direction: .incoming
                )
            ]

            messages = openingMessages
            connectionState = .connected
            sessionTitle = "Mock Premium Support"
            bannerText = "Mock agent connected."
        }
    }

    func disconnect() {
        guard connectionState == .connected || connectionState == .ended else { return }

        messages.append(
            makeMessage(
                text: "Mock chat ended.",
                senderName: "System",
                direction: .system
            )
        )
        connectionState = .ended
        bannerText = "Mock session ended."
    }

    func resetDemo() {
        draftMessage = ""
        messages = []
        connectionState = .idle
        errorText = nil
        bannerText = "Mock mode ready. No Amazon Connect API calls are made."
    }

    func sendDraftMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isConnected else { return }

        draftMessage = ""
        messages.append(
            makeMessage(
                text: trimmed,
                senderName: "You",
                direction: .outgoing,
                statusText: "Sent"
            )
        )

        Task {
            bannerText = "Ava is typing..."
            try? await Task.sleep(for: .milliseconds(850))

            messages.append(
                makeMessage(
                    text: mockReply(for: trimmed),
                    senderName: "Ava",
                    direction: .incoming
                )
            )
            bannerText = "Mock agent connected."
        }
    }

    func clearError() {
        errorText = nil
    }

    private func makeMessage(
        text: String,
        senderName: String,
        direction: ChatMessageDirection,
        statusText: String? = nil
    ) -> ChatMessageItem {
        messageIndex += 1
        return ChatMessageItem(
            id: "mock-\(messageIndex)",
            text: text,
            senderName: senderName,
            timeStamp: timestampString(),
            direction: direction,
            statusText: statusText
        )
    }

    private func timestampString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }

    private func mockReply(for text: String) -> String {
        let normalized = text.lowercased()

        if normalized.contains("refund") {
            return "I can help with that. In a real Amazon Connect session this is where we would branch into the refund workflow, gather the order ID, and hand off to an agent queue if needed."
        }

        if normalized.contains("order") || normalized.contains("delivery") || normalized.contains("track") {
            return "Your mock order is currently marked as shipped and expected tomorrow by 6 PM. This is fake data, but it shows the transcript and overlay behavior clearly."
        }

        if normalized.contains("agent") || normalized.contains("human") {
            return "Escalation noted. For the POC, this simulated response stands in for routing into a live Amazon Connect queue or transfer flow."
        }

        return "That looks good for the POC. We can keep using this mock transcript to validate floating bubble behavior, composer UX, and transcript rendering before wiring a real backend."
    }
}
