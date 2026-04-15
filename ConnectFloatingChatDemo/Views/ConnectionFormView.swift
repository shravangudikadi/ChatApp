import SwiftUI

struct ConnectionFormView: View {
    @EnvironmentObject private var chatService: AmazonConnectChatService
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Mock POC Controls")
                .font(.title2.weight(.bold))

            Text("This build is intentionally backend-free. It keeps the Amazon Connect binaries in the project, but the transcript is driven by local mock messages so you can review the floating widget behavior quickly.")
                .foregroundStyle(.secondary)

            ChatStatusCard(
                title: "Current Mode",
                description: "Mock transcript only. No `StartChatContact`, no participant token, and no endpoint configuration required.",
                accent: Color(red: 0.02, green: 0.66, blue: 0.62)
            )

            Button {
                chatService.startMockChat()
                overlayManager.expand()
            } label: {
                Label("Start Mock Chat", systemImage: "play.circle.fill")
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
                Label("Reset Transcript", systemImage: "arrow.counterclockwise")
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
