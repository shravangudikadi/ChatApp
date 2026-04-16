import SwiftUI

struct ConnectionFormView: View {
    @EnvironmentObject private var settingsStore: ChatSettingsStore
    @EnvironmentObject private var chatService: InHouseChatService
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("In-House POC Controls")
                .font(.title2.weight(.bold))

            Text("Run a fully local in-house chat shell that can render your reusable SwiftUI views directly inside the conversation. The floating bubble and panel stay the same no matter which app component you inject.")
                .foregroundStyle(.secondary)

            ChatStatusCard(
                title: "Experience",
                description: settingsStore.experienceDescription,
                accent: Color(red: 0.02, green: 0.66, blue: 0.62)
            )

            TextField("Customer Name", text: $settingsStore.customerName)
                .textFieldStyle(.roundedBorder)

            TextField("Customer ID", text: $settingsStore.customerId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("Order ID", text: $settingsStore.orderId)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("Membership Tier", text: $settingsStore.membershipTier)
                .textFieldStyle(.roundedBorder)

            TextField("Locale", text: $settingsStore.locale)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            TextField("Issue Type", text: $settingsStore.issueType)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .textFieldStyle(.roundedBorder)

            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "rectangle.on.rectangle.angled")
                    .foregroundStyle(Color(red: 0.02, green: 0.66, blue: 0.62))

                Text("Your internal API can return structured payloads and the chat can render your existing SwiftUI components inside the transcript. Today the sample uses a hotel carousel, but the same pattern works for flights, destinations, itineraries, or booking cards.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(Color(red: 0.95, green: 0.99, blue: 0.97))
            )

            Button {
                chatService.startSession(using: settingsStore.currentConfiguration)
                overlayManager.hide()
            } label: {
                Label(settingsStore.startButtonTitle, systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.02, green: 0.66, blue: 0.62))

            Button {
                overlayManager.expand()
            } label: {
                Label("Open Chat Panel", systemImage: "rectangle.portrait.on.rectangle.portrait")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                overlayManager.showBubble()
            } label: {
                Label("Show Floating Bubble", systemImage: "message.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                chatService.resetDemo()
            } label: {
                Label("Reset Session", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background.opacity(0.92))
                .shadow(color: .black.opacity(0.08), radius: 18, y: 12)
        )
        .onAppear {
            chatService.resetDemo(using: settingsStore.currentConfiguration)
        }
    }
}

struct ChatStatusCard: View {
    let title: String
    let description: String
    let accent: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                Circle()
                    .fill(accent)
                    .frame(width: 12, height: 12)

                Text(title)
                    .font(.headline)
            }

            Text(description)
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 12, y: 8)
        )
    }
}
