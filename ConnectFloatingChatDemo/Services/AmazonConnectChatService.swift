import Foundation
import AmazonConnectChatIOS
import AWSCore

@MainActor
final class AmazonConnectChatService: ObservableObject {
    @Published var messages: [ChatMessageItem] = []
    @Published var draftMessage = ""
    @Published var connectionState: ChatConnectionState = .idle
    @Published var bannerText = "Choose a provider and start a chat session."
    @Published var errorText: String?
    @Published var sessionTitle = "Support"
    @Published var providerTitle = ChatProviderMode.mock.title
    @Published var providerDescription = ChatProviderMode.mock.description
    @Published var activeProviderMode: ChatProviderMode = .mock

    private let liveBootstrapProvider: any ChatSessionBootstrapProviding
    private var provider: any ChatProvider

    init(liveBootstrapProvider: any ChatSessionBootstrapProviding = PlaceholderBootstrapProvider()) {
        self.liveBootstrapProvider = liveBootstrapProvider
        let provider = MockChatProvider()
        self.provider = provider
        bind(provider)
    }

    var isConnected: Bool {
        connectionState == .connected
    }

    func startSession(using configuration: ChatProviderConfiguration) {
        activateProvider(for: configuration)
        draftMessage = ""

        Task {
            await provider.startSession()
        }
    }

    func disconnect() {
        Task {
            await provider.disconnect()
        }
    }

    func resetDemo(using configuration: ChatProviderConfiguration? = nil) {
        if let configuration {
            activateProvider(for: configuration)
        }

        draftMessage = ""
        provider.reset()
    }

    func sendDraftMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isConnected else { return }

        draftMessage = ""
        Task {
            await provider.sendMessage(trimmed)
        }
    }

    func clearError() {
        errorText = nil
    }

    private func activateProvider(for configuration: ChatProviderConfiguration) {
        if provider.mode != configuration.providerMode {
            provider = makeProvider(for: configuration.providerMode)
            bind(provider)
        }

        provider.updateConfiguration(configuration)
    }

    private func makeProvider(for mode: ChatProviderMode) -> any ChatProvider {
        switch mode {
        case .mock:
            return MockChatProvider()
        case .amazonConnect:
            return AmazonConnectSDKChatProvider(bootstrapProvider: liveBootstrapProvider)
        }
    }

    private func bind(_ provider: any ChatProvider) {
        provider.onSnapshot = { [weak self] snapshot in
            Task { @MainActor in
                self?.apply(snapshot)
            }
        }
        apply(provider.snapshot)
    }

    private func apply(_ snapshot: ChatProviderSnapshot) {
        messages = snapshot.messages
        connectionState = snapshot.state
        bannerText = snapshot.bannerText
        errorText = snapshot.errorText
        sessionTitle = snapshot.sessionTitle
        providerTitle = snapshot.providerTitle
        providerDescription = snapshot.providerDescription
        activeProviderMode = snapshot.mode
    }
}

private struct ChatProviderSnapshot {
    var mode: ChatProviderMode
    var messages: [ChatMessageItem]
    var state: ChatConnectionState
    var bannerText: String
    var errorText: String?
    var sessionTitle: String
    var providerTitle: String
    var providerDescription: String
}

private protocol ChatProvider: AnyObject {
    var mode: ChatProviderMode { get }
    var snapshot: ChatProviderSnapshot { get }
    var onSnapshot: ((ChatProviderSnapshot) -> Void)? { get set }

    func updateConfiguration(_ configuration: ChatProviderConfiguration)
    func startSession() async
    func sendMessage(_ text: String) async
    func disconnect() async
    func reset()
}

private final class MockChatProvider: ChatProvider {
    let mode: ChatProviderMode = .mock
    var onSnapshot: ((ChatProviderSnapshot) -> Void)?

    private(set) var snapshot: ChatProviderSnapshot
    private var configuration = ChatProviderConfiguration.previewMock
    private var messageIndex = 0

    init() {
        snapshot = ChatProviderSnapshot(
            mode: .mock,
            messages: [],
            state: .idle,
            bannerText: "Mock provider ready. No backend or AWS traffic required.",
            errorText: nil,
            sessionTitle: "Mock Premium Support",
            providerTitle: ChatProviderMode.mock.title,
            providerDescription: ChatProviderMode.mock.description
        )
    }

    func updateConfiguration(_ configuration: ChatProviderConfiguration) {
        self.configuration = configuration
        snapshot.mode = configuration.providerMode
        snapshot.providerTitle = ChatProviderMode.mock.title
        snapshot.providerDescription = ChatProviderMode.mock.description
        if snapshot.state == .idle {
            snapshot.sessionTitle = "Mock Premium Support"
            snapshot.bannerText = "Mock provider ready. No backend or AWS traffic required."
        }
        publish()
    }

    func startSession() async {
        guard snapshot.state != .connecting else { return }

        snapshot.state = .connecting
        snapshot.errorText = nil
        snapshot.messages = []
        snapshot.bannerText = "Loading local transcript..."
        snapshot.sessionTitle = "Mock Premium Support"
        publish()

        try? await Task.sleep(for: .milliseconds(650))

        snapshot.messages = [
            makeMessage(
                text: "Local mock provider started. The UI and chat lifecycle behave like production, but no backend or Amazon Connect API calls are happening yet.",
                senderName: "System",
                direction: .system
            ),
            makeMessage(
                text: "Hi \(configuration.customerName.isEmpty ? "there" : configuration.customerName). I can help with \(configuration.issueType.readableIssueType), refunds, and account questions.",
                senderName: "Ava",
                direction: .incoming
            ),
            makeMessage(
                text: "I already have your \(configuration.membershipTier) membership and order \(configuration.orderId) in context for this simulated chat.",
                senderName: "Ava",
                direction: .incoming
            )
        ]
        snapshot.state = .connected
        snapshot.bannerText = "Mock agent connected."
        publish()
    }

    func sendMessage(_ text: String) async {
        snapshot.messages.append(
            makeMessage(
                text: text,
                senderName: "You",
                direction: .outgoing,
                statusText: "Sent"
            )
        )
        snapshot.bannerText = "Ava is typing..."
        publish()

        try? await Task.sleep(for: .milliseconds(850))

        snapshot.messages.append(
            makeMessage(
                text: mockReply(for: text),
                senderName: "Ava",
                direction: .incoming
            )
        )
        snapshot.bannerText = "Mock agent connected."
        publish()
    }

    func disconnect() async {
        guard snapshot.state == .connected || snapshot.state == .ended else { return }

        snapshot.messages.append(
            makeMessage(
                text: "Mock chat ended.",
                senderName: "System",
                direction: .system
            )
        )
        snapshot.state = .ended
        snapshot.bannerText = "Mock session ended."
        publish()
    }

    func reset() {
        snapshot.messages = []
        snapshot.state = .idle
        snapshot.errorText = nil
        snapshot.sessionTitle = "Mock Premium Support"
        snapshot.bannerText = "Mock provider ready. No backend or AWS traffic required."
        publish()
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
            timeStamp: Date.chatTimeString(),
            direction: direction,
            statusText: statusText
        )
    }

    private func mockReply(for text: String) -> String {
        let normalized = text.lowercased()

        if normalized.contains("refund") {
            return "For a real build, this branch would send your order and membership context to Amazon Connect at chat start, then route the transcript into a refund queue. In mock mode, I can still prove the handoff UX."
        }

        if normalized.contains("order") || normalized.contains("delivery") || normalized.contains("track") {
            return "Your simulated order \(configuration.orderId) is marked in transit and expected tomorrow by 6 PM. This fake reply is here to mimic the agent workflow without needing a backend."
        }

        if normalized.contains("agent") || normalized.contains("human") {
            return "Escalation noted. In the real provider, this same UI would still be used, but the messages would come through the Amazon Connect SDK after your bootstrap service returns participant details."
        }

        return "This mock provider is exercising the same screen, bubble, composer, and transcript behaviors that the real Amazon Connect provider will use later."
    }

    private func publish() {
        onSnapshot?(snapshot)
    }
}

private final class AmazonConnectSDKChatProvider: ChatProvider {
    let mode: ChatProviderMode = .amazonConnect
    var onSnapshot: ((ChatProviderSnapshot) -> Void)?

    private(set) var snapshot: ChatProviderSnapshot
    private let bootstrapProvider: any ChatSessionBootstrapProviding
    private var configuration = ChatProviderConfiguration.previewAmazonConnect
    private var chatSession: any ChatSessionProtocol = ChatSession.shared
    private var callbacksInstalled = false

    init(bootstrapProvider: any ChatSessionBootstrapProviding) {
        self.bootstrapProvider = bootstrapProvider
        snapshot = ChatProviderSnapshot(
            mode: .amazonConnect,
            messages: [],
            state: .idle,
            bannerText: "Real SDK provider ready. Add a bootstrap service to start a live session.",
            errorText: nil,
            sessionTitle: "Amazon Connect Live Session",
            providerTitle: ChatProviderMode.amazonConnect.title,
            providerDescription: ChatProviderMode.amazonConnect.description
        )
    }

    func updateConfiguration(_ configuration: ChatProviderConfiguration) {
        self.configuration = configuration
        configureSDK(region: configuration.region.awsRegionType)
        if snapshot.state == .idle {
            snapshot.bannerText = "Real SDK provider ready. Add a bootstrap service to start a live session."
            snapshot.errorText = nil
            publish()
        }
    }

    func startSession() async {
        guard snapshot.state != .connecting else { return }

        snapshot.state = .connecting
        snapshot.messages = []
        snapshot.errorText = nil
        snapshot.bannerText = "Requesting chat bootstrap..."
        publish()

        do {
            configureSDK(region: configuration.region.awsRegionType)
            installCallbacksIfNeeded()

            let bootstrap = try await bootstrapProvider.fetchBootstrap(using: configuration)
            snapshot.bannerText = "Connecting to Amazon Connect..."
            publish()

            let chatDetails = ChatDetails(
                contactId: bootstrap.contactId,
                participantId: bootstrap.participantId,
                participantToken: bootstrap.participantToken
            )

            try await withCheckedThrowingContinuation { continuation in
                chatSession.connect(chatDetails: chatDetails) { result in
                    continuation.resume(with: result)
                }
            }

            snapshot.state = .connected
            snapshot.bannerText = "Live Amazon Connect session connected."
            publish()
        } catch {
            snapshot.state = .failed
            snapshot.errorText = error.localizedDescription
            snapshot.bannerText = "Live Amazon Connect session unavailable."
            publish()
        }
    }

    func sendMessage(_ text: String) async {
        guard snapshot.state == .connected else { return }

        do {
            try await withCheckedThrowingContinuation { continuation in
                chatSession.sendMessage(contentType: .plainText, message: text) { result in
                    continuation.resume(with: result)
                }
            }
        } catch {
            snapshot.errorText = error.localizedDescription
            publish()
        }
    }

    func disconnect() async {
        guard snapshot.state == .connected || snapshot.state == .ended else { return }

        do {
            try await withCheckedThrowingContinuation { continuation in
                chatSession.disconnect { result in
                    continuation.resume(with: result)
                }
            }
            snapshot.state = .ended
            snapshot.bannerText = "Amazon Connect session ended."
            publish()
        } catch {
            snapshot.errorText = error.localizedDescription
            snapshot.state = .failed
            publish()
        }
    }

    func reset() {
        chatSession.reset()
        snapshot.messages = []
        snapshot.state = .idle
        snapshot.errorText = nil
        snapshot.bannerText = "Real SDK provider ready. Add a bootstrap service to start a live session."
        publish()
    }

    private func configureSDK(region: AWSRegionType) {
        let features = Features(messageReceipts: MessageReceipts(shouldSendMessageReceipts: true, throttleTime: 0.75))
        let config = GlobalConfig(region: region, features: features, disableCsm: true)
        chatSession.configure(config: config)
    }

    private func installCallbacksIfNeeded() {
        guard !callbacksInstalled else { return }
        callbacksInstalled = true

        chatSession.onConnectionEstablished = { [weak self] in
            self?.snapshot.state = .connected
            self?.snapshot.bannerText = "Live Amazon Connect session connected."
            self?.publish()
        }

        chatSession.onConnectionReEstablished = { [weak self] in
            self?.snapshot.state = .connected
            self?.snapshot.bannerText = "Connection restored."
            self?.publish()
        }

        chatSession.onConnectionBroken = { [weak self] in
            self?.snapshot.bannerText = "Connection interrupted. The SDK is attempting to recover."
            self?.publish()
        }

        chatSession.onTranscriptUpdated = { [weak self] transcriptData in
            self?.applyTranscript(transcriptData.transcriptList)
        }

        chatSession.onTyping = { [weak self] event in
            let name = event?.displayName ?? event?.participant ?? "Agent"
            self?.snapshot.bannerText = "\(name) is typing..."
            self?.publish()
        }

        chatSession.onChatEnded = { [weak self] in
            self?.snapshot.state = .ended
            self?.snapshot.bannerText = "Amazon Connect session ended."
            self?.publish()
        }

        chatSession.onDeepHeartbeatFailure = { [weak self] in
            self?.snapshot.bannerText = "Heartbeat missed. Waiting for reconnect..."
            self?.publish()
        }
    }

    private func applyTranscript(_ transcriptItems: [TranscriptItem]) {
        var updatedMessages: [ChatMessageItem] = []

        for item in transcriptItems {
            if let message = item as? Message {
                if message.messageDirection != .Outgoing {
                    chatSession.sendMessageReceipt(for: message, eventType: .messageDelivered)
                }

                updatedMessages.append(
                    ChatMessageItem(
                        id: message.id,
                        text: message.text,
                        senderName: message.displayName ?? message.participant,
                        timeStamp: message.timeStamp,
                        direction: message.messageDirection == .Outgoing ? .outgoing : .incoming,
                        statusText: statusText(for: message)
                    )
                )
            } else if let event = item as? Event {
                let text = event.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                guard !text.isEmpty else { continue }

                updatedMessages.append(
                    ChatMessageItem(
                        id: event.id,
                        text: text,
                        senderName: event.displayName ?? "System",
                        timeStamp: event.timeStamp,
                        direction: .system,
                        statusText: nil
                    )
                )
            }
        }

        snapshot.messages = updatedMessages
        if snapshot.state == .connected {
            snapshot.bannerText = "Live Amazon Connect session connected."
        }
        publish()
    }

    private func statusText(for message: Message) -> String? {
        guard let metadata = message.metadata else {
            return nil
        }

        switch metadata.status {
        case .Delivered:
            return "Delivered"
        case .Read:
            return "Read"
        case .Sending:
            return "Sending"
        case .Failed:
            return "Failed"
        case .Sent:
            return "Sent"
        case .Unknown, .none:
            return nil
        @unknown default:
            return nil
        }
    }

    private func publish() {
        onSnapshot?(snapshot)
    }
}

private extension Date {
    static func chatTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}

private extension String {
    var readableIssueType: String {
        replacingOccurrences(of: "_", with: " ")
    }
}
