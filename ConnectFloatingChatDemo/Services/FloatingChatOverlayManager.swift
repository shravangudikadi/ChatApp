import SwiftUI

@MainActor
final class FloatingChatOverlayManager: ObservableObject {
    @Published var isVisible = false
    @Published var isExpanded = false
    @Published var bubbleOffset = CGSize(width: -24, height: -120)

    func showBubble() {
        isVisible = true
        isExpanded = false
    }

    func expand() {
        isVisible = true
        isExpanded = true
    }

    func minimize() {
        isExpanded = false
    }

    func hide() {
        isVisible = false
        isExpanded = false
    }
}
