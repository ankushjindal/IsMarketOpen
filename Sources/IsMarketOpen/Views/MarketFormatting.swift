import Foundation

enum MarketFormatting {
    static func clock(_ date: Date, timeZone: TimeZone, preference: ClockFormatPreference, includeDay: Bool = false) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.dateFormat = timePattern(preference: preference, includeDay: includeDay)
        return formatter.string(from: date)
    }

    static func sessionRange(_ interval: SessionInterval, market: MarketDefinition, preference: ClockFormatPreference) -> String {
        let start = clock(interval.start, timeZone: market.timeZone, preference: preference)
        let end = clock(interval.end, timeZone: market.timeZone, preference: preference)
        return "\(start)–\(end)"
    }

    static func transitionText(for snapshot: MarketSnapshot, now: Date, preference: ClockFormatPreference, compact: Bool = false) -> String {
        if snapshot.state == .calendarOutdated {
            return "Calendar needs an update"
        }
        if snapshot.state == .alwaysOpen {
            return "Trading continuously"
        }
        if let exception = snapshot.currentException, exception.isFullClosure, snapshot.nextTransition == nil {
            return exception.name
        }
        guard let transition = snapshot.nextTransition, let kind = snapshot.transitionKind else {
            return snapshot.activeBreak == nil ? "No upcoming session" : "Daily break"
        }

        let verb = kind == .opens ? "opens" : "closes"
        let interval = max(0, transition.timeIntervalSince(now))
        if interval < 24 * 60 * 60 {
            return "\(verb.capitalized) in \(relativeDuration(interval))"
        }

        let exact = clock(transition, timeZone: .current, preference: preference, includeDay: true)
        if compact {
            return "\(verb.capitalized) \(exact)"
        }
        return "\(verb.capitalized) \(exact) · in \(relativeDuration(interval))"
    }

    static func menuBarText(for snapshot: MarketSnapshot, now: Date, preference: ClockFormatPreference) -> String {
        if snapshot.state == .calendarOutdated {
            return "\(snapshot.market.shortName) calendar outdated"
        }
        if snapshot.state == .alwaysOpen {
            return "\(snapshot.market.shortName) open 24/7"
        }
        if let exception = snapshot.currentException, exception.isFullClosure {
            return "\(snapshot.market.shortName) closed · \(exception.name)"
        }
        return "\(snapshot.market.shortName) \(transitionText(for: snapshot, now: now, preference: preference, compact: true).lowercased())"
    }

    static func headlineStateLabel(for snapshot: MarketSnapshot) -> String {
        guard snapshot.state == .open, snapshot.market.usesElectronicSessionForHeadline else {
            return snapshot.state.label
        }
        return snapshot.primarySession?.kind == .globex ? "OPEN · GLOBEX" : "OPEN · REGULAR"
    }

    static func regularSessionText(for snapshot: MarketSnapshot, now: Date) -> String? {
        guard snapshot.market.usesElectronicSessionForHeadline else { return nil }
        if snapshot.activeSecondarySessions.contains(where: { $0.kind == .regular }) {
            return "Regular session active"
        }
        guard snapshot.primarySession?.kind == .globex,
              let nextRegular = snapshot.upcomingSessions.first(where: { $0.kind == .regular })
        else { return nil }
        return "Regular opens in \(relativeDuration(nextRegular.start.timeIntervalSince(now)))"
    }

    static func relativeDuration(_ interval: TimeInterval) -> String {
        let totalMinutes = max(0, Int(interval / 60))
        let days = totalMinutes / (24 * 60)
        let hours = (totalMinutes % (24 * 60)) / 60
        let minutes = totalMinutes % 60
        if days > 0 {
            return hours > 0 ? "\(days)d \(hours)h" : "\(days)d"
        }
        if hours > 0 {
            return minutes > 0 ? "\(hours)h \(minutes)m" : "\(hours)h"
        }
        return "\(minutes)m"
    }

    static func shortDate(_ date: Date, timeZone: TimeZone = .current) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = timeZone
        formatter.setLocalizedDateFormatFromTemplate("EEE d MMM")
        return formatter.string(from: date)
    }

    static func fullDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    static func stateColor(_ snapshot: MarketSnapshot) -> String {
        switch snapshot.state {
        case .open, .alwaysOpen: "green"
        case .closed: snapshot.isTransitionSoon ? "orange" : "secondary"
        case .calendarOutdated: "orange"
        }
    }

    private static func timePattern(preference: ClockFormatPreference, includeDay: Bool) -> String {
        let time: String
        switch preference {
        case .system:
            time = DateFormatter.dateFormat(fromTemplate: "j:mm", options: 0, locale: .current) ?? "h:mm a"
        case .twelveHour:
            time = "h:mm a"
        case .twentyFourHour:
            time = "HH:mm"
        }
        return includeDay ? "EEE \(time)" : time
    }
}
