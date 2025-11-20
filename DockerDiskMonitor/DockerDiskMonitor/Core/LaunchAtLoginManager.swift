//
//  LaunchAtLoginManager.swift
//  DockerDiskMonitor
//
//  Manages launch at login functionality using ServiceManagement
//

import Foundation
import ServiceManagement

enum LaunchAtLoginError: Error, LocalizedError {
    case registrationFailed
    case unregistrationFailed
    case statusCheckFailed

    var errorDescription: String? {
        switch self {
        case .registrationFailed:
            return "Failed to enable launch at login"
        case .unregistrationFailed:
            return "Failed to disable launch at login"
        case .statusCheckFailed:
            return "Failed to check launch at login status"
        }
    }
}

class LaunchAtLoginManager {
    static let shared = LaunchAtLoginManager()

    private init() {}

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                if SMAppService.mainApp.status == .enabled {
                    // Already enabled
                    return
                }
                try SMAppService.mainApp.register()
            } else {
                if SMAppService.mainApp.status == .notRegistered {
                    // Already disabled
                    return
                }
                try SMAppService.mainApp.unregister()
            }
        } catch {
            throw enabled ? LaunchAtLoginError.registrationFailed : LaunchAtLoginError.unregistrationFailed
        }
    }

    var isEnabled: Bool {
        return SMAppService.mainApp.status == .enabled
    }

    var statusDescription: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "Enabled"
        case .notRegistered:
            return "Disabled"
        case .notFound:
            return "Not Found"
        case .requiresApproval:
            return "Requires Approval in System Settings"
        @unknown default:
            return "Unknown"
        }
    }
}
