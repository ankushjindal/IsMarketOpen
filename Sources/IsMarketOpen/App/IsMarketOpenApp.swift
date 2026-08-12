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

        Settings {
            SettingsView()
                .environment(model)
        }
    }
}
#endif
