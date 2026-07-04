import ArgumentParser
import Darwin

/// Signal choice for `--kill`, mirroring the app's terminate actions.
enum TerminationSignal: String, CaseIterable, ExpressibleByArgument {
    case term
    case kill

    var rawSignal: Int32 {
        switch self {
        case .term: SIGTERM
        case .kill: SIGKILL
        }
    }

    var displayName: String {
        switch self {
        case .term: "SIGTERM"
        case .kill: "SIGKILL"
        }
    }
}

enum TerminationError: Error, CustomStringConvertible, Equatable {
    case permissionDenied
    case noSuchProcess
    case failed(code: Int32)

    var description: String {
        switch self {
        case .permissionDenied:
            "permission denied (the process may be owned by another user or protected by macOS)"
        case .noSuchProcess:
            "no such process (it may have already exited)"
        case let .failed(code):
            "kill failed with errno \(code)"
        }
    }
}

/// Sends termination signals directly via `kill(2)`.
struct ProcessTerminator {
    func terminate(pid: Int, signal: TerminationSignal) -> Result<Void, TerminationError> {
        guard Darwin.kill(pid_t(pid), signal.rawSignal) == 0 else {
            switch errno {
            case EPERM:
                return .failure(.permissionDenied)
            case ESRCH:
                return .failure(.noSuchProcess)
            default:
                return .failure(.failed(code: errno))
            }
        }
        return .success(())
    }
}
