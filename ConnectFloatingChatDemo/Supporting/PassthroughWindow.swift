import UIKit

final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hitView = super.hitTest(point, with: event)
        if let rootView = rootViewController?.view, hitView === rootView {
            return nil
        }

        return hitView
    }
}
