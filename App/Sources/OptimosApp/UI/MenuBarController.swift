import AppKit

@MainActor
final class MenuBarController: NSObject, NSMenuDelegate {
    var onAction: ((HotkeyAction) -> Void)?
    var onOpenOptimizer: (() -> Void)?

    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
    private let permission: PermissionService
    private let saveLocation: SaveLocationStore
    private let hotkeys: [HotkeyAction: Hotkey]
    private var failedHotkeys: [HotkeyAction] = []

    init(
        permission: PermissionService, saveLocation: SaveLocationStore,
        hotkeys: [HotkeyAction: Hotkey] = Hotkey.defaults
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
            let shortcut = hotkeys[action]?.displayString ?? ""
            let item = NSMenuItem(
                title: "\(action.menuTitle)    \(shortcut)", action: #selector(capture(_:)), keyEquivalent: "")
            item.target = self
            item.representedObject = NSNumber(value: action.rawValue)
            menu.addItem(item)
        }

        menu.addItem(.separator())
        let optimize = NSMenuItem(title: "Optimize Images…", action: #selector(openOptimizer), keyEquivalent: "")
        optimize.target = self
        menu.addItem(optimize)

        menu.addItem(.separator())
        let asks = NSMenuItem(
            title: "Ask Where to Save Each Time", action: #selector(toggleAsk), keyEquivalent: "")
        asks.target = self
        asks.state = saveLocation.asksWhereToSave ? .on : .off
        menu.addItem(asks)
        let current = NSMenuItem(
            title: saveLocation.asksWhereToSave
                ? "Save panel starts in: \(saveLocation.displayPath)"
                : "Autosaving to: \(saveLocation.displayPath)",
            action: nil, keyEquivalent: "")
        current.isEnabled = false
        menu.addItem(current)
        let choose = NSMenuItem(title: "Save Location…", action: #selector(chooseSaveLocation), keyEquivalent: "")
        choose.target = self
        menu.addItem(choose)
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

    @objc private func openOptimizer() { onOpenOptimizer?() }

    @objc private func toggleAsk() {
        saveLocation.setAsksWhereToSave(!saveLocation.asksWhereToSave)
        if let menu = statusItem.menu { rebuild(menu) }
    }

    @objc private func chooseSaveLocation() {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Choose"
        panel.message = "Choose the folder where screenshots are saved."
        panel.directoryURL = saveLocation.directory
        // An accessory app is not frontmost by default, and the panel would open behind other windows.
        NSApp.activate(ignoringOtherApps: true)
        guard panel.runModal() == .OK, let url = panel.url else { return }  // cancelled: nothing changes
        saveLocation.setDirectory(url)
        if let menu = statusItem.menu { rebuild(menu) }
    }

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
