import XCTest
@testable import OpenPortsCore

final class PortScannerTests: XCTestCase {
    
    func testPortProtocol() {
        XCTAssertEqual(PortInfo.PortProtocol.tcp.rawValue, "TCP")
        XCTAssertEqual(PortInfo.PortProtocol.udp.rawValue, "UDP")
    }
    
    func testPortInfo() {
        let portInfo = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 456,
            processName: "nginx",
            appName: "Nginx",
            bundleID: "com.nginx.server",
            executablePath: "/usr/local/bin/nginx",
            isSystemProcess: false
        )
        
        XCTAssertEqual(portInfo.port, 80)
        XCTAssertEqual(portInfo.portProtocol, .tcp)
        XCTAssertEqual(portInfo.pid, 456)
        XCTAssertEqual(portInfo.processName, "nginx")
        XCTAssertEqual(portInfo.displayName, "Nginx")
        XCTAssertEqual(portInfo.executablePath, "/usr/local/bin/nginx")
        XCTAssertFalse(portInfo.isSystemProcess)
    }
    
    func testPortInfoDefaults() {
        let portInfo = PortInfo(
            port: 3000,
            portProtocol: .tcp,
            pid: 789,
            processName: "node",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false
        )
        
        XCTAssertEqual(portInfo.displayName, "node")
        XCTAssertNil(portInfo.displayPath)
    }
    
    func testPortScanResultSuccess() {
        let ports = [
            PortInfo(port: 80, portProtocol: .tcp, pid: 1, processName: "test1", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 443, portProtocol: .tcp, pid: 2, processName: "test2", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false)
        ]
        
        let result = PortScanResult(ports: ports, success: true, error: nil)
        
        XCTAssertTrue(result.success)
        XCTAssertEqual(result.ports.count, 2)
        XCTAssertNil(result.error)
    }
    
    func testPortScanResultFailure() {
        let result = PortScanResult.failure("test error")
        
        XCTAssertFalse(result.success)
        XCTAssertTrue(result.ports.isEmpty)
        XCTAssertEqual(result.error, "test error")
    }
    
    func testProcessResolverIntegration() async {
        let resolver = ProcessResolver()
        let ports = [
            PortInfo(port: 8080, portProtocol: .tcp, pid: 99999, processName: "fake-process", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false)
        ]
        
        let resolved = await resolver.resolveProcessInfo(for: ports)
        
        XCTAssertFalse(resolved.isEmpty)
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved[0].port, 8080)
    }
}
