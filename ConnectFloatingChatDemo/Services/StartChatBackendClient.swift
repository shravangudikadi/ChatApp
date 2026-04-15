import Foundation

struct ChatBootstrapRequest: Encodable {
    let customerName: String
    let customerId: String
    let orderId: String
    let membershipTier: String
    let locale: String
    let issueType: String
    let region: String
    let instanceId: String
    let contactFlowId: String
}

struct ChatBootstrapResponse {
    let participantToken: String
    let participantId: String?
    let contactId: String?
}

protocol ChatSessionBootstrapProviding {
    func fetchBootstrap(using configuration: ChatProviderConfiguration) async throws -> ChatBootstrapResponse
}

enum ChatBootstrapError: LocalizedError {
    case localPocOnly
    case invalidEndpoint
    case invalidResponse
    case missingCredentials
    case missingConfiguration(String)

    var errorDescription: String? {
        switch self {
        case .localPocOnly:
            return "The real Amazon Connect SDK path is already wired, but this build is still using a placeholder bootstrap provider. Replace `ChatSessionBootstrapProviding` with your backend call to StartChatContact."
        case .invalidEndpoint:
            return "The bootstrap endpoint is invalid. Enter a real service URL that starts the chat and returns participant details."
        case .invalidResponse:
            return "The bootstrap service returned an unexpected response shape."
        case .missingCredentials:
            return "The bootstrap response did not include a valid participant token."
        case .missingConfiguration(let field):
            return "Missing required configuration: \(field)."
        }
    }
}

final class PlaceholderBootstrapProvider: ChatSessionBootstrapProviding {
    func fetchBootstrap(using configuration: ChatProviderConfiguration) async throws -> ChatBootstrapResponse {
        throw ChatBootstrapError.localPocOnly
    }
}

final class NetworkChatSessionBootstrapProvider: ChatSessionBootstrapProviding {
    func fetchBootstrap(using configuration: ChatProviderConfiguration) async throws -> ChatBootstrapResponse {
        guard !configuration.bootstrapEndpoint.isEmpty else {
            throw ChatBootstrapError.missingConfiguration("Bootstrap Endpoint")
        }

        guard !configuration.instanceId.isEmpty else {
            throw ChatBootstrapError.missingConfiguration("Connect Instance ID")
        }

        guard !configuration.contactFlowId.isEmpty else {
            throw ChatBootstrapError.missingConfiguration("Contact Flow ID")
        }

        guard let url = URL(string: configuration.bootstrapEndpoint) else {
            throw ChatBootstrapError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(configuration.bootstrapRequest)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw ChatBootstrapError.invalidResponse
        }

        guard let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw ChatBootstrapError.invalidResponse
        }

        let participantToken = Self.findString(key: "participantToken", in: jsonObject)
            ?? Self.findString(key: "ParticipantToken", in: jsonObject)
        let participantId = Self.findString(key: "participantId", in: jsonObject)
            ?? Self.findString(key: "ParticipantId", in: jsonObject)
        let contactId = Self.findString(key: "contactId", in: jsonObject)
            ?? Self.findString(key: "ContactId", in: jsonObject)

        guard let participantToken, !participantToken.isEmpty else {
            throw ChatBootstrapError.missingCredentials
        }

        return ChatBootstrapResponse(
            participantToken: participantToken,
            participantId: participantId,
            contactId: contactId
        )
    }

    private static func findString(key: String, in value: Any) -> String? {
        if let dictionary = value as? [String: Any] {
            if let match = dictionary.first(where: { $0.key.caseInsensitiveCompare(key) == .orderedSame }),
               let stringValue = match.value as? String,
               !stringValue.isEmpty {
                return stringValue
            }

            for nestedValue in dictionary.values {
                if let result = findString(key: key, in: nestedValue) {
                    return result
                }
            }
        }

        if let array = value as? [Any] {
            for nestedValue in array {
                if let result = findString(key: key, in: nestedValue) {
                    return result
                }
            }
        }

        return nil
    }
}
