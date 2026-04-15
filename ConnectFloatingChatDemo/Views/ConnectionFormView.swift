import SwiftUI

struct ConnectionFormView: View {
    @EnvironmentObject private var settingsStore: ChatSettingsStore
    @EnvironmentObject private var chatService: AmazonConnectChatService
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Provider-Ready POC Controls")
                .font(.title2.weight(.bold))

            Text("Run a fully local mock today, or switch to the real Amazon Connect SDK provider. Later, you only need to replace the bootstrap provider that returns participant chat details.")
                .foregroundStyle(.secondary)

            Picker("Provider", selection: $settingsStore.providerMode) {
                ForEach(ChatProviderMode.allCases) { mode in
                    Text(mode.title).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            ChatStatusCard(
                title: "Selected Provider",
                description: settingsStore.providerMode.description,
                accent: settingsStore.providerMode == .mock ? Color(red: 0.02, green: 0.66, blue: 0.62) : Color(red: 0.11, green: 0.46, blue: 0.95)
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

            if settingsStore.providerMode == .amazonConnect {
                Picker("AWS Region", selection: $settingsStore.region) {
                    ForEach(AWSRegionOption.allCases) { region in
                        Text(region.displayName).tag(region)
                    }
                }
                .pickerStyle(.menu)

                TextField("Bootstrap Endpoint URL", text: $settingsStore.bootstrapEndpoint)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)
                    .textFieldStyle(.roundedBorder)

                TextField("Connect Instance ID", text: $settingsStore.instanceId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                TextField("Contact Flow ID", text: $settingsStore.contactFlowId)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "bolt.horizontal.circle")
                        .foregroundStyle(Color(red: 0.11, green: 0.46, blue: 0.95))

                    Text("The real provider already calls the Amazon Connect iOS SDK. When your backend is ready, replace the bootstrap provider so it returns `participantToken`, `participantId`, and `contactId` from `StartChatContact`.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(Color(red: 0.95, green: 0.97, blue: 1.0))
                )
            }

            Button {
                chatService.startSession(using: settingsStore.currentConfiguration)
                if settingsStore.providerMode == .amazonConnect {
                    overlayManager.expand()
                } else {
                    overlayManager.hide()
                }
            } label: {
                Label(
                    settingsStore.providerMode.startButtonTitle,
                    systemImage: settingsStore.providerMode == .mock ? "play.circle.fill" : "antenna.radiowaves.left.and.right"
                )
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(settingsStore.providerMode == .mock ? Color(red: 0.02, green: 0.66, blue: 0.62) : Color(red: 0.11, green: 0.46, blue: 0.95))

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
        .onChange(of: settingsStore.providerMode) { _ in
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
