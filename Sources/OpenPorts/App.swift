import SwiftUI
import AppKit
import OpenPortsCore

@main
struct OpenPortsApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        EmptyScene()
    }
}

struct EmptyScene: Scene {
    var body: some Scene {
        WindowGroup {
            Text("")
                .frame(width: 0, height: 0)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 0, height: 0)
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItemController: StatusItemController?
    private var menuViewModel: MenuViewModel?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up app to not show dock icon (menu bar only app)
        NSApp.setActivationPolicy(.accessory)
        
        // Initialize the process manager
        let processManager = ProcessManager()
        
        // Initialize the status item controller
        let statusItemController = StatusItemController()
        self.statusItemController = statusItemController
        
        // Initialize the menu view model with dependencies
        let menuViewModel = MenuViewModel(
            portScanner: PortScanner(),
            processResolver: ProcessResolver(),
            processManager: processManager
        )
        self.menuViewModel = menuViewModel
        
        // Connect the view model with the status item controller
        menuViewModel.statusItemController = statusItemController
        
        // Set initial preferences
        UserDefaults.standard.register(defaults: [
            "refreshInterval": 5.0,
            "showSystemProcesses": true,
            "groupPorts": false
        ])
        
        print("OpenPorts started successfully")
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Keep the app running even when all windows are closed
        return false
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        print("OpenPorts is terminating")
    }
}
