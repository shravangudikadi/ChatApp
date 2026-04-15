import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var settingsStore: ChatSettingsStore
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager
    @EnvironmentObject private var chatService: AmazonConnectChatService

    var body: some View {
        TabView {
            NavigationStack {
                SwiftUIHostDemoView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                overlayManager.showBubble()
                            } label: {
                                Label("Bubble", systemImage: "message.badge")
                            }
                        }
                    }
            }
            .tabItem {
                Label("SwiftUI", systemImage: "sparkles.rectangle.stack")
            }

            NavigationStack {
                UIKitDemoHostView()
                    .toolbar {
                        ToolbarItem(placement: .topBarTrailing) {
                            Button {
                                overlayManager.showBubble()
                            } label: {
                                Label("Bubble", systemImage: "square.stack.3d.up")
                            }
                        }
                    }
            }
            .tabItem {
                Label("UIKit", systemImage: "rectangle.3.offgrid")
            }

            NavigationStack {
                ScrollView {
                    VStack(spacing: 20) {
                        ConnectionFormView()

                        ChatStatusCard(
                            title: "Provider Status",
                            description: chatService.bannerText,
                            accent: statusColor
                        )

                        ChatStatusCard(
                            title: "Current Architecture",
                            description: settingsStore.providerMode == .mock ? "Mock provider drives the transcript locally. The UI layer is already structured so you can swap to the real SDK provider later." : "Real SDK provider selected. The app will attempt the true Amazon Connect SDK path as soon as a bootstrap service returns participant details.",
                            accent: settingsStore.providerMode == .mock ? .green : .blue
                        )

                        ChatStatusCard(
                            title: "Typing Test",
                            description: "Use the inline panel below if the floating overlay does not capture keyboard focus reliably in simulator. The same chat service powers both views.",
                            accent: .orange
                        )

                        ChatPanelView(isOverlayPresentation: false)
                            .frame(minHeight: 560)
                    }
                    .padding(20)
                }
                .navigationTitle("POC")
            }
            .tabItem {
                Label("POC", systemImage: "testtube.2")
            }
        }
        .tint(Color(red: 0.11, green: 0.46, blue: 0.95))
    }

    private var statusColor: Color {
        switch chatService.connectionState {
        case .connected:
            return .green
        case .connecting:
            return .orange
        case .failed:
            return .red
        case .ended:
            return .gray
        case .idle:
            return .blue
        }
    }
}
