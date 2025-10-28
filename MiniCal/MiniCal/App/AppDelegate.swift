//
//  AppDelegate.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Cocoa
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    private let themeManager = ThemeManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let complete = Logger.measureTimeAsync(operation: "Application startup", category: Logger.performance)

        // Initialize theme manager first
        // ThemeManager will automatically load themes and apply the saved theme
        Logger.info("Application launched, ThemeManager initialized", category: Logger.app)

        // Initialize menu bar controller
        menuBarController = MenuBarController()

        Logger.info("MenuBar controller initialized", category: Logger.app)

        complete()

        // Request calendar access in background (non-blocking)
        Task.detached(priority: .background) {
            _ = await EventService.shared.requestAuthorization()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Cleanup theme manager
        themeManager.stopObservingSystemAppearance()
    }
}
