import AppKit

enum SettingsPresenter {
    /// Opens the Settings window and dismisses the menu-bar panel if it is open.
    @MainActor
    static func openClosingMenuBar() {
        let popoverWindows = NSApp.windows.filter(isMenuBarPopoverWindow)

        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        NSApp.activate(ignoringOtherApps: true)

        for window in popoverWindows {
            window.orderOut(nil)
        }
    }

    @MainActor
    private static func isMenuBarPopoverWindow(_ window: NSWindow) -> Bool {
        guard window.isVisible else { return false }

        let className = NSStringFromClass(type(of: window))
        if className.contains("NSStatusBarWindow") { return false }

        // Window-style MenuBarExtra content is a fixed 420pt panel while open.
        if abs(window.frame.width - 420) < 2 {
            return true
        }

        // Fallback: key, untitled utility panel that is currently frontmost.
        return window.isKeyWindow && window.title.isEmpty && window.styleMask.contains(.nonactivatingPanel)
    }
}
