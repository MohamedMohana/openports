import Foundation
import OpenPortsCore

/// Renders a list of ports as an aligned plain-text table.
struct PortTableFormatter {
    private static let header = ["PORT", "PROTO", "PID", "PROCESS", "APP", "SAFETY", "UPTIME"]
    private static let columnSpacing = "  "

    /// Render ports in the order given; callers own sorting.
    func render(_ ports: [PortInfo]) -> String {
        let rows = ports.map(row(for:))
        let widths = columnWidths(rows: [Self.header] + rows)

        var lines = [pad(Self.header, widths: widths)]
        lines += rows.map { pad($0, widths: widths) }
        return lines.joined(separator: "\n")
    }

    private func row(for port: PortInfo) -> [String] {
        [
            String(port.port),
            port.portProtocol.rawValue,
            String(port.pid),
            port.processName,
            port.appName ?? "-",
            port.safety?.rawValue ?? "-",
            port.formattedUptime ?? "-",
        ]
    }

    private func columnWidths(rows: [[String]]) -> [Int] {
        var widths = [Int](repeating: 0, count: Self.header.count)
        for row in rows {
            for (index, cell) in row.enumerated() {
                widths[index] = max(widths[index], cell.count)
            }
        }
        return widths
    }

    /// Pad every column except the last, which stays unpadded to avoid trailing whitespace.
    private func pad(_ row: [String], widths: [Int]) -> String {
        row.enumerated().map { index, cell in
            index == row.count - 1 ? cell : cell.padding(toLength: widths[index], withPad: " ", startingAt: 0)
        }
        .joined(separator: Self.columnSpacing)
    }
}
