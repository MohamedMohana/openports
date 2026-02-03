import XCTest
@testable import OpenPortsCore

final class AppIntegrationTests: XCTestCase {
    
    func testPortScannerIntegration() async throws {
        let scanner = PortScanner()
        let result = await scanner.scanOpenPorts()
        
        // Verify scanner returns something (either success with ports or failure with error)
        if result.success {
            XCTAssertFalse(result.ports.isEmpty, "Scanner should return at least one port")
        } else {
            XCTAssertNotNil(result.error, "Error message should be provided")
        }
    }
    
    func testProcessResolverIntegration() async throws {
        let resolver = ProcessResolver()
        
        // Create test port info
        let testPort = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: 12345,
            processName: "test-app",
            appName: "Test App",
            bundleID: "com.test.app",
            executablePath: "/Applications/TestApp.app",
            isSystemProcess: false
        )
        
        // Resolve process info
        let resolved = await resolver.resolveProcessInfo(for: [testPort])
        
        XCTAssertFalse(resolved.isEmpty, "Resolver should return resolved port info")
        XCTAssertEqual(resolved.count, 1, "Should resolve exactly one port")
        
        // Verify basic properties are preserved
        XCTAssertEqual(resolved[0].port, 8080)
        XCTAssertEqual(resolved[0].portProtocol, .tcp)
        XCTAssertEqual(resolved[0].pid, 12345)
    }
    
    func testPortInfoCreation() {
        // Test various PortInfo creation scenarios
        
        // Full port info
        let fullPort = PortInfo(
            port: 443,
            portProtocol: .tcp,
            pid: 123,
            processName: "nginx",
            appName: "Nginx",
            bundleID: "com.nginx.server",
            executablePath: "/usr/local/bin/nginx",
            isSystemProcess: false
        )
        
        XCTAssertEqual(fullPort.port, 443)
        XCTAssertEqual(fullPort.displayName, "Nginx")
        XCTAssertEqual(fullPort.displayPath, "/usr/local/bin/nginx")
        
        // Minimal port info (no app info)
        let minimalPort = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: 456,
            processName: "node",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false
        )
        
        XCTAssertEqual(minimalPort.displayName, "node")
        XCTAssertNil(minimalPort.displayPath)
    }
    
    func testPortProtocolEnum() {
        // Test protocol enum values
        XCTAssertEqual(PortInfo.PortProtocol.tcp.rawValue, "TCP")
        XCTAssertEqual(PortInfo.PortProtocol.udp.rawValue, "UDP")
    }
    
    func testSystemProcessDetection() {
        // Test various system process scenarios
        
        // System process (root user)
        let systemPort1 = PortInfo(
            port: 22,
            portProtocol: .tcp,
            pid: 1,
            processName: "sshd",
            appName: nil,
            bundleID: nil,
            executablePath: "/usr/sbin/sshd",
            isSystemProcess: true
        )
        
        XCTAssertTrue(systemPort1.isSystemProcess)
        
        // Apple system app
        let systemPort2 = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 123,
            processName: "apache",
            appName: "Apache",
            bundleID: "com.apple.apache",
            executablePath: "/usr/sbin/httpd",
            isSystemProcess: true
        )
        
        XCTAssertTrue(systemPort2.isSystemProcess)
        
        // User process
        let userPort = PortInfo(
            port: 8080,
            portProtocol: .tcp,
            pid: 456,
            processName: "node",
            appName: "MyApp",
            bundleID: "com.myapp.app",
            executablePath: "/Users/test/MyApp.app",
            isSystemProcess: false
        )
        
        XCTAssertFalse(userPort.isSystemProcess)
    }
    
    func testPortScanResult() {
        // Test PortScanResult scenarios
        
        // Success result with ports
        let ports = [
            PortInfo(port: 80, portProtocol: .tcp, pid: 1, processName: "test1", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 443, portProtocol: .tcp, pid: 2, processName: "test2", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false)
        ]
        
        let successResult = PortScanResult(ports: ports, success: true, error: nil)
        
        XCTAssertTrue(successResult.success)
        XCTAssertEqual(successResult.ports.count, 2)
        XCTAssertNil(successResult.error)
        
        // Success result without ports (scanner runs but finds nothing)
        let emptySuccessResult = PortScanResult(ports: [], success: true, error: nil)
        
        XCTAssertTrue(emptySuccessResult.success)
        XCTAssertEqual(emptySuccessResult.ports.count, 0)
        XCTAssertNil(emptySuccessResult.error)
        XCTAssertEqual(emptySuccessResult, PortScanResult.success)
        
        // Failure result
        let failureResult = PortScanResult.failure("Connection timeout")
        
        XCTAssertFalse(failureResult.success)
        XCTAssertTrue(failureResult.ports.isEmpty)
        XCTAssertEqual(failureResult.error, "Connection timeout")
    }
}
