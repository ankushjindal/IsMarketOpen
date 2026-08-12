import Foundation

enum BundledCalendar {
    static let generatedAt = isoDate("2026-08-12T00:00:00Z")
    static let verifiedAt = isoDate("2026-08-12T00:00:00Z")

    static let manifest = CalendarManifest(
        schemaVersion: 1,
        generatedAt: generatedAt,
        calendars: [
            MarketCalendarOverlay(
                marketIDs: ["us-stocks"],
                verifiedAt: verifiedAt,
                verifiedThrough: "2026-12-31",
                sources: [source("NYSE", "https://www.nyse.com/markets/hours-calendars"), source("Nasdaq", "https://www.nasdaqtrader.com/trader.aspx?id=calendar")],
                exceptions: usEquityExceptions
            ),
            MarketCalendarOverlay(
                marketIDs: ["india-stocks", "nse-fo"],
                verifiedAt: verifiedAt,
                verifiedThrough: "2026-12-31",
                sources: [source("NSE", "https://www.nseindia.com/resources/exchange-communication-holidays"), source("BSE", "https://www.bseindia.com/static/markets/marketinfo/listholi")],
                exceptions: indiaEquityExceptions
            ),
            MarketCalendarOverlay(
                marketIDs: ["mcx"],
                verifiedAt: verifiedAt,
                verifiedThrough: "2026-12-31",
                sources: [source("MCX", "https://www.mcxindia.com/market-operations/trading-surveillance/trading-holidays")],
                exceptions: mcxExceptions
            ),
            MarketCalendarOverlay(
                marketIDs: futuresMarketIDs,
                verifiedAt: verifiedAt,
                // CME finalizes product-specific holiday schedules close to each
                // holiday. Stop before Labor Day instead of inventing hours;
                // the public manifest can move this rolling horizon without
                // requiring a new application release.
                verifiedThrough: "2026-09-06",
                sources: [source("CME Group", "https://www.cmegroup.com/trading-hours.html")],
                exceptions: []
            ),
            MarketCalendarOverlay(
                marketIDs: ["crypto"],
                verifiedAt: verifiedAt,
                verifiedThrough: "2030-12-31",
                sources: [source("Binance", "https://www.binance.com/en")],
                exceptions: []
            ),
        ]
    )

    private static let futuresMarketIDs = [
        "es", "nq", "rty", "emd", "ym",
        "zb", "zn", "zf", "zt", "zc", "zs", "zw",
        "cl", "ng", "ho", "rb", "gc", "si", "hg", "pl",
    ]

    private static let usEquityExceptions: [MarketException] = {
        let closures = [
            ("2026-01-01", "New Year's Day"),
            ("2026-01-19", "Martin Luther King Jr. Day"),
            ("2026-02-16", "Washington's Birthday"),
            ("2026-04-03", "Good Friday"),
            ("2026-05-25", "Memorial Day"),
            ("2026-06-19", "Juneteenth"),
            ("2026-07-03", "Independence Day (observed)"),
            ("2026-09-07", "Labor Day"),
            ("2026-11-26", "Thanksgiving Day"),
            ("2026-12-25", "Christmas Day"),
        ].map { MarketException(date: $0.0, name: $0.1, sessions: [], note: nil) }

        let earlyCloseSessions = [
            SessionRule(startMinute: 4 * 60, endMinute: 9 * 60 + 30, kind: .preMarket),
            SessionRule(startMinute: 9 * 60 + 30, endMinute: 13 * 60, kind: .regular),
            SessionRule(startMinute: 13 * 60, endMinute: 17 * 60, kind: .postMarket),
        ]
        let earlyCloses = [
            MarketException(date: "2026-11-27", name: "Day after Thanksgiving", sessions: earlyCloseSessions, note: "Regular session closes at 1:00 PM ET"),
            MarketException(date: "2026-12-24", name: "Christmas Eve", sessions: earlyCloseSessions, note: "Regular session closes at 1:00 PM ET"),
        ]
        return closures + earlyCloses
    }()

    private static let indiaEquityExceptions: [MarketException] = {
        let closures = [
            ("2026-01-15", "Maharashtra municipal election"),
            ("2026-01-26", "Republic Day"),
            ("2026-03-03", "Holi"),
            ("2026-03-26", "Shri Ram Navami"),
            ("2026-03-31", "Shri Mahavir Jayanti"),
            ("2026-04-03", "Good Friday"),
            ("2026-04-14", "Dr. Babasaheb Ambedkar Jayanti"),
            ("2026-05-01", "Maharashtra Day"),
            ("2026-05-28", "Bakri Id"),
            ("2026-06-26", "Muharram"),
            ("2026-09-14", "Ganesh Chaturthi"),
            ("2026-10-02", "Mahatma Gandhi Jayanti"),
            ("2026-10-20", "Dussehra"),
            ("2026-11-10", "Diwali Balipratipada"),
            ("2026-11-24", "Guru Nanak Jayanti"),
            ("2026-12-25", "Christmas"),
        ].map { MarketException(date: $0.0, name: $0.1, sessions: [], note: nil) }

        return closures + [
            MarketException(
                date: "2026-11-08",
                name: "Diwali Laxmi Pujan",
                sessions: [],
                note: "Muhurat trading is planned; session time has not yet been announced"
            ),
        ]
    }()

    private static let mcxExceptions: [MarketException] = {
        let fullClosures = [
            ("2026-01-26", "Republic Day"),
            ("2026-04-03", "Good Friday"),
            ("2026-10-02", "Mahatma Gandhi Jayanti"),
            ("2026-12-25", "Christmas"),
        ].map { MarketException(date: $0.0, name: $0.1, sessions: [], note: nil) }

        let eveningOnly = [
            ("2026-03-03", "Holi"),
            ("2026-03-26", "Shri Ram Navami"),
            ("2026-03-31", "Shri Mahavir Jayanti"),
            ("2026-04-14", "Dr. Babasaheb Ambedkar Jayanti"),
            ("2026-05-01", "Maharashtra Day"),
            ("2026-05-28", "Bakri Id"),
            ("2026-06-26", "Muharram"),
            ("2026-09-14", "Ganesh Chaturthi"),
            ("2026-10-20", "Dussehra"),
            ("2026-11-10", "Diwali Balipratipada"),
            ("2026-11-24", "Guru Nanak Jayanti"),
        ].map {
            MarketException(
                date: $0.0,
                name: $0.1,
                sessions: [SessionRule(startMinute: 17 * 60, endMinute: 23 * 60 + 30, kind: .evening)],
                note: "Morning session closed; evening session open"
            )
        }

        return fullClosures + eveningOnly + [
            MarketException(
                date: "2026-01-01",
                name: "New Year's Day",
                sessions: [SessionRule(startMinute: 9 * 60, endMinute: 17 * 60, kind: .regular)],
                note: "Evening session closed"
            ),
            MarketException(
                date: "2026-11-08",
                name: "Diwali Laxmi Pujan",
                sessions: [],
                note: "Muhurat trading is planned; session time has not yet been announced"
            ),
        ]
    }()

    private static func source(_ name: String, _ url: String) -> MarketSource {
        MarketSource(name: name, url: URL(string: url)!)
    }

    private static func isoDate(_ value: String) -> Date {
        ISO8601DateFormatter().date(from: value)!
    }
}
