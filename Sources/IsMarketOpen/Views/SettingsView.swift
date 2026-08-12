import SwiftUI

struct SettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        TabView {
            GeneralSettingsView()
                .tabItem { Label("General", systemImage: "gearshape") }

            MarketSettingsView()
                .tabItem { Label("Markets", systemImage: "building.columns") }

            WorldClockSettingsView()
                .tabItem { Label("Clocks", systemImage: "globe") }

            CalendarSettingsView()
                .tabItem { Label("Calendars", systemImage: "calendar") }
        }
        .frame(width: 540, height: 430)
    }
}

private struct GeneralSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var settings = model.settings

        Form {
            Section("Favorite") {
                Picker("Favorite market", selection: $settings.favoriteMarketID) {
                    ForEach(model.favoriteChoices) { market in
                        Text(market.shortName == market.displayName ? market.displayName : "\(market.shortName) — \(market.displayName)")
                            .tag(market.id)
                    }
                }
            }

            Section("Menu Bar") {
                Picker("Display", selection: $settings.menuDisplayMode) {
                    ForEach(MenuDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.label).tag(mode)
                    }
                }
                Picker("Opening/closing soon", selection: $settings.soonThresholdMinutes) {
                    Text("15 minutes").tag(15)
                    Text("30 minutes").tag(30)
                    Text("60 minutes").tag(60)
                }
                Picker("Clock format", selection: $settings.clockFormat) {
                    ForEach(ClockFormatPreference.allCases, id: \.self) { preference in
                        Text(preference.label).tag(preference)
                    }
                }
            }

            Section("Startup") {
                Toggle("Launch at login", isOn: Binding(
                    get: { model.launchAtLogin },
                    set: { model.setLaunchAtLogin($0) }
                ))
                if let error = model.launchAtLoginError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section {
                LabeledContent("Privacy", value: "No account or telemetry")
                LabeledContent("Application", value: "Native macOS menu-bar app")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

private struct MarketSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section {
                Text("Show, hide, and reorder market groups. A futures product can still be selected as the favorite in General.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            ForEach(MarketRegion.allCases, id: \.self) { region in
                Section(region.rawValue) {
                    ForEach(orderedRows(in: region)) { row in
                        HStack {
                            Toggle(rowName(row), isOn: Binding(
                                get: { !model.settings.hiddenRowIDs.contains(row.id) },
                                set: { enabled in
                                    if enabled {
                                        model.settings.hiddenRowIDs.remove(row.id)
                                    } else {
                                        model.settings.hiddenRowIDs.insert(row.id)
                                    }
                                }
                            ))
                            Spacer()
                            Button { model.settings.moveRow(row.id, direction: -1) } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Move \(rowName(row)) up")
                            Button { model.settings.moveRow(row.id, direction: 1) } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.borderless)
                            .accessibilityLabel("Move \(rowName(row)) down")
                        }
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func orderedRows(in region: MarketRegion) -> [MarketRowDefinition] {
        let rows = MarketCatalog.sections.first { $0.region == region }?.rows ?? []
        return rows.sorted {
            (model.settings.rowOrder.firstIndex(of: $0.id) ?? .max) <
                (model.settings.rowOrder.firstIndex(of: $1.id) ?? .max)
        }
    }

    private func rowName(_ row: MarketRowDefinition) -> String {
        switch row {
        case let .single(_, marketID): model.markets[marketID]?.displayName ?? marketID
        case let .group(_, title, _): title
        }
    }
}

private struct WorldClockSettingsView: View {
    @Environment(AppModel.self) private var model
    @State private var pendingCityID = "singapore"

    var body: some View {
        Form {
            Section("Displayed clocks") {
                ForEach(model.settings.cityIDs, id: \.self) { cityID in
                    if let city = CityCatalog.city(id: cityID) {
                        HStack {
                            VStack(alignment: .leading) {
                                Text(city.cityName)
                                Text(city.timeZoneID)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button { model.settings.moveCity(cityID, direction: -1) } label: {
                                Image(systemName: "chevron.up")
                            }
                            .buttonStyle(.borderless)
                            Button { model.settings.moveCity(cityID, direction: 1) } label: {
                                Image(systemName: "chevron.down")
                            }
                            .buttonStyle(.borderless)
                            Button(role: .destructive) {
                                model.settings.cityIDs.removeAll { $0 == cityID }
                            } label: {
                                Image(systemName: "minus.circle")
                            }
                            .buttonStyle(.borderless)
                        }
                    }
                }
            }

            Section("Add a city") {
                HStack {
                    Picker("City", selection: $pendingCityID) {
                        ForEach(availableCities) { city in
                            Text(city.cityName).tag(city.id)
                        }
                    }
                    Button("Add") {
                        guard !model.settings.cityIDs.contains(pendingCityID) else { return }
                        model.settings.cityIDs.append(pendingCityID)
                        pendingCityID = availableCities.first?.id ?? pendingCityID
                    }
                    .disabled(availableCities.isEmpty)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private var availableCities: [CityClockDefinition] {
        CityCatalog.all.filter { !model.settings.cityIDs.contains($0.id) }
    }
}

private struct CalendarSettingsView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        Form {
            Section("Calendar data") {
                LabeledContent("Source", value: model.calendarState.origin.rawValue)
                LabeledContent("Generated", value: MarketFormatting.fullDate(model.calendarState.generatedAt))
                if let refreshed = model.calendarState.lastSuccessfulRefresh {
                    LabeledContent("Last downloaded", value: MarketFormatting.fullDate(refreshed))
                }
                LabeledContent("Equities coverage", value: model.markets["us-stocks"]?.verifiedThrough ?? "Unknown")
                LabeledContent("Futures coverage", value: model.markets["es"]?.verifiedThrough ?? "Unknown")
                LabeledContent("India coverage", value: model.markets["india-stocks"]?.verifiedThrough ?? "Unknown")

                Button {
                    Task { await model.refreshCalendars() }
                } label: {
                    if model.calendarState.isRefreshing {
                        HStack { ProgressView().controlSize(.small); Text("Refreshing…") }
                    } else {
                        Label("Refresh calendars", systemImage: "arrow.clockwise")
                    }
                }
                .disabled(model.calendarState.isRefreshing)

                if let error = model.calendarState.lastError {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.orange)
                }
            }

            Section("Official sources") {
                Link("NYSE hours and holidays", destination: URL(string: "https://www.nyse.com/markets/hours-calendars")!)
                Link("Nasdaq holiday calendar", destination: URL(string: "https://www.nasdaqtrader.com/trader.aspx?id=calendar")!)
                Link("CME Group trading hours", destination: URL(string: "https://www.cmegroup.com/trading-hours.html")!)
                Link("NSE timings and holidays", destination: URL(string: "https://www.nseindia.com/resources/exchange-communication-holidays")!)
                Link("MCX trading holidays", destination: URL(string: "https://www.mcxindia.com/market-operations/trading-surveillance/trading-holidays")!)
            }

            Section {
                Text("Market status is calculated locally. Network access is used only to refresh the public calendar manifest.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}
