import SwiftUI

struct ChatPanelView: View {
    @EnvironmentObject private var chatService: AmazonConnectChatService
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    let isOverlayPresentation: Bool

    var body: some View {
        VStack(spacing: 0) {
            header

            if let errorText = chatService.errorText {
                Text(errorText)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.red.opacity(0.08))
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if chatService.messages.isEmpty {
                            emptyState
                        } else {
                            ForEach(chatService.messages) { item in
                                MessageBubbleRow(item: item)
                                    .id(item.id)
                            }
                        }
                    }
                    .padding(16)
                }
                .background(Color(red: 0.97, green: 0.98, blue: 1.0))
                .onChange(of: chatService.messages.count) { _ in
                    if let lastID = chatService.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastID, anchor: .bottom)
                        }
                    }
                }
            }

            composer
        }
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
                .stroke(Color.white.opacity(0.65), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.16), radius: 24, y: 14)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(chatService.sessionTitle)
                        .font(.headline.weight(.bold))

                    Text(chatService.bannerText)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if isOverlayPresentation {
                    Button {
                        overlayManager.minimize()
                    } label: {
                        Image(systemName: "minus")
                            .padding(8)
                    }
                    .buttonStyle(.borderless)

                    Button {
                        overlayManager.hide()
                    } label: {
                        Image(systemName: "xmark")
                            .padding(8)
                    }
                    .buttonStyle(.borderless)
                }
            }

            mockModeCard
        }
        .padding(16)
        .background(.thinMaterial)
    }

    private var mockModeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "testtube.2")
                .foregroundStyle(Color(red: 0.02, green: 0.66, blue: 0.62))

            Text("Mock transcript only. The Amazon Connect SDK is linked into the project, but this screen uses local fake messages so you can review the UI without any backend.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.95, green: 0.99, blue: 0.97))
        )
    }

    private var composer: some View {
        VStack(spacing: 12) {
            Divider()

            HStack(spacing: 12) {
                TextField("Type a message", text: $chatService.draftMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .disabled(!chatService.isConnected)

                if chatService.isConnected {
                    Button {
                        chatService.sendDraftMessage()
                    } label: {
                        Image(systemName: "paperplane.fill")
                            .frame(width: 40, height: 40)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.11, green: 0.46, blue: 0.95))
                } else {
                    Button {
                        chatService.startMockChat()
                    } label: {
                        if chatService.connectionState == .connecting {
                            ProgressView()
                                .frame(width: 40, height: 40)
                        } else {
                            Image(systemName: "bolt.horizontal.circle.fill")
                                .frame(width: 40, height: 40)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.02, green: 0.66, blue: 0.62))
                }
            }

            if chatService.isConnected {
                Button("Disconnect") {
                    chatService.disconnect()
                }
                .font(.footnote.weight(.semibold))
            } else {
                Button("Reset Demo") {
                    chatService.resetDemo()
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(16)
        .background(.background)
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No messages yet")
                .font(.headline)

            Text("Start the mock session and the floating chat will fill with sample support messages immediately.")
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }
}

private struct MessageBubbleRow: View {
    let item: ChatMessageItem

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(item.senderName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Text(item.text)
                .frame(maxWidth: .infinity, alignment: textAlignment)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(bubbleColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            if let statusText = item.statusText {
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: rowAlignment)
    }

    private var alignment: HorizontalAlignment {
        switch item.direction {
        case .incoming:
            return .leading
        case .outgoing:
            return .trailing
        case .system:
            return .leading
        }
    }

    private var rowAlignment: Alignment {
        switch item.direction {
        case .incoming:
            return .leading
        case .outgoing:
            return .trailing
        case .system:
            return .center
        }
    }

    private var textAlignment: Alignment {
        switch item.direction {
        case .incoming:
            return .leading
        case .outgoing:
            return .trailing
        case .system:
            return .leading
        }
    }

    private var bubbleColor: Color {
        switch item.direction {
        case .incoming:
            return .white
        case .outgoing:
            return Color(red: 0.11, green: 0.46, blue: 0.95)
        case .system:
            return Color(red: 0.93, green: 0.95, blue: 0.99)
        }
    }

    private var foregroundColor: Color {
        switch item.direction {
        case .outgoing:
            return .white
        case .incoming, .system:
            return .primary
        }
    }
}
