import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class AppModel {
    let settings: AppSettings
    private(set) var now = Date()
    private(set) var markets: [String: MarketDefinition]
    private(set) var calendarState: CalendarLoadState
    private(set) var launchAtLogin = LaunchAtLoginService.isEnabled
    var launchAtLoginError: String?

    private let engine = MarketCalendarEngine()
    private let updater = CalendarUpdateService.shared

    convenience init() {
        self.init(settings: AppSettings())
    }

    init(settings: AppSettings) {
        self.settings = settings
        markets = MarketCatalog.definitions()
        calendarState = CalendarLoadState(
            origin: .bundled,
            generatedAt: BundledCalendar.generatedAt,
            lastSuccessfulRefresh: nil,
            lastError: nil,
            isRefreshing: false
        )

        Task { await loadCalendarsAndRefreshIfNeeded() }
    }

    var favoriteMarket: MarketDefinition {
        markets[settings.favoriteMarketID] ?? markets["us-stocks"]!
    }

    var favoriteSnapshot: MarketSnapshot {
        snapshot(for: favoriteMarket)
    }

    var upcomingExceptions: [UpcomingException] {
        engine.upcomingExceptions(for: Array(markets.values), at: now)
    }

    var visibleSections: [MarketSectionDefinition] {
        MarketCatalog.sections.compactMap { section in
            let visibleRows = section.rows
                .filter { !settings.hiddenRowIDs.contains($0.id) }
                .sorted { rowRank($0.id) < rowRank($1.id) }
            return visibleRows.isEmpty ? nil : MarketSectionDefinition(region: section.region, rows: visibleRows)
        }
    }

    var favoriteChoices: [MarketDefinition] {
        markets.values.sorted {
            if $0.region != $1.region {
                return MarketRegion.allCases.firstIndex(of: $0.region)! < MarketRegion.allCases.firstIndex(of: $1.region)!
            }
            return $0.displayName < $1.displayName
        }
    }

    func snapshot(for market: MarketDefinition) -> MarketSnapshot {
        engine.snapshot(
            for: market,
            at: now,
            soonThreshold: TimeInterval(settings.soonThresholdMinutes * 60),
            lastSuccessfulRefresh: calendarState.lastSuccessfulRefresh
        )
    }

    func snapshots(for row: MarketRowDefinition) -> [MarketSnapshot] {
        row.marketIDs.compactMap { markets[$0] }.map(snapshot(for:))
    }

    func tick() {
        now = Date()
    }

    func completeFirstRun(enableLaunchAtLogin: Bool) {
        settings.completedFirstRun = true
        setLaunchAtLogin(enableLaunchAtLogin)
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        do {
            try LaunchAtLoginService.setEnabled(enabled)
            launchAtLogin = LaunchAtLoginService.isEnabled
            launchAtLoginError = nil
        } catch {
            launchAtLogin = LaunchAtLoginService.isEnabled
            launchAtLoginError = error.localizedDescription
        }
    }

    func refreshCalendars() async {
        guard !calendarState.isRefreshing else { return }
        calendarState.isRefreshing = true
        calendarState.lastError = nil
        do {
            let manifest = try await updater.refresh()
            markets = MarketCatalog.definitions(applying: manifest)
            calendarState = CalendarLoadState(
                origin: .remote,
                generatedAt: manifest.generatedAt,
                lastSuccessfulRefresh: Date(),
                lastError: nil,
                isRefreshing: false
            )
        } catch {
            calendarState.isRefreshing = false
            calendarState.lastError = error.localizedDescription
        }
    }

    private func loadCalendarsAndRefreshIfNeeded() async {
        let (manifest, state) = await updater.loadBestAvailable()
        markets = MarketCatalog.definitions(applying: manifest)
        calendarState = state

        let lastAttempt = UserDefaults.standard.object(forKey: "lastCalendarRefreshAttempt") as? Date
        if lastAttempt == nil || Date().timeIntervalSince(lastAttempt!) > 24 * 60 * 60 {
            UserDefaults.standard.set(Date(), forKey: "lastCalendarRefreshAttempt")
            await refreshCalendars()
        }
    }

    private func rowRank(_ rowID: String) -> Int {
        settings.rowOrder.firstIndex(of: rowID) ?? Int.max
    }
}
