import Foundation

struct ChatExperienceConfiguration {
    let customerName: String
    let customerId: String
    let orderId: String
    let membershipTier: String
    let locale: String
    let issueType: String

    static let preview = ChatExperienceConfiguration(
        customerName: "Taylor",
        customerId: "CUST-1024",
        orderId: "ORD-9981",
        membershipTier: "Gold",
        locale: "en-US",
        issueType: "travel_search"
    )
}

@MainActor
final class ChatSettingsStore: ObservableObject {
    @Published var customerName: String { didSet { persist() } }
    @Published var customerId: String { didSet { persist() } }
    @Published var orderId: String { didSet { persist() } }
    @Published var membershipTier: String { didSet { persist() } }
    @Published var locale: String { didSet { persist() } }
    @Published var issueType: String { didSet { persist() } }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        customerName = userDefaults.string(forKey: Keys.customerName) ?? "Taylor"
        customerId = userDefaults.string(forKey: Keys.customerId) ?? "CUST-1024"
        orderId = userDefaults.string(forKey: Keys.orderId) ?? "ORD-9981"
        membershipTier = userDefaults.string(forKey: Keys.membershipTier) ?? "Gold"
        locale = userDefaults.string(forKey: Keys.locale) ?? "en-US"
        issueType = userDefaults.string(forKey: Keys.issueType) ?? "travel_search"
    }

    var currentConfiguration: ChatExperienceConfiguration {
        ChatExperienceConfiguration(
            customerName: customerName.trimmed,
            customerId: customerId.trimmed,
            orderId: orderId.trimmed,
            membershipTier: membershipTier.trimmed,
            locale: locale.trimmed,
            issueType: issueType.trimmed
        )
    }

    var experienceDescription: String {
        "Runs locally as an in-house chat shell that can render reusable SwiftUI components, such as your hotel or flight carousels, directly inside the transcript."
    }

    var startButtonTitle: String {
        "Start In-House Chat"
    }

    private func persist() {
        userDefaults.set(customerName, forKey: Keys.customerName)
        userDefaults.set(customerId, forKey: Keys.customerId)
        userDefaults.set(orderId, forKey: Keys.orderId)
        userDefaults.set(membershipTier, forKey: Keys.membershipTier)
        userDefaults.set(locale, forKey: Keys.locale)
        userDefaults.set(issueType, forKey: Keys.issueType)
    }
}

private enum Keys {
    static let customerName = "chat.customerName"
    static let customerId = "chat.customerId"
    static let orderId = "chat.orderId"
    static let membershipTier = "chat.membershipTier"
    static let locale = "chat.locale"
    static let issueType = "chat.issueType"
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
