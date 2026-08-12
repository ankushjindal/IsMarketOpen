import SwiftUI
import ServiceManagement

@main
struct IsMarketOpenPreviewApp: App {
    @State private var model = AppModel()

    init() {
        // Clean up any preview login item left by an earlier QA build.
        try? SMAppService.mainApp.unregister()
    }

    var body: some Scene {
        WindowGroup("Is Market Open? Preview") {
            MarketPopoverView()
                .environment(model)
        }
        .defaultSize(width: 420, height: 650)
    }
}
