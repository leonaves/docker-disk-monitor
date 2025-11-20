//
//  NotificationManager.swift
//  DockerDiskMonitor
//
//  Manages user notifications for disk usage alerts
//

import Foundation
import AppKit
import UserNotifications

enum AlertLevel: String {
    case warning
    case critical

    var notificationSound: UNNotificationSound {
        switch self {
        case .warning:
            return .default
        case .critical:
            return .defaultCritical
        }
    }
}

class NotificationManager: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationManager()

    private override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        setupNotificationCategories()
    }

    // MARK: - Authorization

    func requestAuthorization() async throws -> Bool {
        return try await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge])
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }

    func isAuthorized() async -> Bool {
        let status = await checkAuthorizationStatus()
        return status == .authorized || status == .provisional
    }

    // MARK: - Sending Notifications

    func sendDiskWarning(percentage: Int, level: AlertLevel) async {
        // Check authorization first
        guard await isAuthorized() else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Docker Disk Usage \(level == .critical ? "Critical" : "Warning")"

        if level == .critical {
            content.body = "Docker disk is at \(percentage)% capacity! Consider cleaning up images and containers."
        } else {
            content.body = "Docker disk usage is at \(percentage)%. You may want to clean up soon."
        }

        content.sound = level.notificationSound
        content.categoryIdentifier = "docker-disk-\(level.rawValue)"

        // Make notification time-sensitive to break through Focus modes
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = level == .critical ? 1.0 : 0.8

        // Add actions
        content.userInfo = ["percentage": percentage, "level": level.rawValue]

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silent failure
        }
    }

    func sendTestNotification() async {
        // Check authorization first
        let status = await checkAuthorizationStatus()

        guard status == .authorized else {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "Test Notification"
        content.body = "Docker Disk Monitor notifications are working correctly!"
        content.sound = .default

        // Make test notification time-sensitive too
        content.interruptionLevel = .timeSensitive
        content.relevanceScore = 0.7

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        do {
            try await UNUserNotificationCenter.current().add(request)
        } catch {
            // Silent failure
        }
    }

    // MARK: - Notification Categories

    private func setupNotificationCategories() {
        let openDockerAction = UNNotificationAction(
            identifier: "OPEN_DOCKER",
            title: "Open Docker Desktop",
            options: .foreground
        )

        let warningCategory = UNNotificationCategory(
            identifier: "docker-disk-warning",
            actions: [openDockerAction],
            intentIdentifiers: [],
            options: []
        )

        let criticalCategory = UNNotificationCategory(
            identifier: "docker-disk-critical",
            actions: [openDockerAction],
            intentIdentifiers: [],
            options: []
        )

        UNUserNotificationCenter.current().setNotificationCategories([
            warningCategory,
            criticalCategory
        ])
    }

    // MARK: - UNUserNotificationCenterDelegate

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.actionIdentifier == "OPEN_DOCKER" {
            // Try to open Docker Desktop
            if let dockerDesktopURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.docker.docker") {
                NSWorkspace.shared.open(dockerDesktopURL)
            }
        }

        completionHandler()
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
}
