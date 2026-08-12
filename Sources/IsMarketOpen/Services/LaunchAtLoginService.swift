import Foundation
import ServiceManagement

@MainActor
enum LaunchAtLoginService {
    static var isEnabled: Bool {
#if ISMARKETOPEN_PREVIEW
        false
#else
        SMAppService.mainApp.status == .enabled
#endif
    }

    static func setEnabled(_ enabled: Bool) throws {
#if ISMARKETOPEN_PREVIEW
        // Visual-QA builds must never persist themselves as login items.
        return
#else
        if enabled {
            if SMAppService.mainApp.status != .enabled {
                try SMAppService.mainApp.register()
            }
        } else if SMAppService.mainApp.status == .enabled {
            try SMAppService.mainApp.unregister()
        }
#endif
    }
}
