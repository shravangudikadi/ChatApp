import SwiftUI

struct SwiftUIHostDemoView: View {
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.97, green: 0.98, blue: 1.0),
                    Color(red: 0.88, green: 0.94, blue: 1.0),
                    Color(red: 0.91, green: 0.96, blue: 0.92)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("SwiftUI Demo")
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))

                    Text("Tap once to place the chat bubble above the whole app window. It will stay available while you move between screens.")
                        .font(.title3)
                        .foregroundStyle(.secondary)

                    ChatStatusCard(
                        title: "Floating Overlay",
                        description: "This bubble is hosted inside a separate `UIWindow`, so it can float over SwiftUI and UIKit content without being tied to one screen hierarchy.",
                        accent: Color(red: 0.11, green: 0.46, blue: 0.95)
                    )

                    Button {
                        overlayManager.showBubble()
                    } label: {
                        Label("Show Floating Bubble", systemImage: "message.circle.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(red: 0.11, green: 0.46, blue: 0.95))

                    Button {
                        overlayManager.expand()
                    } label: {
                        Label("Open Chat Panel", systemImage: "rectangle.portrait.on.rectangle.portrait.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                }
                .padding(24)
            }
        }
        .navigationTitle("SwiftUI")
    }
}
