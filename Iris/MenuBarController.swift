import AppKit

final class MenuBarController: NSObject {
    private let item: NSStatusItem
    var onToggle: (() -> Void)?

    override init() {
        item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()
        item.button?.title = "🌸"

        let menu = NSMenu()
        let toggle = NSMenuItem(
            title: "Toggle Overlay",
            action: #selector(toggleAction),
            keyEquivalent: "t"
        )
        toggle.target = self
        menu.addItem(toggle)
        menu.addItem(.separator())
        menu.addItem(NSMenuItem(
            title: "Quit Iris",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        ))
        item.menu = menu
    }

    @objc private func toggleAction() {
        onToggle?()
    }
}
