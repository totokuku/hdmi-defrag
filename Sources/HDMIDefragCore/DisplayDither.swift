import Foundation
import IOKit
import os.log

public enum DisplayScope {
    case all, builtIn, external
}

/// Flips the GPU/DCP "enableDither" property that IOMobileFramebufferAP exposes
/// per display. This is the temporal dithering (FRC) that shows up as visible
/// flicker/noise over HDMI on Apple silicon Macs -- most famously on the M4 Mac mini.
/// Same mechanism as Stillcolor (https://github.com/aiaf/Stillcolor), reimplemented here.
public enum DisplayDither {
    private static let log = Logger(subsystem: "com.tomkucy.hdmidefrag", category: "IOKit")

    /// Sets dithering disabled/enabled on every matching display.
    /// - Returns: number of display services successfully updated (or already in the desired state).
    @discardableResult
    public static func setDitherDisabled(_ disabled: Bool, scope: DisplayScope = .all, property: String = "enableDither") -> Int {
        forEachFramebuffer(scope: scope) { service, _ in
            let desired: CFBoolean = disabled ? kCFBooleanFalse : kCFBooleanTrue
            if let current = IORegistryProperty.value(forKey: property, on: service), CFEqual(current, desired) {
                return true
            }

            let result = IORegistryEntrySetCFProperty(service, property as CFString, desired)
            if result == KERN_SUCCESS {
                log.info("Set \(property, privacy: .public) = \(disabled ? "No" : "Yes", privacy: .public)")
                return true
            } else {
                log.error("Failed to set \(property, privacy: .public): kern_return_t \(result)")
                return false
            }
        }
    }

    /// Reads back the current state directly from the IORegistry (doesn't trust our own
    /// last-known state) so the UI can show what's actually true, not just what we tried to set.
    /// Returns nil if no displays were found, true if dithering is off on all of them,
    /// false if at least one display still has it on.
    public static func currentlyDisabled(property: String = "enableDither") -> Bool? {
        var sawAny = false
        var anyStillEnabled = false

        forEachFramebuffer(scope: .all) { service, _ in
            sawAny = true
            if let enabled = IORegistryProperty.bool(forKey: property, on: service), enabled {
                anyStillEnabled = true
            }
            return true
        }

        guard sawAny else { return nil }
        return !anyStillEnabled
    }

    /// Iterates IOMobileFramebufferAP services, filtered by `scope`. `body` receives the
    /// service (do not release it) and whether it's an external display; return false from
    /// `body` to record a failure without stopping iteration over the remaining displays.
    @discardableResult
    private static func forEachFramebuffer(scope: DisplayScope, _ body: (io_service_t, Bool) -> Bool) -> Int {
        var iterator = io_iterator_t()
        let matchResult = IOServiceGetMatchingServices(kIOMainPortDefault, IOServiceMatching("IOMobileFramebufferAP"), &iterator)
        guard matchResult == KERN_SUCCESS else {
            log.error("IOServiceGetMatchingServices failed: kern_return_t \(matchResult)")
            return 0
        }
        defer { IOObjectRelease(iterator) }

        var succeeded = 0
        while true {
            let service = IOIteratorNext(iterator)
            if service == IO_OBJECT_NULL { break }
            defer { IOObjectRelease(service) }

            let isExternal = IORegistryProperty.bool(forKey: "external", on: service) ?? false
            if scope == .builtIn && isExternal { continue }
            if scope == .external && !isExternal { continue }

            if body(service, isExternal) {
                succeeded += 1
            }
        }
        return succeeded
    }
}
