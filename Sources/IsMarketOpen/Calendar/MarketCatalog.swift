import Foundation

enum MarketCatalog {
    static let weekdays: Set<Int> = [2, 3, 4, 5, 6]
    static let sundayThroughThursday: Set<Int> = [1, 2, 3, 4, 5]
    static let mondayThroughThursday: Set<Int> = [2, 3, 4, 5]

    static let rowOrder = [
        "us-stocks",
        "us-index-futures",
        "rates-agriculture",
        "energy",
        "metals",
        "india-stocks",
        "nse-fo",
        "mcx",
        "crypto",
    ]

    static let sections: [MarketSectionDefinition] = [
        MarketSectionDefinition(
            region: .us,
            rows: [
                .single(id: "us-stocks", marketID: "us-stocks"),
                .group(id: "us-index-futures", title: "US Index Futures", marketIDs: ["es", "nq", "rty", "emd", "ym"]),
                .group(id: "rates-agriculture", title: "Rates & Agriculture", marketIDs: ["zb", "zn", "zf", "zt", "zc", "zs", "zw"]),
                .group(id: "energy", title: "Energy", marketIDs: ["cl", "ng", "ho", "rb"]),
                .group(id: "metals", title: "Metals", marketIDs: ["gc", "si", "hg", "pl"]),
            ]
        ),
        MarketSectionDefinition(
            region: .india,
            rows: [
                .single(id: "india-stocks", marketID: "india-stocks"),
                .single(id: "nse-fo", marketID: "nse-fo"),
                .single(id: "mcx", marketID: "mcx"),
            ]
        ),
        MarketSectionDefinition(
            region: .crypto,
            rows: [
                .single(id: "crypto", marketID: "crypto"),
            ]
        ),
    ]

    static var marketIDs: Set<String> {
        Set(baseDefinitions().map(\.id))
    }

    static func definitions(applying manifest: CalendarManifest = BundledCalendar.manifest) -> [String: MarketDefinition] {
        let base = baseDefinitions()
        var indexed = Dictionary(uniqueKeysWithValues: base.map { ($0.id, $0) })

        for overlay in manifest.calendars {
            for marketID in overlay.marketIDs {
                guard var market = indexed[marketID] else { continue }
                market.exceptions = overlay.exceptions
                market.sources = overlay.sources
                market.verifiedAt = overlay.verifiedAt
                market.verifiedThrough = overlay.verifiedThrough
                indexed[marketID] = market
            }
        }
        return indexed
    }

    private static func baseDefinitions() -> [MarketDefinition] {
        let placeholderDate = Date(timeIntervalSince1970: 0)

        func market(
            _ id: String,
            _ name: String,
            shortName: String? = nil,
            city: String,
            timezone: String,
            region: MarketRegion,
            sessions: [SessionRule],
            alwaysOpen: Bool = false,
            usesElectronicSessionForHeadline: Bool = false
        ) -> MarketDefinition {
            MarketDefinition(
                id: id,
                displayName: name,
                shortName: shortName ?? name,
                cityName: city,
                timeZoneID: timezone,
                region: region,
                sessions: sessions,
                isAlwaysOpen: alwaysOpen,
                usesElectronicSessionForHeadline: usesElectronicSessionForHeadline,
                exceptions: [],
                sources: [],
                verifiedAt: placeholderDate,
                verifiedThrough: "1970-01-01"
            )
        }

        let usEquitySessions = [
            SessionRule(weekdays: weekdays, startHour: 4, endHour: 9, endMinute: 30, kind: .preMarket),
            SessionRule(weekdays: weekdays, startHour: 9, startMinute: 30, endHour: 16, kind: .regular),
            SessionRule(weekdays: weekdays, startHour: 16, endHour: 20, kind: .postMarket),
        ]

        let equityFutureSessions = [
            SessionRule(weekdays: sundayThroughThursday, startHour: 18, endHour: 17, kind: .globex),
            SessionRule(weekdays: mondayThroughThursday, startHour: 17, endHour: 18, kind: .maintenanceBreak),
            SessionRule(weekdays: weekdays, startHour: 9, startMinute: 30, endHour: 16, kind: .regular),
        ]

        let energySessions = [
            SessionRule(weekdays: sundayThroughThursday, startHour: 18, endHour: 17, kind: .globex),
            SessionRule(weekdays: mondayThroughThursday, startHour: 17, endHour: 18, kind: .maintenanceBreak),
            SessionRule(weekdays: weekdays, startHour: 9, endHour: 14, endMinute: 30, kind: .regular),
        ]

        // CME publishes one continuous Globex session for Treasury futures,
        // rather than a separate product RTH window. Treat that published
        // session as primary and still expose the daily maintenance break.
        let treasurySessions = [
            SessionRule(weekdays: sundayThroughThursday, startHour: 17, endHour: 16, kind: .regular),
            SessionRule(weekdays: mondayThroughThursday, startHour: 16, endHour: 17, kind: .maintenanceBreak),
        ]

        let agricultureSessions = [
            SessionRule(weekdays: sundayThroughThursday, startHour: 19, endHour: 7, endMinute: 45, kind: .globex),
            SessionRule(weekdays: weekdays, startHour: 7, startMinute: 45, endHour: 8, endMinute: 30, kind: .maintenanceBreak),
            SessionRule(weekdays: weekdays, startHour: 8, startMinute: 30, endHour: 13, endMinute: 20, kind: .regular),
        ]

        func future(_ id: String, _ name: String, sessions: [SessionRule], timezone: String = "America/New_York", city: String = "New York") -> MarketDefinition {
            market(
                id,
                name,
                shortName: id.uppercased(),
                city: city,
                timezone: timezone,
                region: .us,
                sessions: sessions,
                usesElectronicSessionForHeadline: sessions.contains { $0.kind == .globex }
            )
        }

        return [
            market("us-stocks", "US Stocks", city: "New York", timezone: "America/New_York", region: .us, sessions: usEquitySessions),

            future("es", "E-mini S&P 500", sessions: equityFutureSessions),
            future("nq", "E-mini Nasdaq-100", sessions: equityFutureSessions),
            future("rty", "E-mini Russell 2000", sessions: equityFutureSessions),
            future("emd", "E-mini S&P MidCap 400", sessions: equityFutureSessions),
            future("ym", "E-mini Dow", sessions: equityFutureSessions),

            future("zb", "30-Year Treasury Bond", sessions: treasurySessions, timezone: "America/Chicago", city: "Chicago"),
            future("zn", "10-Year Treasury Note", sessions: treasurySessions, timezone: "America/Chicago", city: "Chicago"),
            future("zf", "5-Year Treasury Note", sessions: treasurySessions, timezone: "America/Chicago", city: "Chicago"),
            future("zt", "2-Year Treasury Note", sessions: treasurySessions, timezone: "America/Chicago", city: "Chicago"),
            future("zc", "Corn", sessions: agricultureSessions, timezone: "America/Chicago", city: "Chicago"),
            future("zs", "Soybeans", sessions: agricultureSessions, timezone: "America/Chicago", city: "Chicago"),
            future("zw", "Wheat", sessions: agricultureSessions, timezone: "America/Chicago", city: "Chicago"),

            future("cl", "Crude Oil", sessions: energySessions),
            future("ng", "Natural Gas", sessions: energySessions),
            future("ho", "Heating Oil", sessions: energySessions),
            future("rb", "RBOB Gasoline", sessions: energySessions),

            future("gc", "Gold", sessions: metalSessions(openHour: 8, openMinute: 20, closeHour: 13, closeMinute: 30)),
            future("si", "Silver", sessions: metalSessions(openHour: 8, openMinute: 25, closeHour: 13, closeMinute: 25)),
            future("hg", "Copper", sessions: metalSessions(openHour: 8, openMinute: 10, closeHour: 13, closeMinute: 0)),
            future("pl", "Platinum", sessions: metalSessions(openHour: 8, openMinute: 20, closeHour: 13, closeMinute: 5)),

            market(
                "india-stocks",
                "India Stocks",
                city: "Mumbai",
                timezone: "Asia/Kolkata",
                region: .india,
                sessions: [
                    SessionRule(weekdays: weekdays, startHour: 9, endHour: 9, endMinute: 15, kind: .preMarket),
                    SessionRule(weekdays: weekdays, startHour: 9, startMinute: 15, endHour: 15, endMinute: 30, kind: .regular),
                ]
            ),
            market(
                "nse-fo",
                "NSE F&O",
                city: "Mumbai",
                timezone: "Asia/Kolkata",
                region: .india,
                sessions: [SessionRule(weekdays: weekdays, startHour: 9, startMinute: 15, endHour: 15, endMinute: 30, kind: .regular)]
            ),
            market(
                "mcx",
                "MCX",
                city: "Mumbai",
                timezone: "Asia/Kolkata",
                region: .india,
                sessions: [
                    SessionRule(
                        weekdays: weekdays,
                        startHour: 9,
                        endHour: 23,
                        endMinute: 55,
                        kind: .regular,
                        endHourWhenReferenceIsDST: 23,
                        endMinuteWhenReferenceIsDST: 30,
                        daylightReferenceTimeZoneID: "America/New_York"
                    ),
                ]
            ),
            market("crypto", "Crypto", shortName: "Crypto", city: "UTC", timezone: "UTC", region: .crypto, sessions: [], alwaysOpen: true),
        ]
    }

    private static func metalSessions(openHour: Int, openMinute: Int, closeHour: Int, closeMinute: Int) -> [SessionRule] {
        [
            SessionRule(weekdays: sundayThroughThursday, startHour: 18, endHour: 17, kind: .globex),
            SessionRule(weekdays: mondayThroughThursday, startHour: 17, endHour: 18, kind: .maintenanceBreak),
            SessionRule(weekdays: weekdays, startHour: openHour, startMinute: openMinute, endHour: closeHour, endMinute: closeMinute, kind: .regular),
        ]
    }
}
