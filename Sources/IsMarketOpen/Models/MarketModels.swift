import Foundation

enum MarketRegion: String, CaseIterable, Sendable {
    case us = "US"
    case india = "India"
    case crypto = "Crypto"
}

enum SessionKind: String, Codable, Sendable, CaseIterable {
    case preMarket
    case regular
    case postMarket
    case globex
    case maintenanceBreak
    case evening
    case special

    var label: String {
        switch self {
        case .preMarket: "Pre-market"
        case .regular: "Regular"
        case .postMarket: "After-hours"
        case .globex: "Globex"
        case .maintenanceBreak: "Daily break"
        case .evening: "Evening session"
        case .special: "Special session"
        }
    }

    var isPrimary: Bool {
        self == .regular || self == .evening || self == .special
    }
}

struct SessionRule: Codable, Hashable, Sendable {
    /// Foundation weekday numbers: Sunday = 1 ... Saturday = 7.
    let weekdays: Set<Int>
    let startMinute: Int
    let endMinute: Int
    let kind: SessionKind
    let endMinuteWhenReferenceIsDST: Int?
    let daylightReferenceTimeZoneID: String?

    init(
        weekdays: Set<Int>,
        startHour: Int,
        startMinute: Int = 0,
        endHour: Int,
        endMinute: Int = 0,
        kind: SessionKind,
        endHourWhenReferenceIsDST: Int? = nil,
        endMinuteWhenReferenceIsDST: Int = 0,
        daylightReferenceTimeZoneID: String? = nil
    ) {
        self.weekdays = weekdays
        self.startMinute = startHour * 60 + startMinute
        self.endMinute = endHour * 60 + endMinute
        self.kind = kind
        self.endMinuteWhenReferenceIsDST = endHourWhenReferenceIsDST.map {
            $0 * 60 + endMinuteWhenReferenceIsDST
        }
        self.daylightReferenceTimeZoneID = daylightReferenceTimeZoneID
    }

    init(
        weekdays: Set<Int> = [],
        startMinute: Int,
        endMinute: Int,
        kind: SessionKind,
        endMinuteWhenReferenceIsDST: Int? = nil,
        daylightReferenceTimeZoneID: String? = nil
    ) {
        self.weekdays = weekdays
        self.startMinute = startMinute
        self.endMinute = endMinute
        self.kind = kind
        self.endMinuteWhenReferenceIsDST = endMinuteWhenReferenceIsDST
        self.daylightReferenceTimeZoneID = daylightReferenceTimeZoneID
    }
}

struct MarketException: Codable, Hashable, Sendable {
    let date: String
    let name: String
    let sessions: [SessionRule]
    let note: String?

    var isFullClosure: Bool { sessions.isEmpty }
}

struct MarketSource: Codable, Hashable, Sendable {
    let name: String
    let url: URL
}

struct MarketDefinition: Identifiable, Hashable, Sendable {
    let id: String
    let displayName: String
    let shortName: String
    let cityName: String
    let timeZoneID: String
    let region: MarketRegion
    let sessions: [SessionRule]
    let isAlwaysOpen: Bool
    let usesElectronicSessionForHeadline: Bool
    var exceptions: [MarketException]
    var sources: [MarketSource]
    var verifiedAt: Date
    var verifiedThrough: String

    var timeZone: TimeZone {
        TimeZone(identifier: timeZoneID) ?? .gmt
    }
}

enum MarketRowDefinition: Identifiable, Hashable, Sendable {
    case single(id: String, marketID: String)
    case group(id: String, title: String, marketIDs: [String])

    var id: String {
        switch self {
        case let .single(id, _), let .group(id, _, _): id
        }
    }

    var title: String {
        switch self {
        case .single: ""
        case let .group(_, title, _): title
        }
    }

    var marketIDs: [String] {
        switch self {
        case let .single(_, marketID): [marketID]
        case let .group(_, _, marketIDs): marketIDs
        }
    }
}

struct MarketSectionDefinition: Identifiable, Hashable, Sendable {
    let region: MarketRegion
    let rows: [MarketRowDefinition]
    var id: String { region.rawValue }
}

struct SessionInterval: Identifiable, Hashable, Sendable {
    let marketID: String
    let kind: SessionKind
    let start: Date
    let end: Date
    let exceptionName: String?
    let note: String?

    var id: String {
        "\(marketID)-\(kind.rawValue)-\(start.timeIntervalSince1970)"
    }
}

enum MarketHeadlineState: String, Sendable {
    case open
    case closed
    case alwaysOpen
    case calendarOutdated

    var label: String {
        switch self {
        case .open: "OPEN"
        case .closed: "CLOSED"
        case .alwaysOpen: "OPEN 24/7"
        case .calendarOutdated: "CALENDAR OUTDATED"
        }
    }
}

enum TransitionKind: Sendable {
    case opens
    case closes
}

struct MarketSnapshot: Identifiable, Sendable {
    let market: MarketDefinition
    let state: MarketHeadlineState
    let primarySession: SessionInterval?
    let activeSecondarySessions: [SessionInterval]
    let activeBreak: SessionInterval?
    let nextTransition: Date?
    let transitionKind: TransitionKind?
    let isTransitionSoon: Bool
    let currentException: MarketException?
    let todaySessions: [SessionInterval]
    let upcomingSessions: [SessionInterval]
    let calendarIsStale: Bool

    var id: String { market.id }
}

struct UpcomingException: Identifiable, Sendable {
    let date: Date
    let dateKey: String
    let title: String
    let marketNames: [String]
    let isFullClosure: Bool

    var id: String { "\(dateKey)-\(title)-\(marketNames.joined())" }
}

enum MarketIconState: Sendable {
    case open
    case closed
    case soon
    case warning

    var systemImage: String {
        switch self {
        case .open: "building.columns.fill"
        case .closed: "building.columns"
        case .soon: "clock.badge"
        case .warning: "exclamationmark.triangle.fill"
        }
    }
}
