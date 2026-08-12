import SwiftUI

#if !ISMARKETOPEN_PREVIEW
@main
struct IsMarketOpenApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        MenuBarExtra {
            MarketPopoverView()
                .environment(model)
        } label: {
            MenuBarStatusLabel()
                .environment(model)
        }
        .menuBarExtraStyle(.window)
        .commands {
            CommandGroup(replacing: .appSettings) {
                Button("Settings…") {
                    SettingsPresenter.openClosingMenuBar()
                }
                .keyboardShortcut(",", modifiers: .command)
            }
        }

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
#endif
