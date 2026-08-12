import Foundation

struct CalendarManifest: Codable, Sendable {
    let schemaVersion: Int
    let generatedAt: Date
    let calendars: [MarketCalendarOverlay]
}

struct MarketCalendarOverlay: Codable, Sendable {
    let marketIDs: [String]
    let verifiedAt: Date
    let verifiedThrough: String
    let sources: [MarketSource]
    let exceptions: [MarketException]
}

enum CalendarLoadOrigin: String, Sendable {
    case bundled = "Bundled calendar"
    case cached = "Downloaded calendar"
    case remote = "Fresh download"
}

struct CalendarLoadState: Sendable {
    var origin: CalendarLoadOrigin
    var generatedAt: Date
    var lastSuccessfulRefresh: Date?
    var lastError: String?
    var isRefreshing: Bool
}
