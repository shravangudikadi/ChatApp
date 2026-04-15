import UIKit

final class UIKitDemoViewController: UIViewController {
    private let overlayManager: FloatingChatOverlayManager

    init(overlayManager: FloatingChatOverlayManager) {
        self.overlayManager = overlayManager
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildInterface()
    }

    private func buildInterface() {
        let hero = UIView()
        hero.translatesAutoresizingMaskIntoConstraints = false
        hero.layer.cornerRadius = 28
        hero.layer.cornerCurve = .continuous
        hero.backgroundColor = UIColor(red: 0.10, green: 0.16, blue: 0.33, alpha: 1.0)

        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor(red: 0.11, green: 0.46, blue: 0.95, alpha: 1.0).cgColor,
            UIColor(red: 0.02, green: 0.66, blue: 0.62, alpha: 1.0).cgColor
        ]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        hero.layer.insertSublayer(gradient, at: 0)

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "UIKit Screen"
        titleLabel.font = .preferredFont(forTextStyle: .largeTitle).bold()
        titleLabel.textColor = .white

        let bodyLabel = UILabel()
        bodyLabel.translatesAutoresizingMaskIntoConstraints = false
        bodyLabel.numberOfLines = 0
        bodyLabel.textColor = UIColor.white.withAlphaComponent(0.88)
        bodyLabel.font = .preferredFont(forTextStyle: .title3)
        bodyLabel.text = "The same floating bubble works here too because it sits in a separate overlay window instead of being pushed by one navigation stack."

        let bubbleButton = UIButton(type: .system)
        bubbleButton.translatesAutoresizingMaskIntoConstraints = false
        bubbleButton.configuration = .filled()
        bubbleButton.configuration?.title = "Show Floating Bubble"
        bubbleButton.configuration?.image = UIImage(systemName: "message.circle.fill")
        bubbleButton.configuration?.imagePadding = 8
        bubbleButton.configuration?.cornerStyle = .capsule
        bubbleButton.tintColor = UIColor(red: 0.11, green: 0.46, blue: 0.95, alpha: 1.0)
        bubbleButton.addAction(UIAction { [weak self] _ in
            self?.overlayManager.showBubble()
        }, for: .touchUpInside)

        let openPanelButton = UIButton(type: .system)
        openPanelButton.translatesAutoresizingMaskIntoConstraints = false
        openPanelButton.configuration = .bordered()
        openPanelButton.configuration?.title = "Open Chat Panel"
        openPanelButton.configuration?.cornerStyle = .capsule
        openPanelButton.addAction(UIAction { [weak self] _ in
            self?.overlayManager.expand()
        }, for: .touchUpInside)

        hero.addSubview(titleLabel)
        hero.addSubview(bodyLabel)
        hero.addSubview(bubbleButton)
        hero.addSubview(openPanelButton)
        view.addSubview(hero)

        NSLayoutConstraint.activate([
            hero.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            hero.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            hero.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),

            titleLabel.topAnchor.constraint(equalTo: hero.topAnchor, constant: 24),
            titleLabel.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -24),

            bodyLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 16),
            bodyLabel.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
            bodyLabel.trailingAnchor.constraint(equalTo: hero.trailingAnchor, constant: -24),

            bubbleButton.topAnchor.constraint(equalTo: bodyLabel.bottomAnchor, constant: 24),
            bubbleButton.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),

            openPanelButton.topAnchor.constraint(equalTo: bubbleButton.bottomAnchor, constant: 12),
            openPanelButton.leadingAnchor.constraint(equalTo: hero.leadingAnchor, constant: 24),
            openPanelButton.bottomAnchor.constraint(equalTo: hero.bottomAnchor, constant: -24)
        ])

        hero.layoutIfNeeded()
        gradient.frame = hero.bounds
    }
}

private extension UIFont {
    func bold() -> UIFont {
        let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) ?? fontDescriptor
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}
