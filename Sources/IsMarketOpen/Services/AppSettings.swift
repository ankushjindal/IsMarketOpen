import Foundation
import Observation

enum MenuDisplayMode: String, Codable, CaseIterable, Sendable {
    case iconOnly
    case favoriteCountdown

    var label: String {
        switch self {
        case .iconOnly: "Icon only"
        case .favoriteCountdown: "Favorite and countdown"
        }
    }
}

enum ClockFormatPreference: String, Codable, CaseIterable, Sendable {
    case system
    case twelveHour
    case twentyFourHour

    var label: String {
        switch self {
        case .system: "Follow system"
        case .twelveHour: "12-hour"
        case .twentyFourHour: "24-hour"
        }
    }
}

struct CityClockDefinition: Identifiable, Codable, Hashable, Sendable {
    let id: String
    let cityName: String
    let timeZoneID: String
}

enum CityCatalog {
    static let all: [CityClockDefinition] = [
        CityClockDefinition(id: "bengaluru", cityName: "Bengaluru", timeZoneID: "Asia/Kolkata"),
        CityClockDefinition(id: "new-york", cityName: "New York", timeZoneID: "America/New_York"),
        CityClockDefinition(id: "chicago", cityName: "Chicago", timeZoneID: "America/Chicago"),
        CityClockDefinition(id: "london", cityName: "London", timeZoneID: "Europe/London"),
        CityClockDefinition(id: "singapore", cityName: "Singapore", timeZoneID: "Asia/Singapore"),
        CityClockDefinition(id: "hong-kong", cityName: "Hong Kong", timeZoneID: "Asia/Hong_Kong"),
        CityClockDefinition(id: "tokyo", cityName: "Tokyo", timeZoneID: "Asia/Tokyo"),
        CityClockDefinition(id: "sydney", cityName: "Sydney", timeZoneID: "Australia/Sydney"),
        CityClockDefinition(id: "dubai", cityName: "Dubai", timeZoneID: "Asia/Dubai"),
        CityClockDefinition(id: "frankfurt", cityName: "Frankfurt", timeZoneID: "Europe/Berlin"),
        CityClockDefinition(id: "toronto", cityName: "Toronto", timeZoneID: "America/Toronto"),
        CityClockDefinition(id: "san-francisco", cityName: "San Francisco", timeZoneID: "America/Los_Angeles"),
        CityClockDefinition(id: "utc", cityName: "UTC", timeZoneID: "UTC"),
    ]

    static let defaults = ["bengaluru", "new-york", "chicago", "london"]

    static func city(id: String) -> CityClockDefinition? {
        all.first { $0.id == id }
    }
}

@MainActor
@Observable
final class AppSettings {
    private enum Key {
        static let favoriteMarketID = "favoriteMarketID"
        static let menuDisplayMode = "menuDisplayMode"
        static let soonThresholdMinutes = "soonThresholdMinutes"
        static let clockFormat = "clockFormat"
        static let cityIDs = "cityIDs"
        static let hiddenRowIDs = "hiddenRowIDs"
        static let rowOrder = "rowOrder"
        static let completedFirstRun = "completedFirstRun"
        static let worldClocksCollapsed = "worldClocksCollapsed"
    }

    private let defaults: UserDefaults

    var favoriteMarketID: String { didSet { defaults.set(favoriteMarketID, forKey: Key.favoriteMarketID) } }
    var menuDisplayMode: MenuDisplayMode { didSet { defaults.set(menuDisplayMode.rawValue, forKey: Key.menuDisplayMode) } }
    var soonThresholdMinutes: Int { didSet { defaults.set(soonThresholdMinutes, forKey: Key.soonThresholdMinutes) } }
    var clockFormat: ClockFormatPreference { didSet { defaults.set(clockFormat.rawValue, forKey: Key.clockFormat) } }
    var cityIDs: [String] { didSet { defaults.set(cityIDs, forKey: Key.cityIDs) } }
    var hiddenRowIDs: Set<String> { didSet { defaults.set(Array(hiddenRowIDs), forKey: Key.hiddenRowIDs) } }
    var rowOrder: [String] { didSet { defaults.set(rowOrder, forKey: Key.rowOrder) } }
    var completedFirstRun: Bool { didSet { defaults.set(completedFirstRun, forKey: Key.completedFirstRun) } }
    var worldClocksCollapsed: Bool { didSet { defaults.set(worldClocksCollapsed, forKey: Key.worldClocksCollapsed) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        favoriteMarketID = defaults.string(forKey: Key.favoriteMarketID) ?? "us-stocks"
        menuDisplayMode = defaults.string(forKey: Key.menuDisplayMode).flatMap(MenuDisplayMode.init(rawValue:)) ?? .favoriteCountdown
        soonThresholdMinutes = defaults.object(forKey: Key.soonThresholdMinutes) as? Int ?? 30
        clockFormat = defaults.string(forKey: Key.clockFormat).flatMap(ClockFormatPreference.init(rawValue:)) ?? .system
        cityIDs = defaults.stringArray(forKey: Key.cityIDs) ?? CityCatalog.defaults
        hiddenRowIDs = Set(defaults.stringArray(forKey: Key.hiddenRowIDs) ?? [])
        rowOrder = defaults.stringArray(forKey: Key.rowOrder) ?? MarketCatalog.rowOrder
        completedFirstRun = defaults.bool(forKey: Key.completedFirstRun)
        worldClocksCollapsed = defaults.bool(forKey: Key.worldClocksCollapsed)
    }

    func moveRow(_ rowID: String, direction: Int) {
        guard let index = rowOrder.firstIndex(of: rowID) else { return }
        let destination = index + direction
        guard rowOrder.indices.contains(destination) else { return }
        rowOrder.swapAt(index, destination)
    }

    func moveCity(_ cityID: String, direction: Int) {
        guard let index = cityIDs.firstIndex(of: cityID) else { return }
        let destination = index + direction
        guard cityIDs.indices.contains(destination) else { return }
        cityIDs.swapAt(index, destination)
    }
}
