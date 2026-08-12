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

    /// Inside a scheduled pause with no other session running.
    var isPaused: Bool {
        activeBreak != nil && primarySession == nil && activeSecondarySessions.isEmpty
    }

    /// Today runs on exception sessions rather than the normal rules — an early
    /// close, or a partial holiday with only some sessions trading. A full
    /// closure is excluded: there is nothing shortened about a day that is shut.
    var hasModifiedSessionsToday: Bool {
        guard let exception = currentException else { return false }
        return !exception.isFullClosure
    }
}

struct UpcomingException: Identifiable, Sendable {
    let date: Date
    let dateKey: String
    let title: String
    let marketNames: [String]
    let isFullClosure: Bool

    var id: String { "\(dateKey)-\(title)-\(marketNames.joined())" }
}

/// Menu-bar icon states. Deliberately monochrome: menu-bar images are rendered as
/// templates, so shape has to carry the meaning on tinted bars and under
/// Reduce Transparency. Filled glyphs mean the market is trading right now.
enum MarketIconState: Sendable {
    case open
    case openExtended
    case earlyClose
    case closingSoon
    case openingSoon
    case atBreak
    case closed
    case warning

    var systemImage: String {
        switch self {
        case .open: "building.columns.fill"
        case .openExtended: "sun.horizon.fill"
        case .earlyClose: "clock.badge.exclamationmark.fill"
        case .closingSoon: "arrow.down.circle.fill"
        case .openingSoon: "arrow.up.circle"
        case .atBreak: "pause.circle"
        case .closed: "building.columns"
        case .warning: "exclamationmark.triangle.fill"
        }
    }

    /// Whether the glyph is filled, i.e. some session is currently trading.
    var isTrading: Bool {
        switch self {
        case .open, .openExtended, .earlyClose, .closingSoon: true
        case .openingSoon, .atBreak, .closed, .warning: false
        }
    }

    init(snapshot: MarketSnapshot) {
        if snapshot.state == .calendarOutdated || snapshot.calendarIsStale {
            self = .warning
            return
        }

        // A scheduled pause outranks the countdown: "paused, back at 18:00" says
        // more than "opens soon", and the two always coincide near the reopen.
        if snapshot.isPaused {
            self = .atBreak
            return
        }

        if snapshot.isTransitionSoon, let kind = snapshot.transitionKind {
            self = kind == .closes ? .closingSoon : .openingSoon
            return
        }

        if snapshot.state == .open || snapshot.state == .alwaysOpen {
            self = snapshot.hasModifiedSessionsToday ? .earlyClose : .open
            return
        }

        // Headline session is shut, but pre-market/after-hours/Globex is trading.
        self = snapshot.activeSecondarySessions.isEmpty ? .closed : .openExtended
    }
}
