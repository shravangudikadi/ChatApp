import SwiftUI

struct RootTabView: View {
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
                            title: "Transcript Status",
                            description: chatService.bannerText,
                            accent: statusColor
                        )
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
