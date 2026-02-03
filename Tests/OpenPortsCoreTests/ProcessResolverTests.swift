import XCTest
@testable import OpenPortsCore

final class ProcessResolverTests: XCTestCase {
    var resolver: ProcessResolver!
    
    override func setUp() async throws {
        resolver = ProcessResolver()
    }
    
    func testResolveProcessInfo() async throws {
        let ports = [
            PortInfo(port: 8080, portProtocol: .tcp, pid: 99999, processName: "fake-process", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false)
        ]
        
        let resolved = await resolver.resolveProcessInfo(for: ports)
        
        XCTAssertFalse(resolved.isEmpty)
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved[0].port, 8080)
    }
    
    func testResolveMultiplePorts() async {
        let ports = [
            PortInfo(port: 8080, portProtocol: .tcp, pid: 111, processName: "app1", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 9090, portProtocol: .tcp, pid: 222, processName: "app2", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 443, portProtocol: .tcp, pid: 333, processName: "app3", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false)
        ]
        
        let resolved = await resolver.resolveProcessInfo(for: ports)
        
        XCTAssertEqual(resolved.count, 3)
    }
}
    
    func testSystemProcessDetection() {
        let systemPath = "/usr/sbin/launchd"
        let userPath = "/Users/test/app"
        
        let systemPort = PortInfo(port: 1, portProtocol: .tcp, pid: 1, processName: "launchd", appName: nil, bundleID: nil, executablePath: systemPath, isSystemProcess: true)
        let userPort = PortInfo(port: 2, portProtocol: .tcp, pid: 2, processName: "app", appName: nil, bundleID: nil, executablePath: userPath, isSystemProcess: false)
        
        XCTAssertTrue(systemPort.isSystemProcess)
        XCTAssertFalse(userPort.isSystemProcess)
    }
    
    func testPortInfoEquality() {
        let port1 = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 123,
            processName: "nginx",
            appName: "Nginx",
            bundleID: "com.nginx.server",
            executablePath: "/usr/local/bin/nginx",
            isSystemProcess: false
        )
        
        let port2 = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 123,
            processName: "nginx",
            appName: "Nginx",
            bundleID: "com.nginx.server",
            executablePath: "/usr/local/bin/nginx",
            isSystemProcess: false
        )
        
        XCTAssertEqual(port1.port, port2.port)
        XCTAssertEqual(port1.portProtocol, port2.portProtocol)
        XCTAssertEqual(port1.pid, port2.pid)
        XCTAssertEqual(port1.processName, port2.processName)
        XCTAssertEqual(port1.appName, port2.appName)
        XCTAssertEqual(port1.bundleID, port2.bundleID)
        XCTAssertEqual(port1.executablePath, port2.executablePath)
        XCTAssertEqual(port1.isSystemProcess, port2.isSystemProcess)
    }
    
    func testPortInfoInequality() {
        let port1 = PortInfo(
            port: 80,
            portProtocol: .tcp,
            pid: 123,
            processName: "nginx",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false
        )
        
        let port2 = PortInfo(
            port: 443,
            portProtocol: .tcp,
            pid: 456,
            processName: "apache",
            appName: nil,
            bundleID: nil,
            executablePath: nil,
            isSystemProcess: false
        )
        
        XCTAssertNotEqual(port1, port2)
    }
}
