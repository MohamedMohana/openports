import ArgumentParser
import Foundation
import Logging
import OpenPortsCore

@main
struct OpenPortsCLICommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "openports-cli",
        abstract: "List listening ports and terminate their processes from the terminal.",
        discussion: """
        The command-line companion to the OpenPorts menu bar app. It shares the same \
        scanning, process resolution, and safety analysis, so a port that OpenPorts \
        labels Critical carries the same warning here.

        Examples:
          openports-cli                      List listening TCP ports
          openports-cli --udp                Also include bound UDP sockets
          openports-cli --format json        Machine-readable output
          openports-cli --kill 3000          Terminate the process on port 3000
          openports-cli --kill 3000 --force  Terminate without a confirmation prompt
        """,
        version: CLIVersion.current,
    )

    @Option(name: [.customShort("f"), .long], help: "Output format for the port listing.")
    var format: OutputFormat = .table

    @Flag(name: .long, help: "Include bound UDP sockets alongside listening TCP ports.")
    var udp = false

    @Option(name: .long, help: "Terminate the process(es) listening on this port instead of listing.")
    var kill: Int?

    @Flag(name: .long, help: "Skip the confirmation prompt when using --kill.")
    var force = false

    @Option(name: .long, help: "Signal sent with --kill: term (graceful) or kill (force).")
    var signal: TerminationSignal = .term

    @Flag(name: [.customShort("v"), .long], help: "Print scanner diagnostics to stderr.")
    var verbose = false

    func validate() throws {
        if let kill, !(1 ... 65535).contains(kill) {
            throw ValidationError("Port must be between 1 and 65535.")
        }
    }

    func run() async throws {
        // Core services log via swift-log, whose default handler writes to stdout.
        // Route logs to stderr so table/json/csv output stays pipeable.
        let logLevel: Logger.Level = verbose ? .debug : .warning
        LoggingSystem.bootstrap { label in
            var handler = StreamLogHandler.standardError(label: label)
            handler.logLevel = logLevel
            return handler
        }

        let result = await PortScanner().scanOpenPorts(includeUDP: udp)
        guard result.success else {
            printError("Scan failed: \(result.error ?? "unknown error")")
            throw ExitCode.failure
        }

        let resolved = await ProcessResolver().resolveProcessInfo(for: result.ports)
        let ports = await PortInfoEnhancer().enhance(resolved)
            .sorted { lhs, rhs in
                (lhs.port, lhs.portProtocol.rawValue, lhs.pid) < (rhs.port, rhs.portProtocol.rawValue, rhs.pid)
            }

        if let kill {
            try killProcesses(on: kill, from: ports)
        } else {
            try await list(ports)
        }
    }

    // MARK: - Listing

    private func list(_ ports: [PortInfo]) async throws {
        if let exportFormat = format.exportFormat {
            let output = await PortExporter().export(ports: ports, format: exportFormat)
            print(output)
            return
        }

        guard !ports.isEmpty else {
            print("No listening ports found.")
            return
        }

        print(PortTableFormatter().render(ports))
    }

    // MARK: - Killing

    private func killProcesses(on targetPort: Int, from ports: [PortInfo]) throws {
        let matches = uniqueByPID(ports.filter { $0.port == targetPort })
        guard !matches.isEmpty else {
            var message = "No process found listening on port \(targetPort)."
            if !udp {
                message += " UDP sockets are only scanned with --udp."
            }
            printError(message)
            throw ExitCode.failure
        }

        let analyzer = PortSafetyAnalyzer()
        let terminator = ProcessTerminator()
        var failures = 0

        for port in matches {
            let safety = port.safety ?? analyzer.analyze(port)

            print("Port \(port.port)/\(port.portProtocol.rawValue): \(port.displayName) (PID \(port.pid))")
            if let description = analyzer.getSafetyDescription(port) {
                print("  Safety: \(safety.rawValue) — \(description)")
            }
            if let warning = safety.warningMessage {
                print("  Warning: \(warning)")
            }

            if !force {
                guard confirm("Send \(signal.displayName) to \(port.displayName) (PID \(port.pid))? [y/N] ") else {
                    print("  Skipped.")
                    continue
                }
            }

            switch terminator.terminate(pid: port.pid, signal: signal) {
            case .success:
                print("  Sent \(signal.displayName) to PID \(port.pid).")
            case let .failure(error):
                printError("Failed to terminate PID \(port.pid): \(error)")
                failures += 1
            }
        }

        if failures > 0 {
            throw ExitCode.failure
        }
    }

    /// A process bound to both IPv4/IPv6 or TCP/UDP shows up once per row; only signal it once.
    private func uniqueByPID(_ ports: [PortInfo]) -> [PortInfo] {
        var seen = Set<Int>()
        return ports.filter { seen.insert($0.pid).inserted }
    }

    // MARK: - Terminal helpers

    private func confirm(_ prompt: String) -> Bool {
        fputs(prompt, stdout)
        fflush(stdout)
        guard let line = readLine() else {
            printError("No input available for confirmation; re-run with --force.")
            return false
        }
        let answer = line.trimmingCharacters(in: .whitespaces).lowercased()
        return answer == "y" || answer == "yes"
    }

    private func printError(_ message: String) {
        fputs(message + "\n", stderr)
    }
}
