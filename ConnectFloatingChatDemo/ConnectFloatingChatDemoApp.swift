import SwiftUI

@main
struct ConnectFloatingChatDemoApp: App {
    @StateObject private var settingsStore: ChatSettingsStore
    @StateObject private var chatService: InHouseChatService
    @StateObject private var overlayManager: FloatingChatOverlayManager
    @StateObject private var componentRegistry: ChatComponentRegistry

    init() {
        let settingsStore = ChatSettingsStore()
        let chatService = InHouseChatService()
        _settingsStore = StateObject(wrappedValue: settingsStore)
        _chatService = StateObject(wrappedValue: chatService)
        _overlayManager = StateObject(wrappedValue: FloatingChatOverlayManager())
        _componentRegistry = StateObject(wrappedValue: ChatComponentRegistry())
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(settingsStore)
                .environmentObject(chatService)
                .environmentObject(overlayManager)
                .environmentObject(componentRegistry)
        }
    }
}
