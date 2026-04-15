import SwiftUI

@main
struct ConnectFloatingChatDemoApp: App {
    @StateObject private var settingsStore: ChatSettingsStore
    @StateObject private var chatService: AmazonConnectChatService
    @StateObject private var overlayManager: FloatingChatOverlayManager

    init() {
        let settingsStore = ChatSettingsStore()
        let chatService = AmazonConnectChatService()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _chatService = StateObject(wrappedValue: chatService)
        _overlayManager = StateObject(
            wrappedValue: FloatingChatOverlayManager(
                chatService: chatService,
                settingsStore: settingsStore
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settingsStore)
                .environmentObject(chatService)
                .environmentObject(overlayManager)
        }
    }
}
