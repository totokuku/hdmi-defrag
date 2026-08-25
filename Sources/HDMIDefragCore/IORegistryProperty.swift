import Foundation
import IOKit

/// Thin wrapper around the IORegistry property lookup calls we need.
enum IORegistryProperty {

    /// Searches the entry and its parents in the IOService plane for `key`.
    /// Properties like "external" often live on a parent node rather than the
    /// framebuffer service itself, so this walks up rather than doing a direct lookup.
    static func value(forKey key: String, on entry: io_registry_entry_t) -> CFTypeRef? {
        IORegistryEntrySearchCFProperty(
            entry,
            kIOServicePlane,
            key as CFString,
            kCFAllocatorDefault,
            IOOptionBits(kIORegistryIterateRecursively | kIORegistryIterateParents)
        )
    }

    static func bool(forKey key: String, on entry: io_registry_entry_t) -> Bool? {
        value(forKey: key, on: entry) as? Bool
    }
}
