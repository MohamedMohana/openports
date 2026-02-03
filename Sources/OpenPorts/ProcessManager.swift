import Foundation
import AppKit
import OpenPortsCore

@MainActor
final class ProcessManager {
    
    func terminateProcess(pid: Int, signal: Signal = .term) async throws -> String {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/kill")
        task.arguments = ["-\(signal.rawValue)", String(pid)]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return "Failed to read output"
            }
            
            if task.terminationStatus == 0 {
                return "Process \(pid) terminated successfully"
            }
            
            throw ProcessError.terminationFailed(status: task.terminationStatus, message: output)
        } catch {
            return "Failed to terminate process \(pid): \(error.localizedDescription)"
        }
    }
    
    func checkPermissions(for pid: Int) -> Bool {
        let currentUid = getuid()
        
        if currentUid == 0 {
            return true
        }
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/ps")
        task.arguments = ["-o", "user=\(currentUid)", "-p", String(pid)]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = Pipe()
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            guard let output = String(data: data, encoding: .utf8) else {
                return true
            }
            
            let lines = output.components(separatedBy: .newlines)
            return lines.contains { line in
                let components = line.components(separatedBy: .whitespaces)
                return components.count >= 2 && components[1] == String(currentUid)
            }
        } catch {
            return true
        }
    }
    
    func checkIfPrivileged(_ port: PortInfo) -> Bool {
        let privilegedUsers = ["root", "_windowserver", "_mbsetupuser", "_spotlight"]
        
        if privilegedUsers.contains(port.processName) {
            return true
        }
        
        if let bundleID = port.bundleID {
            let systemPrefixes = ["com.apple.", "com.apple.coreservices"]
            for prefix in systemPrefixes {
                if bundleID.hasPrefix(prefix) {
                    return true
                }
            }
        }
        
        if let path = port.executablePath {
            let systemPaths = ["/System/", "/usr/sbin/", "/usr/bin/"]
            for systemPath in systemPaths {
                if path.hasPrefix(systemPath) {
                    return true
                }
            }
        }
        
        return false
    }
    
    func requestAdminElevation() {
        let script = """
        #!/bin/bash
        osascript -e 'tell application "System Events" to do shell script "osascript -e \\"do shell script \\" & \\"\\\\\\" & quit end\\"'
        """
        
        let tempDir = FileManager.default.temporaryDirectory
        let scriptPath = tempDir.appendingPathComponent("request_auth.bash").path()
        
        try? FileManager.default.removeItem(atPath: scriptPath)
        try? script.write(toFile: scriptPath, atomically: true, encoding: .utf8)
        
        let permissions = NSNumber(value: 0o755)
        try? FileManager.default.setAttributes([.posixPermissions: permissions], ofItemAtPath: scriptPath)
        
        let task = Process()
        task.executableURL = URL(fileURLWithPath: scriptPath)
        
        do {
            try task.run()
            task.waitUntilExit()
        } catch {
            
        }
        
        try? FileManager.default.removeItem(atPath: scriptPath)
    }
}

enum Signal: String {
    case term = "TERM"
    case kill = "KILL"
}

enum ProcessError: LocalizedError {
    case terminationFailed(status: Int32, message: String)
    
    var errorDescription: String? {
        switch self {
        case .terminationFailed(let status, let message):
            return "Failed to terminate process: \(status) - \(message)"
        }
    }
}
