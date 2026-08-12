import SwiftUI

struct WorldClocksView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("WORLD CLOCKS")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

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
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }
}
