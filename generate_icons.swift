#!/usr/bin/env swift

//  generate_icons.swift
//  Generates app icons from SF Symbols
//
//  Usage: swift generate_icons.swift

import Cocoa
import AppKit

// Icon sizes needed for macOS app
let iconSizes: [(size: CGFloat, name: String)] = [
    (16, "AppIcon-16.png"),
    (32, "AppIcon-32.png"),
    (64, "AppIcon-64.png"),
    (128, "AppIcon-128.png"),
    (256, "AppIcon-256.png"),
    (512, "AppIcon-512.png"),
    (1024, "AppIcon-1024.png")
]

func generateIcon(size: CGFloat, symbolName: String, outputPath: String) -> Bool {
    let image = NSImage(size: NSSize(width: size, height: size))

    image.lockFocus()

    // Background gradient (blue to purple)
    let gradient = NSGradient(
        colors: [
            NSColor(red: 0.0, green: 0.478, blue: 1.0, alpha: 1.0),  // Blue
            NSColor(red: 0.345, green: 0.337, blue: 0.839, alpha: 1.0)  // Purple
        ]
    )
    gradient?.draw(in: NSRect(x: 0, y: 0, width: size, height: size), angle: 135)

    // Draw SF Symbol
    if let sfSymbol = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil) {
        let config = NSImage.SymbolConfiguration(pointSize: size * 0.6, weight: .medium)
        let configuredSymbol = sfSymbol.withSymbolConfiguration(config)

        if let symbolImage = configuredSymbol {
            // Center the symbol
            let symbolSize = symbolImage.size
            let x = (size - symbolSize.width) / 2
            let y = (size - symbolSize.height) / 2

            // Draw white symbol
            NSColor.white.setFill()
            let rect = NSRect(x: x, y: y, width: symbolSize.width, height: symbolSize.height)
            symbolImage.draw(in: rect)
        }
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        return false
    }

    let url = URL(fileURLWithPath: outputPath)
    do {
        try pngData.write(to: url)
        return true
    } catch {
        print("Error writing file: \(error)")
        return false
    }
}

// Main execution
let fileManager = FileManager.default
let currentPath = fileManager.currentDirectoryPath
let outputDir = "\(currentPath)/DockerDiskMonitor/Resources/Assets.xcassets/AppIcon.appiconset"

print("Generating app icons...")
print("Output directory: \(outputDir)")

// Create output directory if it doesn't exist
try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

var successCount = 0
for (size, name) in iconSizes {
    let outputPath = "\(outputDir)/\(name)"
    if generateIcon(size: size, symbolName: "gauge.with.dots.needle.67percent", outputPath: outputPath) {
        print("✓ Generated \(name)")
        successCount += 1
    } else {
        print("✗ Failed to generate \(name)")
    }
}

print("\nGenerated \(successCount)/\(iconSizes.count) icons successfully!")
print("\nNote: The icons use SF Symbols and have a blue/purple gradient background.")
print("You can customize the colors and symbol in this script if needed.")
