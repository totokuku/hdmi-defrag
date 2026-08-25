import Combine
import Foundation
import HDMIDefragCore

@MainActor
final class AppState: ObservableObject {
    private enum Keys {
        static let ditheringDisabled = "ditheringDisabled"
    }

    @Published private(set) var ditheringDisabled: Bool
    @Published private(set) var launchAtLogin: Bool

    /// What the IORegistry actually reports right now, read back after every apply.
    /// nil means "no displays found", not "unknown". See DisplayDither.currentlyDisabled.
    @Published private(set) var verifiedDisabled: Bool?

    private let watcher = DisplayWatcher()

    init() {
        ditheringDisabled = UserDefaults.standard.object(forKey: Keys.ditheringDisabled) as? Bool ?? true
        launchAtLogin = LoginItem.isEnabled

        apply()

        watcher.onNeedsReapply = { [weak self] in self?.apply() }
        watcher.start()
    }

    func setDitheringDisabled(_ disabled: Bool) {
        ditheringDisabled = disabled
        UserDefaults.standard.set(disabled, forKey: Keys.ditheringDisabled)
        apply()
    }

    func setLaunchAtLogin(_ enabled: Bool) {
        launchAtLogin = enabled
        LoginItem.setEnabled(enabled)
    }

    func apply() {
        DisplayDither.setDitherDisabled(ditheringDisabled)
        verifiedDisabled = DisplayDither.currentlyDisabled()
    }
}
