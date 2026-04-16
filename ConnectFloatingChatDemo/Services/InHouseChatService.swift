import Foundation

@MainActor
final class InHouseChatService: ObservableObject {
    @Published var messages: [ChatMessageItem] = []
    @Published var draftMessage = ""
    @Published var connectionState: ChatConnectionState = .idle
    @Published var bannerText = "Start the in-house travel assistant."
    @Published var errorText: String?
    @Published var sessionTitle = "Travel Concierge"
    @Published var experienceDescription = "Runs locally and can render reusable SwiftUI components directly inside the transcript."

    private var configuration = ChatExperienceConfiguration.preview
    private var messageIndex = 0

    var isConnected: Bool {
        connectionState == .connected
    }

    func startSession(using configuration: ChatExperienceConfiguration) {
        self.configuration = configuration
        draftMessage = ""

        Task {
            await beginSession()
        }
    }

    func disconnect() {
        Task {
            await endSession()
        }
    }

    func resetDemo(using configuration: ChatExperienceConfiguration? = nil) {
        if let configuration {
            self.configuration = configuration
        }

        draftMessage = ""
        messages = []
        connectionState = .idle
        errorText = nil
        sessionTitle = "Travel Concierge"
        bannerText = "Start the in-house travel assistant."
        experienceDescription = "Runs locally and can render reusable SwiftUI components directly inside the transcript."
    }

    func sendDraftMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, isConnected else { return }

        draftMessage = ""
        Task {
            await sendMessage(trimmed)
        }
    }

    func clearError() {
        errorText = nil
    }

    private func beginSession() async {
        guard connectionState != .connecting else { return }

        connectionState = .connecting
        errorText = nil
        messages = []
        bannerText = "Loading travel assistant..."
        sessionTitle = "Travel Concierge"

        try? await Task.sleep(for: .milliseconds(650))

        messages = [
            makeMessage(
                text: "Local travel assistant started. This POC shows how your own API can return structured content and your app can render reusable SwiftUI components inline.",
                senderName: "System",
                direction: .system
            ),
            makeMessage(
                text: "Hi \(configuration.customerName.isEmpty ? "there" : configuration.customerName). Ask for hotels, weekend stays, or beach resorts and I can render the matching travel component right inside the chat.",
                senderName: "Maya",
                direction: .incoming,
                actionChips: [
                    ChatActionChip(id: "chip-hotels", title: "Hotels in Miami", prompt: "Show hotels in Miami"),
                    ChatActionChip(id: "chip-nyc", title: "Weekend in New York", prompt: "Weekend stay in New York"),
                    ChatActionChip(id: "chip-resorts", title: "Beach resorts", prompt: "Any beach resorts?")
                ]
            ),
            makeMessage(
                text: "The floating bubble and inline panel both use this same in-house chat engine. Swap the sample hotel carousel for your office app's SwiftUI view later.",
                senderName: "Maya",
                direction: .incoming
            )
        ]
        connectionState = .connected
        bannerText = "Travel assistant connected."
    }

    private func sendMessage(_ text: String) async {
        messages.append(
            makeMessage(
                text: text,
                senderName: "You",
                direction: .outgoing,
                statusText: "Sent"
            )
        )
        bannerText = "Maya is searching..."

        try? await Task.sleep(for: .milliseconds(850))

        let response = TravelAssistantDemoAPI.search(for: text)
        messages.append(contentsOf: makeMessages(from: response))
        bannerText = "Travel assistant connected."
    }

    private func endSession() async {
        guard connectionState == .connected || connectionState == .ended else { return }

        messages.append(
            makeMessage(
                text: "Travel assistant chat ended.",
                senderName: "System",
                direction: .system
            )
        )
        connectionState = .ended
        bannerText = "Travel assistant ended."
    }

    private func makeMessage(
        text: String,
        senderName: String,
        direction: ChatMessageDirection,
        statusText: String? = nil,
        actionChips: [ChatActionChip] = []
    ) -> ChatMessageItem {
        messageIndex += 1
        return ChatMessageItem(
            id: "mock-\(messageIndex)",
            text: text,
            senderName: senderName,
            timeStamp: Date.chatTimeString(),
            direction: direction,
            statusText: statusText,
            actionChips: actionChips
        )
    }

    private func makeEmbeddedComponentMessage(_ component: InHouseChatAPIComponentBlock) -> ChatMessageItem {
        messageIndex += 1
        return ChatMessageItem(
            id: "mock-\(messageIndex)",
            content: .embeddedComponent(
                ChatEmbeddedComponent(
                    id: "component-\(messageIndex)",
                    componentKey: component.componentKey,
                    title: component.title,
                    subtitle: component.subtitle,
                    payload: component.payload
                )
            ),
            senderName: "Maya",
            timeStamp: Date.chatTimeString(),
            direction: .incoming
        )
    }

    // This mapper is the seam where a real in-house API response would become chat transcript items.
    private func makeMessages(from response: InHouseChatAPIResponse) -> [ChatMessageItem] {
        response.blocks.map { block in
            switch block {
            case .text(let textBlock):
                return makeMessage(
                    text: textBlock.body,
                    senderName: "Maya",
                    direction: .incoming,
                    actionChips: textBlock.actions
                )
            case .component(let componentBlock):
                return makeEmbeddedComponentMessage(componentBlock)
            }
        }
    }
}

private struct InHouseChatAPIResponse {
    let blocks: [InHouseChatAPIBlock]
}

private enum InHouseChatAPIBlock {
    case text(InHouseChatAPITextBlock)
    case component(InHouseChatAPIComponentBlock)
}

private struct InHouseChatAPITextBlock {
    let body: String
    let actions: [ChatActionChip]
}

private struct InHouseChatAPIComponentBlock {
    let componentKey: String
    let title: String
    let subtitle: String?
    let payload: [String: String]
}

private enum TravelAssistantDemoAPI {
    static func search(for query: String) -> InHouseChatAPIResponse {
        let normalized = query.lowercased()

        if normalized.contains("hotel") || normalized.contains("stay") || normalized.contains("resort") {
            let hotels = sampleHotels(for: normalized)
            return InHouseChatAPIResponse(
                blocks: [
                    .text(
                        InHouseChatAPITextBlock(
                            body: "I found a few stays that match your request. In a real app, this payload would come from your internal API, then the chat would render your existing SwiftUI carousel view.",
                            actions: []
                        )
                    ),
                    .component(
                        InHouseChatAPIComponentBlock(
                            componentKey: "hotel-carousel",
                            title: "Recommended hotels",
                            subtitle: "Example of injecting your app's reusable SwiftUI component into chat",
                            payload: ChatComponentPayloadCoder.encode(hotels)
                        )
                    )
                ]
            )
        }

        return InHouseChatAPIResponse(
            blocks: [
                .text(
                    InHouseChatAPITextBlock(
                        body: "I can route to reusable UI components when your backend returns structured content. Try asking for hotels, a weekend stay, or beach resorts.",
                        actions: [
                            ChatActionChip(id: "suggest-hotels", title: "Hotels", prompt: "Show hotels in Miami"),
                            ChatActionChip(id: "suggest-weekend", title: "Weekend stay", prompt: "Weekend stay in New York"),
                            ChatActionChip(id: "suggest-resorts", title: "Beach resorts", prompt: "Any beach resorts?")
                        ]
                    )
                )
            ]
        )
    }

    private static func sampleHotels(for query: String) -> [HotelCardItem] {
        if query.contains("new york") {
            return [
                HotelCardItem(id: "hotel-nyc-1", name: "The Bryant Loft", location: "Midtown, New York", nightlyPrice: "$289 / night", ratingText: "4.8 - Boutique stay", badgeText: "Popular", summary: "Walkable to Broadway with a rooftop lounge and flexible late checkout."),
                HotelCardItem(id: "hotel-nyc-2", name: "Hudson Corner Hotel", location: "Chelsea, New York", nightlyPrice: "$245 / night", ratingText: "4.6 - Great for weekends", badgeText: "Weekend", summary: "Stylish rooms near galleries, High Line access, and quick subway connections."),
                HotelCardItem(id: "hotel-nyc-3", name: "Park South Residence", location: "Flatiron, New York", nightlyPrice: "$312 / night", ratingText: "4.9 - Premium pick", badgeText: "Premium", summary: "Spacious suites with skyline views and breakfast included for two.")
            ]
        }

        if query.contains("beach") || query.contains("resort") {
            return [
                HotelCardItem(id: "hotel-beach-1", name: "Azure Dunes Resort", location: "South Beach, Miami", nightlyPrice: "$354 / night", ratingText: "4.8 - Oceanfront", badgeText: "Resort", summary: "Beachfront resort with cabanas, family pool, and spa access."),
                HotelCardItem(id: "hotel-beach-2", name: "Coral Bay Retreat", location: "Key Biscayne", nightlyPrice: "$298 / night", ratingText: "4.7 - Relaxed vibe", badgeText: "Beach", summary: "Quiet coastal stay with bike rentals and sunset dining."),
                HotelCardItem(id: "hotel-beach-3", name: "Palm Grove Suites", location: "Fort Lauderdale", nightlyPrice: "$265 / night", ratingText: "4.5 - Value pick", badgeText: "Value", summary: "Suite-style rooms close to the boardwalk and marina.")
            ]
        }

        return [
            HotelCardItem(id: "hotel-miami-1", name: "Soleil Brickell", location: "Brickell, Miami", nightlyPrice: "$229 / night", ratingText: "4.7 - Downtown favorite", badgeText: "Top Pick", summary: "Modern high-rise stay with skyline pool and walkable dining."),
            HotelCardItem(id: "hotel-miami-2", name: "Casa Verde Miami", location: "Wynwood, Miami", nightlyPrice: "$189 / night", ratingText: "4.5 - Design hotel", badgeText: "Design", summary: "Art-forward boutique hotel close to galleries, cafes, and nightlife."),
            HotelCardItem(id: "hotel-miami-3", name: "Marina Blue Suites", location: "Biscayne Bay, Miami", nightlyPrice: "$259 / night", ratingText: "4.8 - Bay view", badgeText: "Scenic", summary: "Large suites with bay views, gym access, and easy rides to the beach.")
        ]
    }
}

private extension Date {
    static func chatTimeString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter.string(from: Date())
    }
}
