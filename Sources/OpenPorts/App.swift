import AppKit
import OpenPortsCore
import SwiftUI

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

    func applicationDidFinishLaunching(_: Notification) {
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
            processManager: processManager,
        )
        self.menuViewModel = menuViewModel

        // Connect the view model with the status item controller
        // IMPORTANT: This must happen BEFORE starting the refresh cycle
        menuViewModel.statusItemController = statusItemController

        // Show initial loading state immediately
        menuViewModel.updateMenuWithLoadingState()

        // Register initial defaults before loading user preferences.
        AppSettings.registerDefaults()

        // Now trigger the first refresh (manual only - no auto-refresh)
        menuViewModel.refreshPorts()

        print("OpenPorts started successfully")
    }

    func applicationShouldTerminateAfterLastWindowClosed(_: NSApplication) -> Bool {
        // Keep the app running even when all windows are closed
        false
    }

    func applicationWillTerminate(_: Notification) {
        print("OpenPorts is terminating")
    }
}
