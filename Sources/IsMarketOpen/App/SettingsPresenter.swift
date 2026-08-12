import AppKit

enum SettingsPresenter {
    /// Brings the Settings window forward and dismisses the menu-bar panel.
    /// Callers open Settings through the `openSettings` environment action first;
    /// the private `showSettingsWindow:` selector no longer exists on macOS 14+.
    @MainActor
    static func finishOpening() {
        let panels = NSApp.windows.filter(isMenuBarPanel)
        NSApp.activate(ignoringOtherApps: true)

        // Order out on the next main-queue turn so the Settings window is up first.
        Task { @MainActor in
            for panel in panels {
                panel.orderOut(nil)
            }
        }
    }

    @MainActor
    private static func isMenuBarPanel(_ window: NSWindow) -> Bool {
        guard window.isVisible else { return false }

        let className = NSStringFromClass(type(of: window))
        if className.contains("NSStatusBarWindow") { return false }
        if className.contains("MenuBarExtra") { return true }

        return window is NSPanel
            && window.styleMask.contains(.nonactivatingPanel)
            && window.title.isEmpty
    }
}
