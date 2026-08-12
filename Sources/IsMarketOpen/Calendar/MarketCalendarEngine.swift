import Foundation

struct MarketCalendarEngine: Sendable {
    private let dayKeyFormatter: DateFormatter

    init() {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        dayKeyFormatter = formatter
    }

    func snapshot(
        for market: MarketDefinition,
        at now: Date,
        soonThreshold: TimeInterval = 30 * 60,
        lastSuccessfulRefresh: Date? = nil
    ) -> MarketSnapshot {
        if market.isAlwaysOpen {
            return MarketSnapshot(
                market: market,
                state: .alwaysOpen,
                primarySession: nil,
                activeSecondarySessions: [],
                activeBreak: nil,
                nextTransition: nil,
                transitionKind: nil,
                isTransitionSoon: false,
                currentException: exception(for: market, on: now),
                todaySessions: [],
                upcomingSessions: [],
                calendarIsStale: isStale(market: market, now: now, lastRefresh: lastSuccessfulRefresh)
            )
        }

        let intervals = sessionIntervals(for: market, around: now, forwardDays: 15)
        let activeRegular = intervals.first { $0.kind.isPrimary && $0.start <= now && now < $0.end }
        let activeElectronic = intervals.first { $0.kind == .globex && $0.start <= now && now < $0.end }
        let primary = market.usesElectronicSessionForHeadline
            ? (activeElectronic ?? activeRegular)
            : activeRegular
        let secondary = intervals.filter {
            $0.id != primary?.id && $0.kind != .maintenanceBreak && $0.start <= now && now < $0.end
        }
        let activeBreak = intervals.first {
            $0.kind == .maintenanceBreak && $0.start <= now && now < $0.end
        }
        let nextPrimary = intervals.first {
            let isHeadlineSession = $0.kind.isPrimary || (market.usesElectronicSessionForHeadline && $0.kind == .globex)
            return isHeadlineSession && $0.start > now
        }
        let calendarOutdated = isCoverageExpired(market: market, now: now)

        let transition: Date?
        let transitionKind: TransitionKind?
        if let primary {
            transition = primary.end
            transitionKind = .closes
        } else {
            transition = nextPrimary?.start
            transitionKind = .opens
        }

        let localCalendar = calendar(in: market.timeZone)
        let todayStart = localCalendar.startOfDay(for: now)
        let tomorrowStart = localCalendar.date(byAdding: .day, value: 1, to: todayStart)!
        let todaySessions = intervals.filter { $0.start >= todayStart && $0.start < tomorrowStart }

        return MarketSnapshot(
            market: market,
            state: calendarOutdated ? .calendarOutdated : (primary == nil ? .closed : .open),
            primarySession: primary,
            activeSecondarySessions: secondary,
            activeBreak: activeBreak,
            nextTransition: transition,
            transitionKind: transitionKind,
            isTransitionSoon: transition.map { $0.timeIntervalSince(now) <= soonThreshold } ?? false,
            currentException: exception(for: market, on: now),
            todaySessions: todaySessions,
            upcomingSessions: intervals.filter { $0.start > now }.prefix(12).map { $0 },
            calendarIsStale: isStale(market: market, now: now, lastRefresh: lastSuccessfulRefresh)
        )
    }

    func sessionIntervals(for market: MarketDefinition, around now: Date, forwardDays: Int) -> [SessionInterval] {
        let marketCalendar = calendar(in: market.timeZone)
        let startOfToday = marketCalendar.startOfDay(for: now)
        let exceptions = Dictionary(uniqueKeysWithValues: market.exceptions.map { ($0.date, $0) })
        var intervals: [SessionInterval] = []

        for offset in -1...forwardDays {
            guard let day = marketCalendar.date(byAdding: .day, value: offset, to: startOfToday) else { continue }
            let key = dayKey(for: day, in: market.timeZone)
            let exception = exceptions[key]
            let weekday = marketCalendar.component(.weekday, from: day)
            let rules = exception?.sessions ?? market.sessions.filter { $0.weekdays.contains(weekday) }

            for rule in rules {
                guard let start = date(on: day, minute: rule.startMinute, calendar: marketCalendar) else { continue }
                let resolvedEndMinute = resolveEndMinute(for: rule, at: start)
                var endDay = day
                if resolvedEndMinute <= rule.startMinute {
                    endDay = marketCalendar.date(byAdding: .day, value: 1, to: day) ?? day
                }
                guard let end = date(on: endDay, minute: resolvedEndMinute, calendar: marketCalendar) else { continue }
                intervals.append(
                    SessionInterval(
                        marketID: market.id,
                        kind: rule.kind,
                        start: start,
                        end: end,
                        exceptionName: exception?.name,
                        note: exception?.note
                    )
                )
            }
        }
        return intervals.sorted { $0.start < $1.start }
    }

    func dayKey(for date: Date, in timeZone: TimeZone) -> String {
        dayKeyFormatter.timeZone = timeZone
        return dayKeyFormatter.string(from: date)
    }

    func exception(for market: MarketDefinition, on date: Date) -> MarketException? {
        let key = dayKey(for: date, in: market.timeZone)
        return market.exceptions.first { $0.date == key }
    }

    func upcomingExceptions(for markets: [MarketDefinition], at now: Date, days: Int = 7) -> [UpcomingException] {
        struct GroupKey: Hashable {
            let date: String
            let title: String
            let isFullClosure: Bool
        }

        var grouped: [GroupKey: (date: Date, names: Set<String>)] = [:]
        for market in markets where !market.isAlwaysOpen {
            let marketCalendar = calendar(in: market.timeZone)
            let today = marketCalendar.startOfDay(for: now)
            for exception in market.exceptions {
                guard let exceptionDate = parseDayKey(exception.date, in: market.timeZone),
                      exceptionDate >= today,
                      exceptionDate < marketCalendar.date(byAdding: .day, value: days, to: today)!
                else { continue }
                let key = GroupKey(date: exception.date, title: exception.name, isFullClosure: exception.isFullClosure)
                var value = grouped[key] ?? (exceptionDate, [])
                value.names.insert(market.shortName)
                grouped[key] = value
            }
        }

        return grouped.map { key, value in
            UpcomingException(
                date: value.date,
                dateKey: key.date,
                title: key.title,
                marketNames: value.names.sorted(),
                isFullClosure: key.isFullClosure
            )
        }.sorted { $0.date < $1.date }
    }

    private func resolveEndMinute(for rule: SessionRule, at start: Date) -> Int {
        guard let dstMinute = rule.endMinuteWhenReferenceIsDST,
              let zoneID = rule.daylightReferenceTimeZoneID,
              let referenceZone = TimeZone(identifier: zoneID),
              referenceZone.daylightSavingTimeOffset(for: start) > 0
        else { return rule.endMinute }
        return dstMinute
    }

    private func isCoverageExpired(market: MarketDefinition, now: Date) -> Bool {
        guard let endDay = parseDayKey(market.verifiedThrough, in: market.timeZone) else { return true }
        let marketCalendar = calendar(in: market.timeZone)
        let endExclusive = marketCalendar.date(byAdding: .day, value: 1, to: endDay) ?? endDay
        return now >= endExclusive
    }

    private func isStale(market: MarketDefinition, now: Date, lastRefresh: Date?) -> Bool {
        let reference = max(market.verifiedAt, lastRefresh ?? .distantPast)
        return now.timeIntervalSince(reference) > 30 * 24 * 60 * 60
    }

    private func parseDayKey(_ value: String, in timeZone: TimeZone) -> Date? {
        dayKeyFormatter.timeZone = timeZone
        return dayKeyFormatter.date(from: value)
    }

    private func date(on day: Date, minute: Int, calendar: Calendar) -> Date? {
        calendar.date(
            bySettingHour: minute / 60,
            minute: minute % 60,
            second: 0,
            of: day
        )
    }

    private func calendar(in timeZone: TimeZone) -> Calendar {
        var result = Calendar(identifier: .gregorian)
        result.locale = Locale(identifier: "en_US_POSIX")
        result.timeZone = timeZone
        return result
    }
}
