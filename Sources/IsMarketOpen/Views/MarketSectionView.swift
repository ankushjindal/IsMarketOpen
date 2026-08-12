import SwiftUI

struct MarketSectionView: View {
    @Environment(AppModel.self) private var model
    let section: MarketSectionDefinition
    @Binding var expandedRowID: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(section.region.rawValue.uppercased())
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 14)
                .padding(.top, 12)
                .padding(.bottom, 4)

            ForEach(section.rows) { row in
                if shouldShow(row) {
                    MarketRowView(row: row, isExpanded: expandedRowID == row.id) {
                        withAnimation(.snappy(duration: 0.2)) {
                            expandedRowID = expandedRowID == row.id ? nil : row.id
                        }
                    }
                }
            }
        }
    }

    private func shouldShow(_ row: MarketRowDefinition) -> Bool {
        if case let .single(_, marketID) = row, marketID == model.settings.favoriteMarketID {
            return false
        }
        return true
    }
}

private struct MarketRowView: View {
    @Environment(AppModel.self) private var model
    let row: MarketRowDefinition
    let isExpanded: Bool
    let toggle: () -> Void

    private var snapshots: [MarketSnapshot] { model.snapshots(for: row) }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: toggle) {
                HStack(spacing: 10) {
                    summaryDot
                    VStack(alignment: .leading, spacing: 2) {
                        Text(rowTitle)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)
                        Text(summaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                    if snapshots.count == 1, let market = snapshots.first?.market {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text(market.cityName)
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            Text(MarketFormatting.clock(model.now, timeZone: market.timeZone, preference: model.settings.clockFormat))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(.primary)
                        }
                    }
                    Image(systemName: "chevron.right")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.tertiary)
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .contentShape(Rectangle())
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
            }
            .buttonStyle(.plain)

            if isExpanded {
                ExpandedMarketDetail(row: row, snapshots: snapshots)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var rowTitle: String {
        switch row {
        case let .single(_, marketID): model.markets[marketID]?.displayName ?? marketID
        case let .group(_, title, _): title
        }
    }

    private var summaryText: String {
        let outdated = snapshots.filter { $0.state == .calendarOutdated }.count
        if outdated > 0 { return "\(outdated) calendar\(outdated == 1 ? "" : "s") need an update" }
        if snapshots.allSatisfy({ $0.state == .alwaysOpen }) { return "Open 24/7" }
        let open = snapshots.filter { $0.state == .open || $0.state == .alwaysOpen }.count
        if snapshots.count == 1, let snapshot = snapshots.first {
            var text = MarketFormatting.transitionText(for: snapshot, now: model.now, preference: model.settings.clockFormat)
            if let secondary = snapshot.activeSecondarySessions.first, snapshot.state == .closed {
                text += " · \(secondary.kind.label) active"
            }
            return text
        }
        if open == snapshots.count { return "All \(open) products open" }
        if open == 0 { return "All \(snapshots.count) products closed" }
        return "\(open) open · \(snapshots.count - open) closed"
    }

    @ViewBuilder
    private var summaryDot: some View {
        let open = snapshots.filter { $0.state == .open || $0.state == .alwaysOpen }.count
        let warning = snapshots.contains { $0.state == .calendarOutdated }
        Circle()
            .fill(warning ? Color.orange : (open > 0 ? Color.green : Color.secondary.opacity(0.6)))
            .frame(width: 7, height: 7)
    }
}

private struct ExpandedMarketDetail: View {
    @Environment(AppModel.self) private var model
    let row: MarketRowDefinition
    let snapshots: [MarketSnapshot]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if snapshots.count > 1 {
                ForEach(snapshots) { snapshot in
                    ProductStatusRow(snapshot: snapshot)
                }
            } else if let snapshot = snapshots.first {
                SessionTimelineView(snapshot: snapshot)
            }

            if let snapshot = snapshots.first {
                Divider()
                HStack(spacing: 6) {
                    Text("Verified \(MarketFormatting.shortDate(snapshot.market.verifiedAt))")
                        .foregroundStyle(.secondary)
                    Text("·")
                        .foregroundStyle(.tertiary)
                    ForEach(snapshot.market.sources, id: \.url) { source in
                        Link(source.name, destination: source.url)
                    }
                }
                .font(.caption2)
            }
        }
        .padding(10)
        .background(.primary.opacity(0.035), in: RoundedRectangle(cornerRadius: 8))
    }
}

private struct ProductStatusRow: View {
    @Environment(AppModel.self) private var model
    let snapshot: MarketSnapshot

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            StatusDot(snapshot: snapshot)
                .padding(.top, 5)
            VStack(alignment: .leading, spacing: 1) {
                HStack {
                    Text(snapshot.market.shortName)
                        .font(.caption.weight(.bold))
                        .frame(width: 34, alignment: .leading)
                    Text(snapshot.market.displayName)
                        .font(.caption)
                    Spacer()
                    Text(MarketFormatting.headlineStateLabel(for: snapshot))
                        .font(.caption2.weight(.bold))
                        .foregroundStyle(.secondary)
                }
                Text(MarketFormatting.transitionText(for: snapshot, now: model.now, preference: model.settings.clockFormat))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                if let regularText = MarketFormatting.regularSessionText(for: snapshot, now: model.now) {
                    Text(regularText)
                        .font(.caption2)
                        .foregroundStyle(.blue)
                } else if let secondary = snapshot.activeSecondarySessions.first, snapshot.state == .closed {
                    Text("\(secondary.kind.label) active")
                        .font(.caption2)
                        .foregroundStyle(.blue)
                } else if snapshot.activeBreak != nil {
                    Text("Daily maintenance break")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}

private struct SessionTimelineView: View {
    @Environment(AppModel.self) private var model
    let snapshot: MarketSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let exception = snapshot.currentException {
                Text(exception.name)
                    .font(.caption.weight(.semibold))
                if let note = exception.note {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            if snapshot.todaySessions.isEmpty {
                Text(snapshot.currentException?.isFullClosure == true ? "No scheduled session today" : "No sessions remaining today")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(snapshot.todaySessions) { interval in
                    HStack {
                        Text(interval.kind.label)
                            .font(.caption)
                        Spacer()
                        Text(MarketFormatting.sessionRange(interval, market: snapshot.market, preference: model.settings.clockFormat))
                            .font(.caption.monospacedDigit())
                        if interval.start <= model.now && model.now < interval.end {
                            Text("NOW")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundStyle(.green)
                        }
                    }
                }
            }

            if let transition = snapshot.nextTransition {
                HStack {
                    Text(snapshot.transitionKind == .opens ? "Next regular open" : "Regular close")
                    Spacer()
                    Text(MarketFormatting.clock(transition, timeZone: .current, preference: model.settings.clockFormat, includeDay: true))
                        .monospacedDigit()
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
    }
}
