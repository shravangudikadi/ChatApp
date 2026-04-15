import Foundation
import AWSCore

enum ChatProviderMode: String, CaseIterable, Identifiable {
    case mock
    case amazonConnect

    var id: String { rawValue }

    var title: String {
        switch self {
        case .mock:
            return "Mock"
        case .amazonConnect:
            return "Amazon Connect"
        }
    }

    var description: String {
        switch self {
        case .mock:
            return "Runs fully locally with realistic support scenarios, transcript behavior, and UI state changes."
        case .amazonConnect:
            return "Uses the real Amazon Connect iOS SDK path. The only missing dependency is a bootstrap service that returns participant chat details."
        }
    }

    var startButtonTitle: String {
        switch self {
        case .mock:
            return "Start Mock Chat"
        case .amazonConnect:
            return "Connect Real SDK"
        }
    }
}

enum AWSRegionOption: String, CaseIterable, Identifiable {
    case usEast1 = "us-east-1"
    case usEast2 = "us-east-2"
    case usWest2 = "us-west-2"
    case caCentral1 = "ca-central-1"
    case euWest1 = "eu-west-1"
    case euCentral1 = "eu-central-1"
    case euWest2 = "eu-west-2"
    case euWest3 = "eu-west-3"
    case euNorth1 = "eu-north-1"
    case apSouth1 = "ap-south-1"
    case apSoutheast1 = "ap-southeast-1"
    case apSoutheast2 = "ap-southeast-2"
    case apNortheast1 = "ap-northeast-1"
    case apNortheast2 = "ap-northeast-2"

    var id: String { rawValue }

    var displayName: String { rawValue }

    var awsRegionType: AWSRegionType {
        switch self {
        case .usEast1:
            return .USEast1
        case .usEast2:
            return .USEast2
        case .usWest2:
            return .USWest2
        case .caCentral1:
            return .CACentral1
        case .euWest1:
            return .EUWest1
        case .euCentral1:
            return .EUCentral1
        case .euWest2:
            return .EUWest2
        case .euWest3:
            return .EUWest3
        case .euNorth1:
            return .EUNorth1
        case .apSouth1:
            return .APSouth1
        case .apSoutheast1:
            return .APSoutheast1
        case .apSoutheast2:
            return .APSoutheast2
        case .apNortheast1:
            return .APNortheast1
        case .apNortheast2:
            return .APNortheast2
        }
    }
}

struct ChatProviderConfiguration {
    let providerMode: ChatProviderMode
    let region: AWSRegionOption
    let customerName: String
    let customerId: String
    let orderId: String
    let membershipTier: String
    let locale: String
    let issueType: String
    let bootstrapEndpoint: String
    let instanceId: String
    let contactFlowId: String

    var bootstrapRequest: ChatBootstrapRequest {
        ChatBootstrapRequest(
            customerName: customerName,
            customerId: customerId,
            orderId: orderId,
            membershipTier: membershipTier,
            locale: locale,
            issueType: issueType,
            region: region.rawValue,
            instanceId: instanceId,
            contactFlowId: contactFlowId
        )
    }

    static let previewMock = ChatProviderConfiguration(
        providerMode: .mock,
        region: .usEast1,
        customerName: "Taylor",
        customerId: "CUST-1024",
        orderId: "ORD-9981",
        membershipTier: "Gold",
        locale: "en-US",
        issueType: "delivery_status",
        bootstrapEndpoint: "",
        instanceId: "",
        contactFlowId: ""
    )

    static let previewAmazonConnect = ChatProviderConfiguration(
        providerMode: .amazonConnect,
        region: .usEast1,
        customerName: "Taylor",
        customerId: "CUST-1024",
        orderId: "ORD-9981",
        membershipTier: "Gold",
        locale: "en-US",
        issueType: "delivery_status",
        bootstrapEndpoint: "https://your-api.example.com/chat/start",
        instanceId: "connect-instance-id",
        contactFlowId: "contact-flow-id"
    )
}

@MainActor
final class ChatSettingsStore: ObservableObject {
    @Published var providerMode: ChatProviderMode { didSet { persist() } }
    @Published var region: AWSRegionOption { didSet { persist() } }
    @Published var customerName: String { didSet { persist() } }
    @Published var customerId: String { didSet { persist() } }
    @Published var orderId: String { didSet { persist() } }
    @Published var membershipTier: String { didSet { persist() } }
    @Published var locale: String { didSet { persist() } }
    @Published var issueType: String { didSet { persist() } }
    @Published var bootstrapEndpoint: String { didSet { persist() } }
    @Published var instanceId: String { didSet { persist() } }
    @Published var contactFlowId: String { didSet { persist() } }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        providerMode = ChatProviderMode(rawValue: userDefaults.string(forKey: Keys.providerMode) ?? "") ?? .mock
        region = AWSRegionOption(rawValue: userDefaults.string(forKey: Keys.region) ?? "") ?? .usEast1
        customerName = userDefaults.string(forKey: Keys.customerName) ?? "Taylor"
        customerId = userDefaults.string(forKey: Keys.customerId) ?? "CUST-1024"
        orderId = userDefaults.string(forKey: Keys.orderId) ?? "ORD-9981"
        membershipTier = userDefaults.string(forKey: Keys.membershipTier) ?? "Gold"
        locale = userDefaults.string(forKey: Keys.locale) ?? "en-US"
        issueType = userDefaults.string(forKey: Keys.issueType) ?? "delivery_status"
        bootstrapEndpoint = userDefaults.string(forKey: Keys.bootstrapEndpoint) ?? "https://your-api.example.com/chat/start"
        instanceId = userDefaults.string(forKey: Keys.instanceId) ?? "connect-instance-id"
        contactFlowId = userDefaults.string(forKey: Keys.contactFlowId) ?? "contact-flow-id"
    }

    var currentConfiguration: ChatProviderConfiguration {
        ChatProviderConfiguration(
            providerMode: providerMode,
            region: region,
            customerName: customerName.trimmed,
            customerId: customerId.trimmed,
            orderId: orderId.trimmed,
            membershipTier: membershipTier.trimmed,
            locale: locale.trimmed,
            issueType: issueType.trimmed,
            bootstrapEndpoint: bootstrapEndpoint.trimmed,
            instanceId: instanceId.trimmed,
            contactFlowId: contactFlowId.trimmed
        )
    }

    private func persist() {
        userDefaults.set(providerMode.rawValue, forKey: Keys.providerMode)
        userDefaults.set(region.rawValue, forKey: Keys.region)
        userDefaults.set(customerName, forKey: Keys.customerName)
        userDefaults.set(customerId, forKey: Keys.customerId)
        userDefaults.set(orderId, forKey: Keys.orderId)
        userDefaults.set(membershipTier, forKey: Keys.membershipTier)
        userDefaults.set(locale, forKey: Keys.locale)
        userDefaults.set(issueType, forKey: Keys.issueType)
        userDefaults.set(bootstrapEndpoint, forKey: Keys.bootstrapEndpoint)
        userDefaults.set(instanceId, forKey: Keys.instanceId)
        userDefaults.set(contactFlowId, forKey: Keys.contactFlowId)
    }
}

private enum Keys {
    static let providerMode = "chat.providerMode"
    static let region = "chat.region"
    static let customerName = "chat.customerName"
    static let customerId = "chat.customerId"
    static let orderId = "chat.orderId"
    static let membershipTier = "chat.membershipTier"
    static let locale = "chat.locale"
    static let issueType = "chat.issueType"
    static let bootstrapEndpoint = "chat.bootstrapEndpoint"
    static let instanceId = "chat.instanceId"
    static let contactFlowId = "chat.contactFlowId"
}

private extension String {
    var trimmed: String {
        trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
