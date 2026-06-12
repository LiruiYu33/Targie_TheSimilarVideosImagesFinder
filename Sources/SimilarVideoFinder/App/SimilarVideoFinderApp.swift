import AppKit
import SwiftUI

enum AppIdentity {
    static let displayName = "Targie"
    static let bundleIdentifier = "local.aaronyu.SimilarVideoFinder"
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        let application = notification.object as? NSApplication ?? NSApplication.shared
        application.setActivationPolicy(.regular)
        application.activate(ignoringOtherApps: true)
    }
}

@main
struct SimilarVideoFinderApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup(AppIdentity.displayName) {
            ContentView()
                .frame(minWidth: 960, minHeight: 600)
        }
        .defaultSize(width: 1180, height: 720)
    }
}
