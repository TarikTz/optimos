import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    var onAction: ((HotkeyAction) -> Void)?
    var onOpenPreferences: (() -> Void)?
    var onAbout: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let permission: PermissionService
    private let saveLocation: SaveLocationStore
    private let hotkeys: () -> [HotkeyAction: Hotkey]
    private var failedHotkeys: [HotkeyAction] = []

    init(
        permission: PermissionService, saveLocation: SaveLocationStore,
        hotkeys: @escaping () -> [HotkeyAction: Hotkey] = { Hotkey.defaults }
    ) {
        self.permission = permission
        self.saveLocation = saveLocation
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
            let shortcut = hotkeys()[action]?.displayString ?? ""
            let item = NSMenuItem(
                title: "\(action.menuTitle)    \(shortcut)", action: #selector(capture(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: action.rawValue)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let reveal = NSMenuItem(
            title: "Show Last Screenshot in Finder", action: #selector(revealLastScreenshot), keyEquivalent: "")
        reveal.target = self
        // Disabled until something has been saved, and again if that file was moved or deleted.
        if let last = saveLocation.lastSavedFile, FileManager.default.fileExists(atPath: last.path) {
            reveal.isEnabled = true
        } else {
            reveal.isEnabled = false
        }
        menu.addItem(reveal)

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
            let shortcut = hotkeys()[action]?.displayString ?? ""
            let item = NSMenuItem(
                title: "⚠︎ \(shortcut) could not be registered", action: nil, keyEquivalent: "")
            item.isEnabled = false
            menu.addItem(item)
        }
        menu.addItem(.separator())
        let prefs = NSMenuItem(title: "Preferences…", action: #selector(openPreferences), keyEquivalent: ",")
        prefs.target = self
        menu.addItem(prefs)
        let about = NSMenuItem(title: "About OptimosApp", action: #selector(showAbout), keyEquivalent: "")
        about.target = self
        menu.addItem(about)
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

    @objc private func openPreferences() { onOpenPreferences?() }
    @objc private func showAbout() { onAbout?() }

    @objc private func revealLastScreenshot() {
        guard let last = saveLocation.lastSavedFile else { return }
        NSWorkspace.shared.activateFileViewerSelecting([last])
    }

    @objc private func grantAccess() {
        permission.request()
        permission.openSystemSettings()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
