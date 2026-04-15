import SwiftUI
import UIKit

@MainActor
final class FloatingChatOverlayManager: ObservableObject {
    @Published var isVisible = false
    @Published var isExpanded = false
    @Published var bubbleOffset = CGSize(width: -24, height: -120)

    private var overlayWindow: PassthroughWindow?
    private weak var hostWindow: UIWindow?
    private let chatService: AmazonConnectChatService
    private let settingsStore: ChatSettingsStore

    init(chatService: AmazonConnectChatService, settingsStore: ChatSettingsStore) {
        self.chatService = chatService
        self.settingsStore = settingsStore
    }

    func showBubble() {
        installOverlayIfNeeded()
        isVisible = true
        isExpanded = false
        overlayWindow?.isHidden = false
        overlayWindow?.makeKeyAndVisible()
    }

    func expand() {
        installOverlayIfNeeded()
        isVisible = true
        isExpanded = true
        overlayWindow?.isHidden = false
        overlayWindow?.makeKeyAndVisible()
    }

    func minimize() {
        isExpanded = false
    }

    func hide() {
        isVisible = false
        isExpanded = false
        overlayWindow?.isHidden = true
        overlayWindow?.rootViewController = nil
        overlayWindow = nil
        hostWindow?.makeKey()
    }

    private func installOverlayIfNeeded() {
        let scene = activeWindowScene()

        if overlayWindow?.windowScene == scene, overlayWindow != nil {
            return
        }

        hostWindow = activeHostWindow(in: scene)

        let window = PassthroughWindow(windowScene: scene)
        window.frame = scene.coordinateSpace.bounds
        window.backgroundColor = .clear
        window.windowLevel = .alert + 1
        window.isHidden = false

        let rootView = FloatingChatOverlayView()
            .environmentObject(self)
            .environmentObject(chatService)
            .environmentObject(settingsStore)

        let controller = UIHostingController(rootView: rootView)
        controller.view.backgroundColor = .clear
        window.rootViewController = controller
        window.isHidden = !isVisible
        window.makeKeyAndVisible()
        overlayWindow = window
    }

    private func activeWindowScene() -> UIWindowScene {
        let scenes = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }

        if let foregroundScene = scenes.first(where: { $0.activationState == .foregroundActive }) {
            return foregroundScene
        }

        guard let firstScene = scenes.first else {
            fatalError("No active UIWindowScene found.")
        }

        return firstScene
    }

    private func activeHostWindow(in scene: UIWindowScene) -> UIWindow? {
        if let keyWindow = scene.windows.first(where: { $0.isKeyWindow && !($0 is PassthroughWindow) }) {
            return keyWindow
        }

        return scene.windows.first(where: { !($0 is PassthroughWindow) })
    }
}
