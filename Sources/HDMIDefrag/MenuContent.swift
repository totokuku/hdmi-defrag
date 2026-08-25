import AppKit
import SwiftUI

struct MenuContent: View {
    @ObservedObject var state: AppState

    var body: some View {
        Toggle(
            "Fix HDMI Flicker (disable dithering)",
            isOn: Binding(
                get: { state.ditheringDisabled },
                set: { state.setDitheringDisabled($0) }
            )
        )

        statusLabel
            .font(.caption)

        Divider()

        Toggle(
            "Launch at Login",
            isOn: Binding(
                get: { state.launchAtLogin },
                set: { state.setLaunchAtLogin($0) }
            )
        )

        Button("Re-apply Now") { state.apply() }

        Divider()

        Button("Quit HDMI Defrag") {
            NSApplication.shared.terminate(nil)
        }
        .keyboardShortcut("q")
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch state.verifiedDisabled {
        case .some(true):
            Label("Verified: dithering off", systemImage: "checkmark.circle")
                .foregroundStyle(.secondary)
        case .some(false):
            Label("Dithering still on, try Re-apply", systemImage: "exclamationmark.triangle")
                .foregroundStyle(.orange)
        case .none:
            Label("No displays detected", systemImage: "questionmark.circle")
                .foregroundStyle(.secondary)
        }
    }
}
