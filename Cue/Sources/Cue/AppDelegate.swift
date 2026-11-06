import AppKit
import SwiftUI
import Carbon.HIToolbox

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate, NSWindowDelegate {
    private let state = PrompterState.shared
    private var panelController: NotchPanelController!
    private var statusItem: NSStatusItem!
    private var editorWindow: NSWindow?

    private var playItem: NSMenuItem!
    private var visibleItem: NSMenuItem!
    private var hideShareItem: NSMenuItem!

    func applicationDidFinishLaunching(_ notification: Notification) {
        installMainMenu()
        panelController = NotchPanelController()
        state.openEditor = { [weak self] in self?.openEditor() }
        setUpStatusItem()
        registerHotKeys()

        if !UserDefaults.standard.bool(forKey: "hasLaunchedBefore") {
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
            openEditor()
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    /// Opening Cue again (Finder, Spotlight, Launchpad) brings the teleprompter back.
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        state.show()
        openEditor()
        return true
    }

    // MARK: Menu bar

    private func setUpStatusItem() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "text.viewfinder", accessibilityDescription: "Cue")

        let menu = NSMenu()
        menu.delegate = self

        visibleItem = item("Hide Teleprompter", #selector(toggleVisible))
        menu.addItem(visibleItem)
        menu.addItem(.separator())
        playItem = item("Play", #selector(togglePlay))
        menu.addItem(playItem)
        menu.addItem(item("Restart", #selector(restart)))
        menu.addItem(item("Faster", #selector(faster)))
        menu.addItem(item("Slower", #selector(slower)))
        menu.addItem(.separator())
        menu.addItem(item("Edit Script…", #selector(openEditor), key: ","))
        menu.addItem(item("Open Script File…", #selector(openFile)))
        hideShareItem = item("Hide from Screen Sharing", #selector(toggleHideShare))
        menu.addItem(hideShareItem)
        menu.addItem(.separator())
        menu.addItem(item("Quit Cue", #selector(quit), key: "q"))
        statusItem.menu = menu
    }

    private func item(_ title: String, _ action: Selector, key: String = "") -> NSMenuItem {
        let i = NSMenuItem(title: title, action: action, keyEquivalent: key)
        i.target = self
        return i
    }

    func menuNeedsUpdate(_ menu: NSMenu) {
        playItem.title = state.isPlaying ? "Pause   (⌃⌥Space)" : "Play   (⌃⌥Space)"
        visibleItem.title = state.isVisible ? "Hide Teleprompter   (⌃⌥T)" : "Show Teleprompter   (⌃⌥T)"
        hideShareItem.state = state.hideFromScreenShare ? .on : .off
    }

    /// Accessory apps have no visible menu bar, but an Edit menu is still needed
    /// so ⌘C / ⌘V / ⌘A work inside the script editor.
    private func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "Quit Cue", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appItem.submenu = appMenu
        main.addItem(appItem)

        let editItem = NSMenuItem()
        let edit = NSMenu(title: "Edit")
        edit.addItem(withTitle: "Undo", action: Selector(("undo:")), keyEquivalent: "z")
        edit.addItem(withTitle: "Redo", action: Selector(("redo:")), keyEquivalent: "Z")
        edit.addItem(.separator())
        edit.addItem(withTitle: "Cut", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        edit.addItem(withTitle: "Copy", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        edit.addItem(withTitle: "Paste", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        edit.addItem(withTitle: "Select All", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editItem.submenu = edit
        main.addItem(editItem)

        let windowItem = NSMenuItem()
        let window = NSMenu(title: "Window")
        window.addItem(withTitle: "Close", action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")
        windowItem.submenu = window
        main.addItem(windowItem)

        NSApp.mainMenu = main
    }

    // MARK: Hotkeys

    private func registerHotKeys() {
        let mods = controlKey | optionKey
        let hk = HotKeyCenter.shared
        hk.register(keyCode: kVK_Space, modifiers: mods) { [weak self] in self?.state.togglePlay() }
        hk.register(keyCode: kVK_ANSI_Equal, modifiers: mods) { [weak self] in self?.state.faster() }
        hk.register(keyCode: kVK_ANSI_Minus, modifiers: mods) { [weak self] in self?.state.slower() }
        hk.register(keyCode: kVK_ANSI_LeftBracket, modifiers: mods) { [weak self] in self?.state.jump(lines: -3) }
        hk.register(keyCode: kVK_ANSI_RightBracket, modifiers: mods) { [weak self] in self?.state.jump(lines: 3) }
        hk.register(keyCode: kVK_ANSI_R, modifiers: mods) { [weak self] in self?.state.restart() }
        hk.register(keyCode: kVK_ANSI_T, modifiers: mods) { [weak self] in self?.state.toggleVisible() }
    }

    // MARK: Actions

    @objc private func togglePlay() { state.togglePlay() }
    @objc private func restart() { state.restart() }
    @objc private func faster() { state.faster() }
    @objc private func slower() { state.slower() }
    @objc private func toggleVisible() { state.toggleVisible() }
    @objc private func toggleHideShare() { state.hideFromScreenShare.toggle() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openFile() {
        openEditor()
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        if panel.runModal() == .OK, let url = panel.url {
            try? state.load(url: url)
        }
    }

    @objc func openEditor() {
        if editorWindow == nil {
            let w = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 560, height: 680),
                             styleMask: [.titled, .closable, .miniaturizable, .resizable],
                             backing: .buffered, defer: false)
            w.title = "Cue — Script & Settings"
            w.contentView = NSHostingView(rootView: EditorView())
            w.isReleasedWhenClosed = false
            w.delegate = self
            w.center()
            editorWindow = w
        }
        // Show in Dock / ⌘-Tab while editing, then go back to menu-bar only.
        NSApp.setActivationPolicy(.regular)
        editorWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func windowWillClose(_ notification: Notification) {
        if (notification.object as? NSWindow) === editorWindow {
            NSApp.setActivationPolicy(.accessory)
        }
    }
}
