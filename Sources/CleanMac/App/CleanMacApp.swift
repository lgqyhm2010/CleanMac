import AppKit
import CleanMacCore
import Combine
import SwiftUI

@main
@MainActor
enum CleanMacApp {
    private static var appDelegate: AppDelegate?

    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        appDelegate = delegate
        app.delegate = delegate
        app.setActivationPolicy(.regular)
        delegate.installApplicationIcon()
        delegate.configureMainMenu()
        app.finishLaunching()
        delegate.showMainWindow()
        app.run()
    }
}

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var mainWindow: NSWindow?
    private var settingsWindow: NSWindow?
    private var settingsMenuItem: NSMenuItem?
    private var quitMenuItem: NSMenuItem?
    private var statusItem: NSStatusItem?
    private var statusMenuStatusItem: NSMenuItem?
    private var statusMenuScanItem: NSMenuItem?
    private var statusMenuShowItem: NSMenuItem?
    private var statusMenuSettingsItem: NSMenuItem?
    private var statusMenuQuitItem: NSMenuItem?
    private var editMenu: NSMenu?
    private var editUndoItem: NSMenuItem?
    private var editRedoItem: NSMenuItem?
    private var editCutItem: NSMenuItem?
    private var editCopyItem: NSMenuItem?
    private var editPasteItem: NSMenuItem?
    private var editSelectAllItem: NSMenuItem?
    private var cleanerMenu: NSMenu?
    private var cleanerScanItem: NSMenuItem?
    private var cleanerSelectAllItem: NSMenuItem?
    private var cleanerClearItem: NSMenuItem?
    private var cleanerAskAIItem: NSMenuItem?
    private var statusCancellables: Set<AnyCancellable> = []
    private lazy var store = CleaningStore(language: resolvedLanguage)

    func installApplicationIcon() {
        guard
            let iconURL = Bundle.module.url(forResource: "cleanmac-mascot", withExtension: "png", subdirectory: "Images"),
            let iconImage = NSImage(contentsOf: iconURL)
        else {
            return
        }

        NSApp.applicationIconImage = iconImage
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        showMainWindow()
        return true
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }

    func configureMainMenu() {
        let mainMenu = NSMenu()
        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        let settingsItem = NSMenuItem(
            title: "",
            action: #selector(showSettingsWindow),
            keyEquivalent: ","
        )
        let quitItem = NSMenuItem(
            title: "",
            action: #selector(NSApplication.terminate(_:)),
            keyEquivalent: "q"
        )

        settingsMenuItem = settingsItem
        quitMenuItem = quitItem

        appMenu.addItem(settingsItem)
        appMenu.addItem(.separator())
        appMenu.addItem(quitItem)
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)
        mainMenu.addItem(makeEditMenuItem())
        mainMenu.addItem(makeCleanerMenuItem())
        NSApp.mainMenu = mainMenu
        configureStatusItem()
        updateLocalizedChrome()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(userDefaultsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil,
        )
    }

    /// Standard Edit menu so Undo/Redo/Cut/Copy/Paste/Select All work in every text field
    /// and editor. The actions target the first responder via the responder chain.
    private func makeEditMenuItem() -> NSMenuItem {
        let language = resolvedLanguage
        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: L10n.text(.edit, language: language))
        let undoItem = editMenu.addItem(withTitle: L10n.text(.undo, language: language), action: Selector(("undo:")), keyEquivalent: "z")
        let redoItem = editMenu.addItem(withTitle: L10n.text(.redo, language: language), action: Selector(("redo:")), keyEquivalent: "z")
        redoItem.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        let cutItem = editMenu.addItem(withTitle: L10n.text(.cut, language: language), action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        let copyItem = editMenu.addItem(withTitle: L10n.text(.copy, language: language), action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        let pasteItem = editMenu.addItem(withTitle: L10n.text(.paste, language: language), action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(.separator())
        let selectAllItem = editMenu.addItem(withTitle: L10n.text(.selectAll, language: language), action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        self.editMenu = editMenu
        editUndoItem = undoItem
        editRedoItem = redoItem
        editCutItem = cutItem
        editCopyItem = copyItem
        editPasteItem = pasteItem
        editSelectAllItem = selectAllItem
        return editMenuItem
    }

    /// Cleaner menu whose items drive the shared store directly, so the keyboard shortcuts
    /// (Scan ⌘R, Select All ⌘⇧A, Clear ⌘⇧⌫, Ask AI ⌘⇧I) actually fire in this AppKit app.
    private func makeCleanerMenuItem() -> NSMenuItem {
        let language = resolvedLanguage
        let cleanerMenuItem = NSMenuItem()
        let menu = NSMenu(title: L10n.text(.cleaner, language: language))

        let scanItem = NSMenuItem(title: L10n.text(.scan, language: language), action: #selector(scanFromMenu), keyEquivalent: "r")
        let selectAllItem = NSMenuItem(title: L10n.text(.selectAllCandidates, language: language), action: #selector(selectAllCandidatesFromMenu), keyEquivalent: "a")
        selectAllItem.keyEquivalentModifierMask = [.command, .shift]
        let clearItem = NSMenuItem(title: L10n.text(.clearSelection, language: language), action: #selector(clearSelectionFromMenu), keyEquivalent: String(UnicodeScalar(NSBackspaceCharacter)!))
        clearItem.keyEquivalentModifierMask = [.command, .shift]
        let askAIItem = NSMenuItem(title: L10n.text(.askAI, language: language), action: #selector(askAIFromMenu), keyEquivalent: "i")
        askAIItem.keyEquivalentModifierMask = [.command, .shift]

        [scanItem, selectAllItem, clearItem, askAIItem].forEach { $0.target = self }

        menu.addItem(scanItem)
        menu.addItem(.separator())
        menu.addItem(selectAllItem)
        menu.addItem(clearItem)
        menu.addItem(.separator())
        menu.addItem(askAIItem)

        cleanerMenuItem.submenu = menu
        cleanerMenu = menu
        cleanerScanItem = scanItem
        cleanerSelectAllItem = selectAllItem
        cleanerClearItem = clearItem
        cleanerAskAIItem = askAIItem
        return cleanerMenuItem
    }

    @objc
    private func scanFromMenu() {
        showMainWindow()
        store.scan()
    }

    @objc
    private func selectAllCandidatesFromMenu() {
        store.selectAll()
    }

    @objc
    private func clearSelectionFromMenu() {
        store.clearSelection()
    }

    @objc
    private func askAIFromMenu() {
        showMainWindow()
        store.askAI()
    }

    func showMainWindow() {
        if let mainWindow {
            activateApplication()
            mainWindow.makeKeyAndOrderFront(nil)
            mainWindow.makeMain()
            mainWindow.orderFrontRegardless()
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_180, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CleanMac"
        window.backgroundColor = NSColor(
            calibratedRed: 1.0,
            green: 253.0 / 255.0,
            blue: 246.0 / 255.0,
            alpha: 1.0
        )
        window.isOpaque = true
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: ContentView(store: store)
                .frame(minWidth: 1_020, minHeight: 660)
        )
        window.minSize = NSSize(width: 1_020, height: 660)
        window.contentMinSize = NSSize(width: 1_020, height: 660)
        window.setContentSize(NSSize(width: 1_180, height: 760))
        window.setFrame(Self.defaultMainWindowFrame(), display: true)
        mainWindow = window
        activateApplication()
        window.makeKeyAndOrderFront(nil)
        window.makeMain()
        window.orderFrontRegardless()
        DispatchQueue.main.async { [weak self, weak window] in
            guard let window else { return }
            self?.activateApplication()
            window.makeKeyAndOrderFront(nil)
            window.makeMain()
            window.orderFrontRegardless()
        }
    }

    private static func defaultMainWindowFrame() -> NSRect {
        let fallback = NSRect(x: 160, y: 120, width: 1_180, height: 792)
        guard let visibleFrame = NSScreen.main?.visibleFrame else { return fallback }
        let width = min(CGFloat(1_180), visibleFrame.width - 80)
        let height = min(CGFloat(792), visibleFrame.height - 80)
        return NSRect(
            x: visibleFrame.midX - width / 2,
            y: visibleFrame.midY - height / 2,
            width: width,
            height: height
        )
    }

    private func activateApplication() {
        NSApp.activate(ignoringOtherApps: true)
    }

    private func configureStatusItem() {
        guard statusItem == nil else { return }

        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "CleanMac"
        statusItem.button?.toolTip = "CleanMac"

        let menu = NSMenu()
        let statusItemLabel = NSMenuItem(title: "CleanMac", action: nil, keyEquivalent: "")
        statusItemLabel.isEnabled = false

        let showItem = NSMenuItem(title: "CleanMac", action: #selector(showMainWindowFromStatusItem), keyEquivalent: "")
        let scanItem = NSMenuItem(title: L10n.text(.scan, language: resolvedLanguage), action: #selector(scanFromStatusItem), keyEquivalent: "")
        let settingsItem = NSMenuItem(title: L10n.text(.settings, language: resolvedLanguage), action: #selector(showSettingsWindow), keyEquivalent: "")
        let quitItem = NSMenuItem(title: L10n.text(.quitCleanMac, language: resolvedLanguage), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")

        [showItem, scanItem, settingsItem].forEach { $0.target = self }
        quitItem.target = NSApp

        menu.addItem(statusItemLabel)
        menu.addItem(.separator())
        menu.addItem(showItem)
        menu.addItem(scanItem)
        menu.addItem(settingsItem)
        menu.addItem(.separator())
        menu.addItem(quitItem)

        statusItem.menu = menu
        self.statusItem = statusItem
        statusMenuStatusItem = statusItemLabel
        statusMenuScanItem = scanItem
        statusMenuShowItem = showItem
        statusMenuSettingsItem = settingsItem
        statusMenuQuitItem = quitItem

        Publishers.CombineLatest3(store.$status, store.$candidates, store.$foregroundOperationState)
            .receive(on: RunLoop.main)
            .sink { [weak self] status, candidates, operationState in
                Task { @MainActor [weak self] in
                    let isScanning = operationState.operation == .scanningFiles || operationState.operation == .scanningApplications
                    self?.updateStatusItem(
                        status: status,
                        candidateCount: candidates.count,
                        isScanning: isScanning,
                        isBusy: operationState.operation != nil
                    )
                }
            }
            .store(in: &statusCancellables)
    }

    private func updateStatusItem(status: CleaningStatus, candidateCount: Int, isScanning: Bool, isBusy: Bool) {
        let title = MenuBarMonitorSummary.title(
            status: status,
            candidateCount: candidateCount,
            isScanning: isScanning,
            language: resolvedLanguage
        )
        statusItem?.button?.title = title
        statusMenuStatusItem?.title = title
        statusMenuScanItem?.isEnabled = !isBusy
    }

    @objc
    private func showMainWindowFromStatusItem() {
        showMainWindow()
    }

    @objc
    private func scanFromStatusItem() {
        showMainWindow()
        store.scan()
    }

    @objc
    private func showSettingsWindow() {
        if let settingsWindow {
            settingsWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 640, height: 440),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = L10n.text(.settings, language: resolvedLanguage)
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: SettingsView())
        window.center()
        window.makeKeyAndOrderFront(nil)
        settingsWindow = window
        NSApp.activate(ignoringOtherApps: true)
    }

    private var resolvedLanguage: ResolvedLanguage {
        AppLanguage(storedRawValue: UserDefaults.standard.string(forKey: AppLanguage.storageKey)).resolved()
    }

    private func updateLocalizedChrome() {
        let language = resolvedLanguage
        settingsMenuItem?.title = "\(L10n.text(.settings, language: language))..."
        quitMenuItem?.title = L10n.text(.quitCleanMac, language: language)
        statusMenuScanItem?.title = L10n.text(.scan, language: language)
        statusMenuShowItem?.title = "CleanMac"
        statusMenuSettingsItem?.title = L10n.text(.settings, language: language)
        statusMenuQuitItem?.title = L10n.text(.quitCleanMac, language: language)
        settingsWindow?.title = L10n.text(.settings, language: language)
        editMenu?.title = L10n.text(.edit, language: language)
        editUndoItem?.title = L10n.text(.undo, language: language)
        editRedoItem?.title = L10n.text(.redo, language: language)
        editCutItem?.title = L10n.text(.cut, language: language)
        editCopyItem?.title = L10n.text(.copy, language: language)
        editPasteItem?.title = L10n.text(.paste, language: language)
        editSelectAllItem?.title = L10n.text(.selectAll, language: language)
        cleanerMenu?.title = L10n.text(.cleaner, language: language)
        cleanerScanItem?.title = L10n.text(.scan, language: language)
        cleanerSelectAllItem?.title = L10n.text(.selectAllCandidates, language: language)
        cleanerClearItem?.title = L10n.text(.clearSelection, language: language)
        cleanerAskAIItem?.title = L10n.text(.askAI, language: language)
    }

    @objc
    private func userDefaultsDidChange(_ notification: Notification) {
        updateLocalizedChrome()
        store.updateDefaultAIQuestionIfNeeded(language: resolvedLanguage)
    }
}
