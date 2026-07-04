import ArgumentParser
import OpenPortsCore

/// Output format for the port listing.
enum OutputFormat: String, CaseIterable, ExpressibleByArgument {
    case table
    case json
    case csv

    /// The matching `PortExporter` format, or `nil` for the CLI-rendered table.
    var exportFormat: ExportFormat? {
        switch self {
        case .table: nil
        case .json: .json
        case .csv: .csv
        }
    }
}
