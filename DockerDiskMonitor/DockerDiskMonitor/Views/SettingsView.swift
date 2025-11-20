//
//  SettingsView.swift
//  DockerDiskMonitor
//
//  Settings interface for Docker Disk Monitor
//

import SwiftUI
import UserNotifications
import AppKit

enum SettingsTab {
    case general
    case notifications
    case about
}

struct SettingsView: View {
    @StateObject private var settings = AppSettings.shared
    @State private var launchAtLogin = LaunchAtLoginManager.shared.isEnabled
    @State private var notificationStatus: UNAuthorizationStatus = .notDetermined
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var showTestNotificationSent = false
    @State private var selectedTab: SettingsTab = .general

    var body: some View {
        TabView(selection: $selectedTab) {
            GeneralSettingsView(
                settings: settings,
                launchAtLogin: $launchAtLogin,
                showError: $showError,
                errorMessage: $errorMessage
            )
            .tabItem {
                Label("General", systemImage: "gear")
            }
            .tag(SettingsTab.general)

            NotificationsSettingsView(
                settings: settings,
                notificationStatus: $notificationStatus,
                showTestNotificationSent: $showTestNotificationSent
            )
            .tabItem {
                Label("Notifications", systemImage: "bell")
            }
            .tag(SettingsTab.notifications)

            AboutSettingsView()
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
                .tag(SettingsTab.about)
        }
        .frame(width: 500)
        .onAppear {
            Task {
                notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
            }
            // Set initial height
            resizeWindow(for: selectedTab)
        }
        .onChange(of: selectedTab) { newTab in
            resizeWindow(for: newTab)
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }

    private func resizeWindow(for tab: SettingsTab) {
        let height: CGFloat = switch tab {
        case .general: 400
        case .notifications: 550
        case .about: 450
        }

        // Find the settings window
        DispatchQueue.main.async {
            if let window = NSApp.windows.first(where: { $0.title == "Docker Disk Monitor Settings" }) {
                var frame = window.frame
                let heightDiff = height - frame.size.height
                frame.origin.y -= heightDiff  // Keep top edge fixed
                frame.size.height = height
                window.setFrame(frame, display: true, animate: true)
            }
        }
    }
}

// MARK: - General Settings

struct GeneralSettingsView: View {
    @ObservedObject var settings: AppSettings
    @Binding var launchAtLogin: Bool
    @Binding var showError: Bool
    @Binding var errorMessage: String

    var body: some View {
        Form {
            Section {
                Picker("Check Interval", selection: $settings.checkInterval) {
                    Text("1 minute").tag(60)
                    Text("5 minutes").tag(300)
                    Text("10 minutes").tag(600)
                    Text("15 minutes").tag(900)
                    Text("30 minutes").tag(1800)
                }
                .help("How often to check Docker disk usage")

                Toggle("Launch at Login", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { newValue in
                        do {
                            try LaunchAtLoginManager.shared.setEnabled(newValue)
                        } catch {
                            errorMessage = error.localizedDescription
                            showError = true
                            launchAtLogin = !newValue // Revert
                        }
                    }
                    .help("Automatically start Docker Disk Monitor when you log in")
            } header: {
                Text("General")
            }

            Section {
                if let dockerPath = settings.dockerPath {
                    HStack {
                        Text("Docker Path:")
                        Spacer()
                        Text(dockerPath)
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                } else {
                    Text("Docker path not detected")
                        .foregroundColor(.secondary)
                }
            } header: {
                Text("Docker Configuration")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Notifications Settings

struct NotificationsSettingsView: View {
    @ObservedObject var settings: AppSettings
    @Binding var notificationStatus: UNAuthorizationStatus
    @Binding var showTestNotificationSent: Bool

    var body: some View {
        Form {
            Section {
                Toggle("Enable Disk Notifications", isOn: $settings.notificationsEnabled)
                    .help("Send notifications when disk usage reaches warning thresholds")

                if notificationStatus == .denied {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("Notifications are disabled in System Settings")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)

                    Button("Open System Settings") {
                        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.notifications") {
                            NSWorkspace.shared.open(url)
                        }
                    }
                    .buttonStyle(.link)
                } else if notificationStatus == .notDetermined {
                    Button("Request Notification Permission") {
                        Task {
                            _ = try? await NotificationManager.shared.requestAuthorization()
                            notificationStatus = await NotificationManager.shared.checkAuthorizationStatus()
                        }
                    }
                }
            } header: {
                Text("Notification Settings")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Warning Threshold:")
                        Spacer()
                        Text("\(settings.warningThreshold)%")
                            .foregroundColor(.orange)
                            .fontWeight(.medium)
                    }

                    Slider(
                        value: Binding(
                            get: { Double(settings.warningThreshold) },
                            set: { settings.warningThreshold = Int($0) }
                        ),
                        in: 50...89,
                        step: 5
                    )
                    .disabled(!settings.notificationsEnabled)

                    Text("You'll receive a warning notification when disk usage reaches this percentage")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("Critical Threshold:")
                        Spacer()
                        Text("\(settings.criticalThreshold)%")
                            .foregroundColor(.red)
                            .fontWeight(.medium)
                    }

                    Text("Fixed at \(settings.criticalThreshold)% - You'll receive a critical alert when disk is nearly full")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)

            } header: {
                Text("Alert Thresholds")
            } footer: {
                Text("Notifications are sent when crossing a threshold and at most once per hour to avoid spam.")
                    .font(.caption)
            }

            Section {
                Button("Send Test Notification") {
                    Task {
                        await NotificationManager.shared.sendTestNotification()
                        showTestNotificationSent = true

                        // Auto-hide after 2 seconds
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            showTestNotificationSent = false
                        }
                    }
                }
                .disabled(notificationStatus != .authorized)

                if showTestNotificationSent {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Test notification sent!")
                            .font(.caption)
                    }
                }
            } header: {
                Text("Testing")
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - About Settings

struct AboutSettingsView: View {
    var body: some View {
        VStack(spacing: 20) {
            // Use the actual app icon
            if let appIcon = NSImage(named: "AppIcon") {
                Image(nsImage: appIcon)
                    .resizable()
                    .frame(width: 128, height: 128)
            } else {
                Image(systemName: "gauge.with.dots.needle.67percent")
                    .font(.system(size: 64))
                    .foregroundColor(.accentColor)
            }

            Text("Docker Disk Monitor")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Version 1.0.0")
                .foregroundColor(.secondary)

            Divider()
                .padding(.horizontal, 60)

            VStack(alignment: .leading, spacing: 8) {
                Text("Monitor your Docker disk usage from the menu bar")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("Built with Swift and SwiftUI")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
}
