//
//  AppSettings.swift
//  DockerDiskMonitor
//
//  User preferences and settings management
//

import Foundation
import Combine

class AppSettings: ObservableObject {
    static let shared = AppSettings()

    @Published var warningThreshold: Int {
        didSet {
            UserDefaults.standard.set(warningThreshold, forKey: Keys.warningThreshold)
        }
    }

    @Published var criticalThreshold: Int {
        didSet {
            UserDefaults.standard.set(criticalThreshold, forKey: Keys.criticalThreshold)
        }
    }

    @Published var notificationsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(notificationsEnabled, forKey: Keys.notificationsEnabled)
        }
    }

    @Published var checkInterval: Int {
        didSet {
            UserDefaults.standard.set(checkInterval, forKey: Keys.checkInterval)
            NotificationCenter.default.post(name: .checkIntervalChanged, object: checkInterval)
        }
    }

    @Published var dockerPath: String? {
        didSet {
            UserDefaults.standard.set(dockerPath, forKey: Keys.dockerPath)
        }
    }

    private init() {
        // Register defaults
        UserDefaults.standard.register(defaults: [
            Keys.warningThreshold: 75,
            Keys.criticalThreshold: 90,
            Keys.notificationsEnabled: true,
            Keys.checkInterval: 300
        ])

        // Load values
        self.warningThreshold = UserDefaults.standard.integer(forKey: Keys.warningThreshold)
        self.criticalThreshold = UserDefaults.standard.integer(forKey: Keys.criticalThreshold)
        self.notificationsEnabled = UserDefaults.standard.bool(forKey: Keys.notificationsEnabled)
        self.checkInterval = UserDefaults.standard.integer(forKey: Keys.checkInterval)
        self.dockerPath = UserDefaults.standard.string(forKey: Keys.dockerPath)
    }

    private struct Keys {
        static let warningThreshold = "warningThreshold"
        static let criticalThreshold = "criticalThreshold"
        static let notificationsEnabled = "notificationsEnabled"
        static let checkInterval = "checkInterval"
        static let dockerPath = "dockerPath"
        static let lastNotificationPercentage = "lastNotificationPercentage"
        static let lastNotificationDate = "lastNotificationDate"
    }

    // Notification throttling
    func shouldSendNotification(forPercentage percentage: Int, force: Bool = false) -> Bool {
        // If forced (manual refresh), just check if over threshold
        if force {
            if percentage >= warningThreshold {
                UserDefaults.standard.set(percentage, forKey: Keys.lastNotificationPercentage)
                UserDefaults.standard.set(Date(), forKey: Keys.lastNotificationDate)
                return true
            }
            return false
        }

        let lastPercentage = UserDefaults.standard.integer(forKey: Keys.lastNotificationPercentage)
        let lastDate = UserDefaults.standard.object(forKey: Keys.lastNotificationDate) as? Date

        // Send if percentage crossed a threshold
        let crossedThreshold = (lastPercentage < warningThreshold && percentage >= warningThreshold) ||
                              (lastPercentage < criticalThreshold && percentage >= criticalThreshold)

        // Or if it's been more than 1 hour since last notification
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let enoughTimePassed = lastDate == nil || lastDate! < oneHourAgo

        if crossedThreshold || (enoughTimePassed && percentage >= warningThreshold) {
            UserDefaults.standard.set(percentage, forKey: Keys.lastNotificationPercentage)
            UserDefaults.standard.set(Date(), forKey: Keys.lastNotificationDate)
            return true
        }

        return false
    }
}

extension Notification.Name {
    static let checkIntervalChanged = Notification.Name("checkIntervalChanged")
}
