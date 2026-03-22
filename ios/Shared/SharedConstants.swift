// SharedConstants.swift
// Included in both the main app target and the CallDirectoryExtension target.
// Both targets must have the same App Group configured in Signing & Capabilities.

enum SharedConstants {
    /// The App Group identifier — must match exactly what is configured in Xcode
    /// for both the CallBlocker and CallDirectoryExtension targets.
    static let appGroupID = "group.com.callblocker.app"

    /// UserDefaults key for the JSON-encoded [BlockRule] array
    static let rulesKey = "blocked_rules_v1"

    /// UserDefaults key for the last sync timestamp (TimeInterval)
    static let lastSyncKey = "last_sync_timestamp"

    /// Bundle identifier of the CallDirectoryExtension target
    static let extensionBundleID = "com.callblocker.app.CallDirectoryExtension"
}
