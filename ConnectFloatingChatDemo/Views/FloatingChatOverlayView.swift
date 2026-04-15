import SwiftUI

struct FloatingChatOverlayView: View {
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .bottomTrailing) {
                if overlayManager.isVisible {
                    if overlayManager.isExpanded {
                        ChatPanelView(isOverlayPresentation: true)
                            .frame(
                                width: min(proxy.size.width - 24, 380),
                                height: min(proxy.size.height - 40, 620)
                            )
                            .padding(.trailing, 12)
                            .padding(.bottom, 12)
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                    } else {
                        bubbleButton
                            .offset(overlayManager.bubbleOffset)
                            .gesture(dragGesture)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: overlayManager.isExpanded)
            .animation(.spring(response: 0.32, dampingFraction: 0.88), value: overlayManager.isVisible)
        }
        .ignoresSafeArea()
    }

    private var bubbleButton: some View {
        Button {
            overlayManager.expand()
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "message.fill")
                    .font(.headline)

                Text("Chat")
                    .font(.headline.weight(.semibold))
            }
            .foregroundStyle(.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .background(
                Capsule(style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.11, green: 0.46, blue: 0.95),
                                Color(red: 0.02, green: 0.66, blue: 0.62)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: .black.opacity(0.22), radius: 18, y: 12)
            )
        }
        .buttonStyle(.plain)
        .padding(.trailing, 12)
        .padding(.bottom, 12)
    }

    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                overlayManager.bubbleOffset = CGSize(
                    width: overlayManager.bubbleOffset.width + value.translation.width,
                    height: overlayManager.bubbleOffset.height + value.translation.height
                )
            }
    }
}
