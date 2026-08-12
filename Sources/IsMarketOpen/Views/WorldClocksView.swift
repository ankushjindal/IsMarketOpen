import SwiftUI

struct WorldClocksView: View {
    @Environment(AppModel.self) private var model
    @State private var isHoveringHeader = false

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Button {
                model.settings.worldClocksCollapsed.toggle()
            } label: {
                HStack(spacing: 4) {
                    Text("WORLD CLOCKS")
                        .font(.caption2.weight(.bold))
                    Image(systemName: "chevron.right")
                        .font(.caption2.weight(.bold))
                        .rotationEffect(.degrees(model.settings.worldClocksCollapsed ? 0 : 90))
                    Spacer()
                }
                .foregroundStyle(isHoveringHeader ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .onHover { isHoveringHeader = $0 }
            .accessibilityLabel("World clocks")
            .accessibilityValue(model.settings.worldClocksCollapsed ? "Collapsed" : "Expanded")

            if !model.settings.worldClocksCollapsed {
                ForEach(model.settings.cityIDs, id: \.self) { cityID in
                    if let city = CityCatalog.city(id: cityID), let zone = TimeZone(identifier: city.timeZoneID) {
                        HStack {
                            Text(city.cityName)
                                .font(.subheadline)
                            Spacer()
                            Text(MarketFormatting.clock(model.now, timeZone: zone, preference: model.settings.clockFormat, includeDay: true))
                                .font(.subheadline.monospacedDigit())
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .animation(.snappy(duration: 0.18), value: model.settings.worldClocksCollapsed)
    }
}
