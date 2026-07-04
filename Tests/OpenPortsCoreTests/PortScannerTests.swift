@testable import OpenPortsCore
import XCTest

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
            isSystemProcess: false,
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
            isSystemProcess: false,
        )

        XCTAssertEqual(portInfo.displayName, "node")
        XCTAssertNil(portInfo.displayPath)
    }

    func testPortScanResultSuccess() {
        let ports = [
            PortInfo(port: 80, portProtocol: .tcp, pid: 1, processName: "test1", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 443, portProtocol: .tcp, pid: 2, processName: "test2", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
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
            PortInfo(port: 8080, portProtocol: .tcp, pid: 99999, processName: "fake-process", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
        ]

        let resolved = await resolver.resolveProcessInfo(for: ports)

        XCTAssertFalse(resolved.isEmpty)
        XCTAssertEqual(resolved.count, 1)
        XCTAssertEqual(resolved[0].port, 8080)
    }

    func testParseLsofLineTCP() async {
        let scanner = PortScanner()
        let line = "node      1234 mohana   23u  IPv6 0xabcdef      0t0  TCP *:3000 (LISTEN)"

        let port = await scanner.parseLsofLine(line, portProtocol: .tcp)

        XCTAssertNotNil(port)
        XCTAssertEqual(port?.port, 3000)
        XCTAssertEqual(port?.portProtocol, .tcp)
        XCTAssertEqual(port?.pid, 1234)
        XCTAssertEqual(port?.processName, "node")
    }

    func testParseLsofLineUDP() async {
        let scanner = PortScanner()
        let line = "rapportd   595 mohana    8u  IPv4 0xabcdef      0t0  UDP *:49158"

        let port = await scanner.parseLsofLine(line, portProtocol: .udp)

        XCTAssertNotNil(port)
        XCTAssertEqual(port?.port, 49158)
        XCTAssertEqual(port?.portProtocol, .udp)
        XCTAssertEqual(port?.pid, 595)
        XCTAssertEqual(port?.processName, "rapportd")
    }

    func testParseLsofLineSkipsConnectedUDPSocket() async {
        let scanner = PortScanner()
        let line = "Spotify    612 mohana  118u  IPv4 0xabcdef      0t0  UDP 192.168.1.7:60401->142.250.74.174:443"

        let port = await scanner.parseLsofLine(line, portProtocol: .udp)

        XCTAssertNil(port)
    }

    func testParseLsofLineSkipsWildcardUDPBinding() async {
        let scanner = PortScanner()
        let line = "mDNSRespo  325 _mdnsresponder 10u  IPv4 0xabcdef      0t0  UDP *:*"

        let port = await scanner.parseLsofLine(line, portProtocol: .udp)

        XCTAssertNil(port)
    }

    func testParseLsofLineParsesIPv6Binding() async {
        let scanner = PortScanner()
        let line = "ControlCe  617 mohana    9u  IPv6 0xabcdef      0t0  TCP [::1]:42050 (LISTEN)"

        let port = await scanner.parseLsofLine(line, portProtocol: .tcp)

        XCTAssertNotNil(port)
        XCTAssertEqual(port?.port, 42050)
    }

    func testDeduplicationKeepsSamePortAcrossProtocols() async {
        let scanner = PortScanner()
        let ports: [PortInfo] = [
            PortInfo(port: 53, portProtocol: .tcp, pid: 100, processName: "dnsmasq", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 53, portProtocol: .udp, pid: 100, processName: "dnsmasq", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
        ]

        let deduplicated = await scanner.deduplicatePorts(ports)

        XCTAssertEqual(deduplicated.count, 2)
    }

    func testPortScannerDeduplicatesSamePIDAndPort() async {
        let scanner = PortScanner()
        let ports: [PortInfo] = [
            PortInfo(port: 5000, portProtocol: .tcp, pid: 100, processName: "python", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 5000, portProtocol: .tcp, pid: 100, processName: "python", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 5000, portProtocol: .tcp, pid: 101, processName: "python", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
            PortInfo(port: 7000, portProtocol: .tcp, pid: 100, processName: "python", appName: nil, bundleID: nil, executablePath: nil, isSystemProcess: false),
        ]

        let deduplicated = await scanner.deduplicatePorts(ports)
        XCTAssertEqual(deduplicated.count, 3)
        XCTAssertEqual(deduplicated[0].pid, 100)
        XCTAssertEqual(deduplicated[0].port, 5000)
        XCTAssertEqual(deduplicated[1].pid, 101)
        XCTAssertEqual(deduplicated[1].port, 5000)
        XCTAssertEqual(deduplicated[2].pid, 100)
        XCTAssertEqual(deduplicated[2].port, 7000)
    }
}
