import Foundation
import AWSCore

enum ConnectionMode: String, CaseIterable, Identifiable {
    case startChatEndpoint
    case directParticipantToken

    var id: String { rawValue }

    var title: String {
        switch self {
        case .startChatEndpoint:
            return "Start Chat Endpoint"
        case .directParticipantToken:
            return "Participant Token"
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

struct ChatConnectionConfiguration {
    let connectionMode: ConnectionMode
    let region: AWSRegionOption
    let startChatEndpoint: String
    let instanceId: String
    let contactFlowId: String
    let customerName: String
    let participantToken: String
    let participantId: String
    let contactId: String
}

@MainActor
final class ChatSettingsStore: ObservableObject {
    @Published var connectionMode: ConnectionMode { didSet { persist() } }
    @Published var region: AWSRegionOption { didSet { persist() } }
    @Published var startChatEndpoint: String { didSet { persist() } }
    @Published var instanceId: String { didSet { persist() } }
    @Published var contactFlowId: String { didSet { persist() } }
    @Published var customerName: String { didSet { persist() } }
    @Published var participantToken: String { didSet { persist() } }
    @Published var participantId: String { didSet { persist() } }
    @Published var contactId: String { didSet { persist() } }

    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        connectionMode = ConnectionMode(rawValue: userDefaults.string(forKey: Keys.connectionMode) ?? "") ?? .startChatEndpoint
        region = AWSRegionOption(rawValue: userDefaults.string(forKey: Keys.region) ?? "") ?? .usEast1
        startChatEndpoint = userDefaults.string(forKey: Keys.startChatEndpoint) ?? ""
        instanceId = userDefaults.string(forKey: Keys.instanceId) ?? ""
        contactFlowId = userDefaults.string(forKey: Keys.contactFlowId) ?? ""
        customerName = userDefaults.string(forKey: Keys.customerName) ?? "Taylor"
        participantToken = userDefaults.string(forKey: Keys.participantToken) ?? ""
        participantId = userDefaults.string(forKey: Keys.participantId) ?? ""
        contactId = userDefaults.string(forKey: Keys.contactId) ?? ""

        bootstrapFromBundledConfigIfNeeded()
    }

    var currentConfiguration: ChatConnectionConfiguration {
        ChatConnectionConfiguration(
            connectionMode: connectionMode,
            region: region,
            startChatEndpoint: startChatEndpoint.trimmingCharacters(in: .whitespacesAndNewlines),
            instanceId: instanceId.trimmingCharacters(in: .whitespacesAndNewlines),
            contactFlowId: contactFlowId.trimmingCharacters(in: .whitespacesAndNewlines),
            customerName: customerName.trimmingCharacters(in: .whitespacesAndNewlines),
            participantToken: participantToken.trimmingCharacters(in: .whitespacesAndNewlines),
            participantId: participantId.trimmingCharacters(in: .whitespacesAndNewlines),
            contactId: contactId.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    private func persist() {
        userDefaults.set(connectionMode.rawValue, forKey: Keys.connectionMode)
        userDefaults.set(region.rawValue, forKey: Keys.region)
        userDefaults.set(startChatEndpoint, forKey: Keys.startChatEndpoint)
        userDefaults.set(instanceId, forKey: Keys.instanceId)
        userDefaults.set(contactFlowId, forKey: Keys.contactFlowId)
        userDefaults.set(customerName, forKey: Keys.customerName)
        userDefaults.set(participantToken, forKey: Keys.participantToken)
        userDefaults.set(participantId, forKey: Keys.participantId)
        userDefaults.set(contactId, forKey: Keys.contactId)
    }

    func loadBundledConfig() {
        guard let configuration = BundledPOCConfiguration.load() else {
            return
        }

        connectionMode = configuration.connectionMode
        region = configuration.region
        startChatEndpoint = configuration.startChatEndpoint
        instanceId = configuration.instanceId
        contactFlowId = configuration.contactFlowId
        customerName = configuration.customerName
        participantToken = configuration.participantToken
        participantId = configuration.participantId
        contactId = configuration.contactId
    }

    private func bootstrapFromBundledConfigIfNeeded() {
        let hasSavedValues =
            !startChatEndpoint.isEmpty ||
            !instanceId.isEmpty ||
            !contactFlowId.isEmpty ||
            !participantToken.isEmpty ||
            !participantId.isEmpty ||
            !contactId.isEmpty

        guard !hasSavedValues else {
            return
        }

        loadBundledConfig()
    }
}

private enum Keys {
    static let connectionMode = "chat.connectionMode"
    static let region = "chat.region"
    static let startChatEndpoint = "chat.startChatEndpoint"
    static let instanceId = "chat.instanceId"
    static let contactFlowId = "chat.contactFlowId"
    static let customerName = "chat.customerName"
    static let participantToken = "chat.participantToken"
    static let participantId = "chat.participantId"
    static let contactId = "chat.contactId"
}

private struct BundledPOCConfiguration {
    let connectionMode: ConnectionMode
    let region: AWSRegionOption
    let startChatEndpoint: String
    let instanceId: String
    let contactFlowId: String
    let customerName: String
    let participantToken: String
    let participantId: String
    let contactId: String

    static func load(bundle: Bundle = .main) -> BundledPOCConfiguration? {
        guard
            let url = bundle.url(forResource: "ConnectPOCConfig", withExtension: "plist"),
            let data = try? Data(contentsOf: url),
            let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
        else {
            return nil
        }

        let modeRawValue = plist["connectionMode"] as? String ?? ConnectionMode.startChatEndpoint.rawValue
        let regionRawValue = plist["region"] as? String ?? AWSRegionOption.usEast1.rawValue

        return BundledPOCConfiguration(
            connectionMode: ConnectionMode(rawValue: modeRawValue) ?? .startChatEndpoint,
            region: AWSRegionOption(rawValue: regionRawValue) ?? .usEast1,
            startChatEndpoint: plist["startChatEndpoint"] as? String ?? "",
            instanceId: plist["instanceId"] as? String ?? "",
            contactFlowId: plist["contactFlowId"] as? String ?? "",
            customerName: plist["customerName"] as? String ?? "Taylor",
            participantToken: plist["participantToken"] as? String ?? "",
            participantId: plist["participantId"] as? String ?? "",
            contactId: plist["contactId"] as? String ?? ""
        )
    }
}
