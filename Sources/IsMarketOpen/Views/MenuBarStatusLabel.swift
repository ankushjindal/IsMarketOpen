import SwiftUI

struct MenuBarStatusLabel: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        let snapshot = model.favoriteSnapshot
        let iconState = iconState(for: snapshot)

        if model.settings.menuDisplayMode == .iconOnly {
            Image(systemName: iconState.systemImage)
                .accessibilityLabel(accessibilityLabel(snapshot))
        } else {
            Label {
                Text(MarketFormatting.menuBarText(
                    for: snapshot,
                    now: model.now,
                    preference: model.settings.clockFormat
                ))
            } icon: {
                Image(systemName: iconState.systemImage)
            }
            .accessibilityLabel(accessibilityLabel(snapshot))
        }
    }

    private func iconState(for snapshot: MarketSnapshot) -> MarketIconState {
        if snapshot.state == .calendarOutdated || snapshot.calendarIsStale { return .warning }
        if snapshot.isTransitionSoon { return .soon }
        if snapshot.state == .open || snapshot.state == .alwaysOpen { return .open }
        return .closed
    }

    private func accessibilityLabel(_ snapshot: MarketSnapshot) -> String {
        "\(snapshot.market.displayName), \(snapshot.state.label), \(MarketFormatting.transitionText(for: snapshot, now: model.now, preference: model.settings.clockFormat))"
    }
}
