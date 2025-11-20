//
//  DockerDiskMonitorApp.swift
//  DockerDiskMonitor
//
//  Main application entry point
//

import SwiftUI

@main
struct DockerDiskMonitorApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView()
        }
    }
}
