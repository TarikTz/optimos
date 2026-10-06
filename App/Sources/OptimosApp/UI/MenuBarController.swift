import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    var onAction: ((HotkeyAction) -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let permission: PermissionService
    private let hotkeys: [HotkeyAction: Hotkey]
    private var failedHotkeys: [HotkeyAction] = []

    init(permission: PermissionService, hotkeys: [HotkeyAction: Hotkey] = Hotkey.defaults) {
        self.permission = permission
        self.hotkeys = hotkeys
        super.init()
        statusItem.button?.image = NSImage(
            systemSymbolName: "camera.viewfinder", accessibilityDescription: "OptimosApp")
        let menu = NSMenu()
        menu.delegate = self
        statusItem.menu = menu
        rebuild(menu)
    }

    func setFailedHotkeys(_ failed: [HotkeyAction]) {
        failedHotkeys = failed
        if let menu = statusItem.menu { rebuild(menu) }
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        rebuild(menu)
    }

    private func rebuild(_ menu: NSMenu) {
        menu.removeAllItems()
        for action in HotkeyAction.allCases {
            let shortcut = hotkeys[action]?.displayString ?? ""
            let item = NSMenuItem(
                title: "\(action.menuTitle)    \(shortcut)", action: #selector(capture(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: action.rawValue)
            menu.addItem(item)
        }
        menu.addItem(.separator())
        if permission.isGranted {
            let item = NSMenuItem(title: "Screen Recording: allowed", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        } else {
            let item = NSMenuItem(
                title: "Allow Screen Recording…", action: #selector(grantAccess), keyEquivalent: "")
            item.target = self
            menu.addItem(item)
        }
        for action in failedHotkeys {
            let shortcut = hotkeys[action]?.displayString ?? ""
            let item = NSMenuItem(
                title: "⚠︎ \(shortcut) could not be registered", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let quit = NSMenuItem(title: "Quit OptimosApp", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)
    }

    @objc private func capture(_ sender: NSMenuItem) {
        guard let number = sender.representedObject as? NSNumber,
            let action = HotkeyAction(rawValue: number.uint32Value)
        else { return }
        onAction?(action)
    }

    @objc private func grantAccess() {
        permission.request()
        permission.openSystemSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
