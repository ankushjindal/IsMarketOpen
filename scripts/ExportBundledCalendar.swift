import Foundation

@main
struct ExportBundledCalendar {
    static func main() throws {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
        let data = try encoder.encode(BundledCalendar.manifest)
        guard CommandLine.arguments.count == 2 else {
            throw ExportError.missingOutputPath
        }
        var output = data
        output.append(Data("\n".utf8))
        try output.write(to: URL(fileURLWithPath: CommandLine.arguments[1]), options: .atomic)
    }
}

private enum ExportError: LocalizedError {
    case missingOutputPath

    var errorDescription: String? {
        "Usage: ExportBundledCalendar <output-path>"
    }
}
