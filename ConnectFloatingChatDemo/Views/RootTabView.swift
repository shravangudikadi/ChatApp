import SwiftUI

struct RootTabView: View {
    private enum DemoTab: Hashable {
        case swiftUI
        case uikit
        case poc
    }

    @EnvironmentObject private var settingsStore: ChatSettingsStore
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager
    @EnvironmentObject private var chatService: AmazonConnectChatService
    @State private var selectedTab: DemoTab = .poc

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView(selection: $selectedTab) {
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
                .tag(DemoTab.swiftUI)
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
                .tag(DemoTab.uikit)
                .tabItem {
                    Label("UIKit", systemImage: "rectangle.3.offgrid")
                }

                NavigationStack {
                    ScrollView {
                        VStack(spacing: 20) {
                            ChatStatusCard(
                                title: "Verified Working Chat",
                                description: "Use the inline panel below for the verified working mock conversation flow. The same chat service powers both the inline panel and the floating bubble.",
                                accent: .orange
                            )

                            ChatPanelView(isOverlayPresentation: false)
                                .frame(minHeight: 560)

                            ChatStatusCard(
                                title: "Provider Status",
                                description: chatService.bannerText,
                                accent: statusColor
                            )

                            ConnectionFormView()

                            ChatStatusCard(
                                title: "Current Architecture",
                                description: settingsStore.providerMode == .mock ? "Mock provider drives the transcript locally. The UI layer is already structured so you can swap to the real SDK provider later." : "Real SDK provider selected. The app will attempt the true Amazon Connect SDK path as soon as a bootstrap service returns participant details.",
                                accent: settingsStore.providerMode == .mock ? .green : .blue
                            )
                        }
                        .padding(20)
                    }
                    .navigationTitle("POC")
                }
                .tag(DemoTab.poc)
                .tabItem {
                    Label("POC", systemImage: "testtube.2")
                }
            }
            .tint(Color(red: 0.11, green: 0.46, blue: 0.95))

            FloatingChatOverlayView()
                .zIndex(1)
        }
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
