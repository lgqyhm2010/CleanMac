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
        delegate.configureMainMenu()
        app.finishLaunching()
        DispatchQueue.main.async {
            delegate.showMainWindow()
        }
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
    private var statusCancellables: Set<AnyCancellable> = []
    private lazy var store = CleaningStore(language: resolvedLanguage)

    func applicationDidFinishLaunching(_ notification: Notification) {
        showMainWindow()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow()
        }
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

    func showMainWindow() {
        if let mainWindow {
            mainWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1_120, height: 760),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "CleanMac"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(
            rootView: ContentView(store: store)
                .frame(minWidth: 980, minHeight: 640)
        )
        window.minSize = NSSize(width: 980, height: 640)
        window.contentMinSize = NSSize(width: 980, height: 640)
        window.setContentSize(NSSize(width: 1_120, height: 760))
        window.center()
        window.makeKeyAndOrderFront(nil)
        mainWindow = window
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

        Publishers.CombineLatest4(store.$status, store.$candidates, store.$isScanning, store.$isScanningApplications)
            .receive(on: RunLoop.main)
            .sink { [weak self] status, candidates, isScanning, isScanningApplications in
                Task { @MainActor [weak self] in
                    self?.updateStatusItem(
                        status: status,
                        candidateCount: candidates.count,
                        isScanning: isScanning || isScanningApplications
                    )
                }
            }
            .store(in: &statusCancellables)
    }

    private func updateStatusItem(status: CleaningStatus, candidateCount: Int, isScanning: Bool) {
        let title = MenuBarMonitorSummary.title(
            status: status,
            candidateCount: candidateCount,
            isScanning: isScanning
        )
        statusItem?.button?.title = title
        statusMenuStatusItem?.title = title
        statusMenuScanItem?.isEnabled = !isScanning
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
    }

    @objc
    private func userDefaultsDidChange(_ notification: Notification) {
        updateLocalizedChrome()
        store.updateDefaultAIQuestionIfNeeded(language: resolvedLanguage)
    }
}
