import SwiftUI

struct ChatPanelView: View {
    @EnvironmentObject private var settingsStore: ChatSettingsStore
    @EnvironmentObject private var chatService: InHouseChatService
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager
    @EnvironmentObject private var componentRegistry: ChatComponentRegistry

    let isOverlayPresentation: Bool
    @FocusState private var isComposerFocused: Bool

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
                                    .environmentObject(componentRegistry)
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
        .onAppear {
            startMockSessionIfNeeded()
        }
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

            providerModeCard
        }
        .padding(16)
        .background(.thinMaterial)
    }

    private var providerModeCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "rectangle.on.rectangle.angled")
                .foregroundStyle(Color(red: 0.02, green: 0.66, blue: 0.62))

            Text(chatService.experienceDescription)
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
            if chatService.isConnected {
                quickReplyRow
            }

            Divider()

            HStack(spacing: 12) {
                TextField("Type a message", text: $chatService.draftMessage, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .focused($isComposerFocused)
                    .submitLabel(.send)
                    .disabled(!chatService.isConnected)
                    .onSubmit {
                        chatService.sendDraftMessage()
                    }

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
                        chatService.startSession(using: settingsStore.currentConfiguration)
                    } label: {
                        if chatService.connectionState == .connecting {
                            ProgressView()
                                .frame(width: 40, height: 40)
                        } else {
                            Image(systemName: "play.circle.fill")
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
                Button("Reset Session") {
                    chatService.resetDemo(using: settingsStore.currentConfiguration)
                }
                .font(.footnote.weight(.semibold))
            }
        }
        .padding(16)
        .background(.background)
        .onChange(of: chatService.connectionState) { newValue in
            guard newValue == .connected else {
                isComposerFocused = false
                return
            }

            focusComposer()
        }
        .onChange(of: overlayManager.isExpanded) { isExpanded in
            guard isOverlayPresentation, isExpanded, chatService.isConnected else { return }
            focusComposer()
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("No messages yet")
                .font(.headline)

            Text("Start the in-house session and the transcript will return travel-style responses, including reusable SwiftUI components rendered directly in chat.")
                .foregroundStyle(.secondary)

            Button {
                chatService.startSession(using: settingsStore.currentConfiguration)
            } label: {
                Label("Start In-House Conversation", systemImage: "play.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(red: 0.02, green: 0.66, blue: 0.62))
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.white)
        )
    }

    @ViewBuilder
    private var quickReplyRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Try a mock question")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    quickReplyButton("Show hotels in Miami")
                    quickReplyButton("Weekend stay in New York")
                    quickReplyButton("Any beach resorts?")
                }
            }
        }
    }

    private func startMockSessionIfNeeded() {
        guard chatService.connectionState == .idle else { return }
        chatService.startSession(using: settingsStore.currentConfiguration)
    }

    private func quickReplyButton(_ text: String) -> some View {
        Button {
            chatService.draftMessage = text
            chatService.sendDraftMessage()
        } label: {
            Text(text)
                .font(.footnote.weight(.medium))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.bordered)
    }

    private func focusComposer() {
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            isComposerFocused = true
        }
    }
}

private struct MessageBubbleRow: View {
    @EnvironmentObject private var componentRegistry: ChatComponentRegistry
    @EnvironmentObject private var chatService: InHouseChatService

    let item: ChatMessageItem

    var body: some View {
        VStack(alignment: alignment, spacing: 6) {
            Text(item.senderName)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            bubbleBody

            if !item.actionChips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(item.actionChips) { chip in
                            Button {
                                chatService.draftMessage = chip.prompt
                                chatService.sendDraftMessage()
                            } label: {
                                Text(chip.title)
                                    .font(.footnote.weight(.medium))
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                }
            }

            if let statusText = item.statusText {
                Text(statusText)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: rowAlignment)
    }

    @ViewBuilder
    private var bubbleBody: some View {
        switch item.content {
        case .text(let text):
            Text(text)
                .frame(maxWidth: .infinity, alignment: textAlignment)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(bubbleColor)
                .foregroundStyle(foregroundColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        case .embeddedComponent(let component):
            componentRegistry.view(for: component)
                .padding(14)
                .background(bubbleColor)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
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
