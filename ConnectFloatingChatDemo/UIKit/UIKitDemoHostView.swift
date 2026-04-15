import SwiftUI

struct UIKitDemoHostView: View {
    @EnvironmentObject private var overlayManager: FloatingChatOverlayManager

    var body: some View {
        UIKitDemoContainer(overlayManager: overlayManager)
            .ignoresSafeArea()
            .navigationTitle("UIKit")
    }
}

private struct UIKitDemoContainer: UIViewControllerRepresentable {
    let overlayManager: FloatingChatOverlayManager

    func makeUIViewController(context: Context) -> UIKitDemoViewController {
        UIKitDemoViewController(overlayManager: overlayManager)
    }

    func updateUIViewController(_ uiViewController: UIKitDemoViewController, context: Context) {
    }
}
