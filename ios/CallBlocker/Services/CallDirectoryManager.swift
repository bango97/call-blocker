import Foundation
import CallKit

/// Wraps CXCallDirectoryManager to reload the extension after rule changes.
final class CallDirectoryManager {

    static let shared = CallDirectoryManager()
    private init() {}

    enum ReloadError: LocalizedError {
        case callKitError(Error)
        case unknown

        var errorDescription: String? {
            switch self {
            case .callKitError(let e): return "CallKit error: \(e.localizedDescription)"
            case .unknown: return "Unknown error reloading call directory."
            }
        }
    }

    /// Reloads the extension so CallKit picks up new rule changes.
    /// Must be called every time rules are saved.
    func reload(completion: @escaping (ReloadError?) -> Void) {
        CXCallDirectoryManager.sharedInstance.reloadExtension(
            withIdentifier: SharedConstants.extensionBundleID
        ) { error in
            if let error {
                completion(.callKitError(error))
            } else {
                completion(nil)
            }
        }
    }

    /// Checks whether the extension is currently enabled in Settings → Phone → Call Blocking.
    func checkExtensionStatus(completion: @escaping (CXCallDirectoryManager.EnabledStatus) -> Void) {
        CXCallDirectoryManager.sharedInstance.getEnabledStatusForExtension(
            withIdentifier: SharedConstants.extensionBundleID,
            completionHandler: { status, _ in completion(status) }
        )
    }
}
