//
//  AppDelegate.swift
//  DockerDiskMonitor
//
//  Manages menu bar icon and application lifecycle
//

import Cocoa
import SwiftUI
import UserNotifications
import Combine

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    private let dockerManager = DockerManager.shared
    private let notificationManager = NotificationManager.shared
    private let settings = AppSettings.shared
    private var settingsWindow: NSWindow?

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Set up status bar item
        setupStatusBar()

        // Request notification permissions
        Task {
            await requestNotificationPermissions()
        }

        // Start monitoring Docker
        dockerManager.startMonitoring(interval: TimeInterval(settings.checkInterval))

        // Subscribe to Docker status changes
        dockerManager.$currentUsage
            .receive(on: DispatchQueue.main)
            .sink { [weak self] usage in
                self?.updateMenuBarIcon(usage: usage)
            }
            .store(in: &cancellables)

        dockerManager.$dockerStatus
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                self?.updateMenuBarIcon(usage: self?.dockerManager.currentUsage)
            }
            .store(in: &cancellables)
    }

    func applicationWillTerminate(_ notification: Notification) {
        dockerManager.stopMonitoring()
    }

    // MARK: - Status Bar Setup

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let button = statusItem?.button else {
            return
        }

        // Use text icon
        button.title = "⚙︎"

        // Set up menu
        let menu = NSMenu()
        menu.delegate = self

        statusItem?.menu = menu
    }

    // MARK: - Menu Bar Icon Update

    private func updateMenuBarIcon(usage: DiskUsage?) {
        guard let button = statusItem?.button else { return }

        // Clear any image - we're using text only
        button.image = nil

        if dockerManager.dockerStatus != .running {
            // Docker not running - show disabled state
            button.title = "⚙︎"
            // Don't set contentTintColor - let it adapt automatically
            return
        }

        guard let usage = usage else {
            button.title = "⚙︎"
            return
        }

        // Update icon based on percentage using text/emoji
        let percentage = usage.usePercentage
        let icon: String

        switch percentage {
        case 0..<25:
            icon = "◔"  // Quarter circle
        case 25..<50:
            icon = "◑"  // Half circle
        case 50..<75:
            icon = "◕"  // Three quarter circle
        default:
            icon = "●"  // Full circle
        }

        button.title = icon

        // Don't set contentTintColor for now - let system handle it
        // TODO: Re-enable color coding once basic visibility works
    }

    // MARK: - Notification Permissions

    private func requestNotificationPermissions() async {
        let status = await notificationManager.checkAuthorizationStatus()

        if status == .notDetermined {
            _ = try? await notificationManager.requestAuthorization()
        }
    }

    // MARK: - Menu Actions

    @objc private func refreshNow() {
        Task {
            await dockerManager.checkDiskUsage(force: true)
        }
    }

    @objc private func openSettings() {
        // If window exists, bring it forward
        if let window = settingsWindow {
            window.makeKeyAndOrderFront(nil)
            window.orderFrontRegardless()
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        // Create new window (start with General tab height)
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 500, height: 400),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )
        window.title = "Docker Disk Monitor Settings"
        window.minSize = NSSize(width: 450, height: 350)
        window.isReleasedWhenClosed = false  // Keep window alive

        let hostingController = NSHostingController(rootView: SettingsView())
        window.contentViewController = hostingController

        // Center on screen
        window.center()

        self.settingsWindow = window
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    @objc private func quitApp() {
        NSApplication.shared.terminate(nil)
    }
}

// MARK: - NSMenuDelegate

extension AppDelegate: NSMenuDelegate {
    func menuWillOpen(_ menu: NSMenu) {
        menu.removeAllItems()

        // Status section
        if dockerManager.dockerStatus == .running {
            if let usage = dockerManager.currentUsage {
                // Disk usage information
                let titleItem = NSMenuItem(
                    title: "Docker Disk Usage: \(usage.usePercentage)%",
                    action: nil,
                    keyEquivalent: ""
                )
                titleItem.isEnabled = false
                menu.addItem(titleItem)

                let usedItem = NSMenuItem(
                    title: "Used: \(usage.used) of \(usage.size)",
                    action: nil,
                    keyEquivalent: ""
                )
                usedItem.isEnabled = false
                menu.addItem(usedItem)

                let availableItem = NSMenuItem(
                    title: "Available: \(usage.available)",
                    action: nil,
                    keyEquivalent: ""
                )
                availableItem.isEnabled = false
                menu.addItem(availableItem)

                let filesystemItem = NSMenuItem(
                    title: "",
                    action: nil,
                    keyEquivalent: ""
                )
                filesystemItem.isEnabled = false
                let filesystemText = "Filesystem: \(usage.filesystem)"
                filesystemItem.attributedTitle = NSAttributedString(
                    string: filesystemText,
                    attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
                )
                menu.addItem(filesystemItem)
            } else {
                let loadingItem = NSMenuItem(
                    title: "Loading...",
                    action: nil,
                    keyEquivalent: ""
                )
                loadingItem.isEnabled = false
                menu.addItem(loadingItem)
            }
        } else {
            // Docker status message
            let statusMessage: String
            switch dockerManager.dockerStatus {
            case .notInstalled:
                statusMessage = "Docker Not Installed"
            case .notRunning:
                statusMessage = "Docker Not Running"
            case .unknown:
                statusMessage = "Checking Docker Status..."
            case .running:
                statusMessage = "Docker Running"
            }

            let statusItem = NSMenuItem(title: statusMessage, action: nil, keyEquivalent: "")
            statusItem.isEnabled = false
            menu.addItem(statusItem)

            if let error = dockerManager.lastError {
                let errorItem = NSMenuItem(
                    title: "",
                    action: nil,
                    keyEquivalent: ""
                )
                errorItem.isEnabled = false
                errorItem.attributedTitle = NSAttributedString(
                    string: error.localizedDescription,
                    attributes: [.font: NSFont.systemFont(ofSize: NSFont.smallSystemFontSize)]
                )
                menu.addItem(errorItem)
            }
        }

        menu.addItem(NSMenuItem.separator())

        // Actions
        menu.addItem(NSMenuItem(
            title: "Refresh Now",
            action: #selector(refreshNow),
            keyEquivalent: "r"
        ))

        menu.addItem(NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        ))

        menu.addItem(NSMenuItem.separator())

        // Quit
        menu.addItem(NSMenuItem(
            title: "Quit Docker Disk Monitor",
            action: #selector(quitApp),
            keyEquivalent: "q"
        ))
    }
}
