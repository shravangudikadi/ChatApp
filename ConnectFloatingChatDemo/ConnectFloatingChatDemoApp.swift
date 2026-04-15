import SwiftUI

@main
struct ConnectFloatingChatDemoApp: App {
    @StateObject private var chatService: AmazonConnectChatService
    @StateObject private var overlayManager: FloatingChatOverlayManager

    init() {
        let chatService = AmazonConnectChatService()
        _chatService = StateObject(wrappedValue: chatService)
        _overlayManager = StateObject(
            wrappedValue: FloatingChatOverlayManager(
                chatService: chatService
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(chatService)
                .environmentObject(overlayManager)
        }
    }
}
