import AppKit
import Combine
import SwiftUI

struct MarketPopoverView: View {
    @Environment(AppModel.self) private var model
    @State private var expandedRowID: String?
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 0) {
                    if !model.settings.completedFirstRun {
                        FirstRunBanner()
                            .padding(12)
                    }

                    FavoriteStatusView(snapshot: model.favoriteSnapshot)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)

                    Divider()

                    ForEach(model.visibleSections) { section in
                        MarketSectionView(section: section, expandedRowID: $expandedRowID)
                    }

                    if !model.upcomingExceptions.isEmpty {
                        Divider()
                        UpcomingExceptionsView(exceptions: model.upcomingExceptions)
                    }

                    Divider()
                    WorldClocksView()
                }
            }
            // MenuBarExtra windows do not infer a useful height for a ScrollView.
            // A max-only constraint lets the scroll area collapse to zero, leaving
            // only the Settings/Quit footer visible in the real menu-bar popover.
            .frame(height: 580)

            Divider()
            HStack {
                SettingsLink {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Quit") {
                    NSApplication.shared.terminate(nil)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .frame(width: 420)
        .background(.regularMaterial)
        .onReceive(timer) { _ in model.tick() }
    }
}

private struct FirstRunBanner: View {
    @Environment(AppModel.self) private var model
    @State private var startAtLogin = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "building.columns.fill")
                    .font(.title2)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Welcome to Is Market Open?")
                        .font(.headline)
                    Text("Market clocks are ready. No account or telemetry.")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            Toggle("Start at login", isOn: $startAtLogin)
                .toggleStyle(.switch)
            HStack {
                Spacer()
                Button("Continue") {
                    model.completeFirstRun(enableLaunchAtLogin: startAtLogin)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(12)
        .background(.blue.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct FavoriteStatusView: View {
    @Environment(AppModel.self) private var model
    let snapshot: MarketSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text(snapshot.market.displayName.uppercased())
                    .font(.headline)
                Spacer()
                Text(snapshot.market.cityName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(MarketFormatting.clock(model.now, timeZone: snapshot.market.timeZone, preference: model.settings.clockFormat))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }

            HStack(spacing: 6) {
                StatusDot(snapshot: snapshot)
                Text(snapshot.state.label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(snapshot.state == .calendarOutdated ? .orange : .primary)
                if let exception = snapshot.currentException {
                    Text("· \(exception.name)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Text(MarketFormatting.transitionText(for: snapshot, now: model.now, preference: model.settings.clockFormat))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let secondary = snapshot.activeSecondarySessions.first {
                Text("\(secondary.kind.label) is active")
                    .font(.caption)
                    .foregroundStyle(.blue)
            } else if snapshot.activeBreak != nil {
                Text("Daily maintenance break")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct StatusDot: View {
    let snapshot: MarketSnapshot

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(Circle().stroke(.primary.opacity(0.12), lineWidth: 0.5))
            .accessibilityHidden(true)
    }

    private var color: Color {
        if snapshot.state == .calendarOutdated { return .orange }
        if snapshot.isTransitionSoon { return .orange }
        if snapshot.state == .open || snapshot.state == .alwaysOpen { return .green }
        return .secondary.opacity(0.6)
    }
}
