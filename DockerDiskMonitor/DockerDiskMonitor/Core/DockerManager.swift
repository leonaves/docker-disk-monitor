//
//  DockerManager.swift
//  DockerDiskMonitor
//
//  Manages Docker interactions and disk usage monitoring
//

import Foundation
import Combine

enum DockerError: Error, LocalizedError {
    case dockerNotFound
    case dockerNotRunning
    case commandFailed(String)
    case parsingFailed

    var errorDescription: String? {
        switch self {
        case .dockerNotFound:
            return "Docker is not installed or not found in PATH"
        case .dockerNotRunning:
            return "Docker daemon is not running"
        case .commandFailed(let message):
            return "Docker command failed: \(message)"
        case .parsingFailed:
            return "Failed to parse Docker disk usage"
        }
    }
}

class DockerManager: ObservableObject {
    static let shared = DockerManager()

    @Published var currentUsage: DiskUsage?
    @Published var dockerStatus: DockerStatus = .unknown
    @Published var lastError: DockerError?

    private var timer: Timer?
    private let settings = AppSettings.shared

    enum DockerStatus {
        case unknown
        case running
        case notInstalled
        case notRunning
    }

    private init() {
        // Find Docker on initialization
        Task {
            await findDockerPath()
        }

        // Listen for interval changes
        NotificationCenter.default.addObserver(
            forName: .checkIntervalChanged,
            object: nil,
            queue: .main
        ) { [weak self] notification in
            if let interval = notification.object as? Int {
                self?.startMonitoring(interval: TimeInterval(interval))
            }
        }
    }

    // MARK: - Docker Path Detection

    private func findDockerPath() async {
        // Check cached path first
        if let cachedPath = settings.dockerPath,
           FileManager.default.fileExists(atPath: cachedPath) {
            return
        }

        // Common Docker installation paths
        let possiblePaths = [
            "/usr/local/bin/docker",
            "/opt/homebrew/bin/docker",
            "/usr/bin/docker"
        ]

        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                settings.dockerPath = path
                return
            }
        }

        // Try to find using 'which'
        if let path = try? await executeCommand(
            executable: "/usr/bin/which",
            arguments: ["docker"]
        ).trimmingCharacters(in: .whitespacesAndNewlines), !path.isEmpty {
            settings.dockerPath = path
            return
        }

        dockerStatus = .notInstalled
        lastError = .dockerNotFound
    }

    private func getDockerPath() -> String {
        return settings.dockerPath ?? "/usr/local/bin/docker"
    }

    // MARK: - Monitoring

    func startMonitoring(interval: TimeInterval = 300) {
        timer?.invalidate()

        // Initial check
        Task {
            await checkDiskUsage()
        }

        // Schedule periodic checks
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task {
                await self?.checkDiskUsage()
            }
        }

        timer?.tolerance = 10 // Allow 10 second variance for efficiency
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Docker Status Check

    func checkDockerStatus() async -> Bool {
        do {
            // Get real home directory (works now that sandbox is disabled!)
            let homeDir = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
            let dockerHost = "unix://\(homeDir)/.docker/run/docker.sock"

            let output = try await executeCommandDirect(
                executable: getDockerPath(),
                arguments: ["info"],
                environment: ["DOCKER_HOST": dockerHost]
            )

            await MainActor.run {
                dockerStatus = .running
                lastError = nil
            }
            return true
        } catch {
            await MainActor.run {
                if case DockerError.dockerNotFound = error {
                    dockerStatus = .notInstalled
                } else {
                    dockerStatus = .notRunning
                }
                lastError = error as? DockerError
            }
            return false
        }
    }

    // MARK: - Disk Usage Check

    func checkDiskUsage(force: Bool = false) async {
        // First verify Docker is running
        guard await checkDockerStatus() else {
            await MainActor.run {
                currentUsage = nil
            }
            return
        }

        do {
            // Get real home directory (works now that sandbox is disabled!)
            let homeDir = ProcessInfo.processInfo.environment["HOME"] ?? NSHomeDirectory()
            let dockerHost = "unix://\(homeDir)/.docker/run/docker.sock"
            let output = try await executeCommandDirect(
                executable: getDockerPath(),
                arguments: ["run", "--rm", "alpine", "df", "-h"],
                environment: ["DOCKER_HOST": dockerHost]
            )

            guard let usage = DiskUsageParser.parse(output) else {
                throw DockerError.parsingFailed
            }

            await MainActor.run {
                currentUsage = usage
                lastError = nil

                // Check if we should send notification
                if settings.notificationsEnabled &&
                   settings.shouldSendNotification(forPercentage: usage.usePercentage, force: force) {
                    Task {
                        await NotificationManager.shared.sendDiskWarning(
                            percentage: usage.usePercentage,
                            level: usage.isCritical ? .critical : .warning
                        )
                    }
                }
            }
        } catch {
            await MainActor.run {
                lastError = error as? DockerError
            }
        }
    }

    // MARK: - Command Execution

    private func executeCommandDirect(executable: String, arguments: [String], environment: [String: String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: executable)
            process.arguments = arguments

            // Set environment with DOCKER_HOST
            var env = ProcessInfo.processInfo.environment
            for (key, value) in environment {
                env[key] = value
            }
            process.environment = env

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()

                // Set timeout
                DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                    if process.isRunning {
                        process.terminate()
                    }
                }

                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } else {
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: DockerError.commandFailed(errorOutput))
                }
            } catch {
                continuation.resume(throwing: DockerError.commandFailed(error.localizedDescription))
            }
        }
    }

    private func executeCommandViaAppleScript(command: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            // Set DOCKER_HOST to use the user's socket directly
            let homeDir = FileManager.default.homeDirectoryForCurrentUser.path
            let dockerSocket = "\(homeDir)/.docker/run/docker.sock"

            // Try to capture both stdout and stderr
            let fullCommand = "export DOCKER_HOST=unix://\(dockerSocket); (\(command)) 2>&1"
            let escapedCommand = fullCommand.replacingOccurrences(of: "\"", with: "\\\"")

            let script = """
            do shell script "\(escapedCommand)"
            """

            var error: NSDictionary?
            if let scriptObject = NSAppleScript(source: script) {
                let output = scriptObject.executeAndReturnError(&error)

                if let error = error {
                    let errorMessage = error["NSAppleScriptErrorMessage"] as? String ?? "Unknown error"
                    continuation.resume(throwing: DockerError.commandFailed(errorMessage))
                } else {
                    let result = output.stringValue ?? ""
                    continuation.resume(returning: result)
                }
            } else {
                continuation.resume(throwing: DockerError.commandFailed("Failed to create AppleScript"))
            }
        }
    }

    private func executeCommand(executable: String, arguments: [String]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()

            // Use shell to execute with proper environment
            process.executableURL = URL(fileURLWithPath: "/bin/zsh")

            // Build the full command
            let fullCommand = ([executable] + arguments).map { arg in
                // Escape arguments with spaces
                if arg.contains(" ") {
                    return "\"\(arg)\""
                }
                return arg
            }.joined(separator: " ")

            process.arguments = ["-l", "-c", fullCommand]

            // Set environment to include user's PATH and Docker context
            var environment = ProcessInfo.processInfo.environment
            environment["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin"
            process.environment = environment

            let outputPipe = Pipe()
            let errorPipe = Pipe()
            process.standardOutput = outputPipe
            process.standardError = errorPipe

            do {
                try process.run()

                // Set timeout
                DispatchQueue.global().asyncAfter(deadline: .now() + 30) {
                    if process.isRunning {
                        process.terminate()
                    }
                }

                process.waitUntilExit()

                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()

                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    continuation.resume(returning: output)
                } else {
                    let errorOutput = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: DockerError.commandFailed(errorOutput))
                }
            } catch {
                if !FileManager.default.fileExists(atPath: executable) {
                    continuation.resume(throwing: DockerError.dockerNotFound)
                } else {
                    continuation.resume(throwing: DockerError.commandFailed(error.localizedDescription))
                }
            }
        }
    }

    deinit {
        stopMonitoring()
    }
}
