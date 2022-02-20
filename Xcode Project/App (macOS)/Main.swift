import SwiftUI

@main struct Main: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDeledate
    @State private var helpAlertShowing = false
    
    var body: some Scene {
        WindowGroup {
            MainWindow()
                .task { NSApplication.shared.windows.forEach { $0.styleMask = [.titled, .closable, .miniaturizable] } }
                .alert("Client Configuration ID", isPresented: self.$helpAlertShowing) { } message: {
                    Text("It can be found in 1.1.1.1 app's Settings ❯ Advanced ❯ Diagnostics under \"Client Configuration\", and it's titled \"ID.\"")
                }
        }
        .windowStyle(.hiddenTitleBar)
        .commands {
            CommandGroup(replacing: .newItem) { EmptyView() }
            CommandGroup(replacing: .help) {
                Button("Client Configuration ID") { self.helpAlertShowing = true }
            }
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSWindow.allowsAutomaticWindowTabbing = false
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
