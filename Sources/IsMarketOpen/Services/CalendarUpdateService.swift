import Foundation

actor CalendarUpdateService {
    enum UpdateError: LocalizedError {
        case invalidResponse
        case unsupportedSchema(Int)
        case invalidManifest(String)

        var errorDescription: String? {
            switch self {
            case .invalidResponse: "The calendar server returned an invalid response."
            case let .unsupportedSchema(version): "Calendar schema version \(version) is not supported."
            case let .invalidManifest(message): "The calendar manifest is invalid: \(message)"
            }
        }
    }

    static let shared = CalendarUpdateService()

    private let remoteURL = URL(string: "https://raw.githubusercontent.com/ankushjindal/IsMarketOpen/main/Calendars/markets.json")!
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder

    init() {
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    }

    func loadBestAvailable() -> (CalendarManifest, CalendarLoadState) {
        if let cached = try? Data(contentsOf: cachedCalendarURL()),
           let manifest = try? decode(cached) {
            return (
                manifest,
                CalendarLoadState(
                    origin: .cached,
                    generatedAt: manifest.generatedAt,
                    lastSuccessfulRefresh: cachedModificationDate(),
                    lastError: nil,
                    isRefreshing: false
                )
            )
        }

        if let bundledURL = Bundle.main.url(forResource: "markets", withExtension: "json", subdirectory: "Calendars"),
           let data = try? Data(contentsOf: bundledURL),
           let manifest = try? decode(data) {
            return (
                manifest,
                CalendarLoadState(origin: .bundled, generatedAt: manifest.generatedAt, lastSuccessfulRefresh: nil, lastError: nil, isRefreshing: false)
            )
        }

        return (
            BundledCalendar.manifest,
            CalendarLoadState(origin: .bundled, generatedAt: BundledCalendar.generatedAt, lastSuccessfulRefresh: nil, lastError: nil, isRefreshing: false)
        )
    }

    func refresh() async throws -> CalendarManifest {
        let (data, response) = try await URLSession.shared.data(from: remoteURL)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw UpdateError.invalidResponse
        }
        let manifest = try decode(data)
        let destination = cachedCalendarURL()
        try FileManager.default.createDirectory(at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
        try data.write(to: destination, options: .atomic)
        return manifest
    }

    private func decode(_ data: Data) throws -> CalendarManifest {
        let manifest = try decoder.decode(CalendarManifest.self, from: data)
        guard manifest.schemaVersion == 1 else { throw UpdateError.unsupportedSchema(manifest.schemaVersion) }
        do {
            try CalendarManifestValidator.validate(manifest, knownMarketIDs: MarketCatalog.marketIDs)
        } catch {
            throw UpdateError.invalidManifest(error.localizedDescription)
        }
        return manifest
    }

    private func cachedCalendarURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return base.appendingPathComponent("IsMarketOpen", isDirectory: true).appendingPathComponent("markets.json")
    }

    private func cachedModificationDate() -> Date? {
        let attributes = try? FileManager.default.attributesOfItem(atPath: cachedCalendarURL().path)
        return attributes?[.modificationDate] as? Date
    }
}
