import Foundation

struct ChatStartupCredentials {
    let participantToken: String
    let participantId: String?
    let contactId: String?
}

enum StartChatBackendError: LocalizedError {
    case invalidEndpoint
    case invalidResponse
    case missingCredentials

    var errorDescription: String? {
        switch self {
        case .invalidEndpoint:
            return "The Start Chat endpoint URL is invalid."
        case .invalidResponse:
            return "The Start Chat endpoint returned data in an unexpected format."
        case .missingCredentials:
            return "The response did not contain participantToken, participantId, and contactId fields."
        }
    }
}

final class StartChatBackendClient {
    func startChat(using configuration: ChatConnectionConfiguration) async throws -> ChatStartupCredentials {
        guard let url = URL(string: configuration.startChatEndpoint), !configuration.startChatEndpoint.isEmpty else {
            throw StartChatBackendError.invalidEndpoint
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            StartChatRequest(
                connectInstanceId: configuration.instanceId,
                contactFlowId: configuration.contactFlowId,
                participantDetails: .init(DisplayName: configuration.customerName),
                attributes: ["customerName": configuration.customerName]
            )
        )

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse, (200 ... 299).contains(httpResponse.statusCode) else {
            throw StartChatBackendError.invalidResponse
        }

        guard
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            throw StartChatBackendError.invalidResponse
        }

        let participantToken = Self.findString(key: "participantToken", in: jsonObject)
            ?? Self.findString(key: "ParticipantToken", in: jsonObject)
        let participantId = Self.findString(key: "participantId", in: jsonObject)
            ?? Self.findString(key: "ParticipantId", in: jsonObject)
        let contactId = Self.findString(key: "contactId", in: jsonObject)
            ?? Self.findString(key: "ContactId", in: jsonObject)

        guard let participantToken, !participantToken.isEmpty else {
            throw StartChatBackendError.missingCredentials
        }

        return ChatStartupCredentials(
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

private struct StartChatRequest: Encodable {
    let connectInstanceId: String
    let contactFlowId: String
    let participantDetails: ParticipantDetails
    let attributes: [String: String]
}

private struct ParticipantDetails: Encodable {
    let DisplayName: String
}
