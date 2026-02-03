import SwiftUI

struct EmptyView: View {
    var body: some View {
        Text("")
            .frame(width: 1, height: 1)
    }
}

@main
struct AppEntryPoint: App {
    var body: some Scene {
        WindowGroup {
            EmptyView()
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
    }
}
