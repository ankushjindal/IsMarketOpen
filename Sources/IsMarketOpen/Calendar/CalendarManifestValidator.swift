import Foundation

enum CalendarManifestValidator {
    enum ValidationError: LocalizedError, Equatable {
        case invalid(String)

        var errorDescription: String? {
            switch self {
            case let .invalid(message): message
            }
        }
    }

    static func validate(
        _ manifest: CalendarManifest,
        knownMarketIDs: Set<String>,
        minimumCoverageDays: Int = 21
    ) throws {
        guard manifest.schemaVersion == 1 else {
            throw ValidationError.invalid("Unsupported calendar schema version \(manifest.schemaVersion).")
        }
        guard !manifest.calendars.isEmpty else {
            throw ValidationError.invalid("The calendar manifest has no market overlays.")
        }

        let calendar = utcCalendar()
        let generatedDay = calendar.startOfDay(for: manifest.generatedAt)
        let minimumCoverageDay = calendar.date(byAdding: .day, value: minimumCoverageDays, to: generatedDay)!
        var coveredMarketIDs = Set<String>()

        for overlay in manifest.calendars {
            guard !overlay.marketIDs.isEmpty else {
                throw ValidationError.invalid("A calendar overlay has no market IDs.")
            }
            guard overlay.verifiedAt <= manifest.generatedAt.addingTimeInterval(24 * 60 * 60) else {
                throw ValidationError.invalid("An overlay is verified after the manifest was generated.")
            }
            guard let verifiedThrough = parseDay(overlay.verifiedThrough), verifiedThrough >= minimumCoverageDay else {
                throw ValidationError.invalid(
                    "Calendar coverage for \(overlay.marketIDs.joined(separator: ", ")) must extend at least \(minimumCoverageDays) days beyond generation."
                )
            }
            guard !overlay.sources.isEmpty else {
                throw ValidationError.invalid("Calendar coverage for \(overlay.marketIDs.joined(separator: ", ")) has no official source.")
            }

            for source in overlay.sources {
                guard source.url.scheme == "https", source.url.host != nil else {
                    throw ValidationError.invalid("Calendar source \(source.name) must use an absolute HTTPS URL.")
                }
            }

            for marketID in overlay.marketIDs {
                guard knownMarketIDs.contains(marketID) else {
                    throw ValidationError.invalid("Unknown market ID: \(marketID).")
                }
                guard coveredMarketIDs.insert(marketID).inserted else {
                    throw ValidationError.invalid("Market ID \(marketID) appears in more than one overlay.")
                }
            }

            var exceptionDates = Set<String>()
            for exception in overlay.exceptions {
                guard let exceptionDay = parseDay(exception.date) else {
                    throw ValidationError.invalid("Invalid exception date: \(exception.date).")
                }
                guard exceptionDay <= verifiedThrough else {
                    throw ValidationError.invalid("Exception \(exception.date) is beyond verified coverage.")
                }
                guard exceptionDates.insert(exception.date).inserted else {
                    throw ValidationError.invalid("Duplicate exception date \(exception.date) in one overlay.")
                }
                for session in exception.sessions {
                    guard (0..<24 * 60).contains(session.startMinute),
                          (0..<24 * 60).contains(session.endMinute),
                          session.startMinute != session.endMinute
                    else {
                        throw ValidationError.invalid("Invalid session minutes on \(exception.date).")
                    }
                    guard session.weekdays.allSatisfy({ (1...7).contains($0) }) else {
                        throw ValidationError.invalid("Invalid weekday on \(exception.date).")
                    }
                }
            }
        }

        let missing = knownMarketIDs.subtracting(coveredMarketIDs)
        guard missing.isEmpty else {
            throw ValidationError.invalid("Manifest is missing markets: \(missing.sorted().joined(separator: ", ")).")
        }
    }

    private static func parseDay(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = utcCalendar()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.isLenient = false
        return formatter.date(from: value)
    }

    private static func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}
