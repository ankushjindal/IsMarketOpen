import SwiftUI

struct UpcomingExceptionsView: View {
    let exceptions: [UpcomingException]

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text("UPCOMING")
                .font(.caption2.weight(.bold))
                .foregroundStyle(.secondary)

            ForEach([UpcomingException](exceptions.prefix(8)), id: \UpcomingException.id) { (exception: UpcomingException) in
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text(MarketFormatting.shortDate(exception.date))
                        .font(.caption.monospacedDigit())
                        .frame(width: 72, alignment: .leading)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(exception.title)
                            .font(.caption.weight(.semibold))
                        Text(scopeText(exception.marketNames))
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text(exception.isFullClosure ? "Closed" : "Special hours")
                        .font(.caption2)
                        .foregroundStyle(exception.isFullClosure ? Color.secondary : Color.orange)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private func scopeText(_ names: [String]) -> String {
        if names.count <= 3 { return names.joined(separator: ", ") }
        return "\(names.prefix(2).joined(separator: ", ")) +\(names.count - 2) markets"
    }
}
