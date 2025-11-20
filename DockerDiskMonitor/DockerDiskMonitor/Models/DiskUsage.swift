//
//  DiskUsage.swift
//  DockerDiskMonitor
//
//  Model representing Docker disk usage information
//

import Foundation

struct DiskUsage {
    let filesystem: String
    let size: String
    let used: String
    let available: String
    let usePercentage: Int
    let mountedOn: String

    // Computed properties for display
    var displayText: String {
        """
        Filesystem: \(filesystem)
        Size: \(size)
        Used: \(used)
        Available: \(available)
        Usage: \(usePercentage)%
        Mounted: \(mountedOn)
        """
    }

    var isWarning: Bool {
        usePercentage >= 75
    }

    var isCritical: Bool {
        usePercentage >= 90
    }
}

// Parser for 'df -h' output
struct DiskUsageParser {
    static func parse(_ output: String) -> DiskUsage? {
        let lines = output.components(separatedBy: "\n")

        // Find the line with 'overlay' filesystem (Docker's storage)
        guard let dataLine = lines.first(where: { $0.contains("overlay") || $0.contains("/") }) else {
            // If no overlay, try to parse any data line (skip header)
            guard lines.count >= 2 else { return nil }
            return parseDataLine(lines[1])
        }

        return parseDataLine(dataLine)
    }

    private static func parseDataLine(_ line: String) -> DiskUsage? {
        let components = line.components(separatedBy: .whitespaces)
            .filter { !$0.isEmpty }

        guard components.count >= 6 else { return nil }

        let percentString = components[4].replacingOccurrences(of: "%", with: "")
        let percentage = Int(percentString) ?? 0

        return DiskUsage(
            filesystem: components[0],
            size: components[1],
            used: components[2],
            available: components[3],
            usePercentage: percentage,
            mountedOn: components[5]
        )
    }
}
