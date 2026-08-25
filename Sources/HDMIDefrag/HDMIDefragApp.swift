import AppKit
import SwiftUI

@main
struct HDMIDefragApp: App {
    @StateObject private var state = AppState()

    init() {
        // Toggling "Launch at Login" makes launchctl RunAtLoad-start a fresh instance
        // right away, on top of whichever instance is already running. Bail out before
        // the menu bar item is created if we're not the only one.
        if Self.anotherInstanceIsRunning() {
            exit(0)
        }

        // No Info.plist LSUIElement when run outside a bundle (e.g. `swift run`),
        // so set the activation policy directly: menu bar only, no Dock icon.
        NSApplication.shared.setActivationPolicy(.accessory)
    }

    var body: some Scene {
        MenuBarExtra(
            "HDMI Defrag",
            // waveform = the pixel value oscillating; slashed = that oscillation stopped
            systemImage: state.ditheringDisabled ? "waveform.slash" : "waveform"
        ) {
            MenuContent(state: state)
        }
        .menuBarExtraStyle(.menu)
    }

    private static func anotherInstanceIsRunning() -> Bool {
        guard let bundleID = Bundle.main.bundleIdentifier else { return false }
        let currentPID = ProcessInfo.processInfo.processIdentifier
        return NSWorkspace.shared.runningApplications.contains {
            $0.bundleIdentifier == bundleID && $0.processIdentifier != currentPID
        }
    }
}
