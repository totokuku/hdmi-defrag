import AppKit
import CoreGraphics

/// The dithering flag resets whenever a display connects/reconnects, and (empirically)
/// can also reset across sleep/wake, so we watch both and debounce a reapply.
final class DisplayWatcher {
    var onNeedsReapply: (() -> Void)?

    private var reapplyTimer: Timer?
    private var started = false

    private static let callback: CGDisplayReconfigurationCallBack = { _, flags, userInfo in
        guard let userInfo else { return }
        let watcher = Unmanaged<DisplayWatcher>.fromOpaque(userInfo).takeUnretainedValue()
        let relevant: CGDisplayChangeSummaryFlags = [.addFlag, .removeFlag, .enabledFlag, .disabledFlag]
        if !flags.intersection(relevant).isEmpty {
            watcher.scheduleReapply()
        }
    }

    func start() {
        guard !started else { return }
        started = true

        let observer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(Self.callback, observer)

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWake),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )
    }

    func stop() {
        guard started else { return }
        started = false

        let observer = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRemoveReconfigurationCallback(Self.callback, observer)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
        reapplyTimer?.invalidate()
    }

    @objc private func handleWake() {
        scheduleReapply()
    }

    private func scheduleReapply() {
        reapplyTimer?.invalidate()
        // Give the display pipeline a moment to settle after connect/wake before we poke it.
        reapplyTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) { [weak self] _ in
            self?.onNeedsReapply?()
        }
    }

    deinit {
        stop()
    }
}
