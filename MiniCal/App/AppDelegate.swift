//
//  AppDelegate.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Cocoa
import SwiftUI
import KeyboardShortcuts

class AppDelegate: NSObject, NSApplicationDelegate {
    var menuBarController: MenuBarController?
    private let themeManager = ThemeManager.shared
    private let settingsManager = SettingsManager.shared
    private let launchManager = LaunchAtLoginManager.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        let complete = Logger.measureTimeAsync(operation: "Application startup", category: Logger.performance)

        // Initialize theme manager first
        // ThemeManager will automatically load themes and apply the saved theme
        Logger.info("Application launched, ThemeManager initialized", category: Logger.app)

        // 应用系统设置
        applySystemSettings()

        // Initialize menu bar controller
        menuBarController = MenuBarController()

        Logger.info("MenuBar controller initialized", category: Logger.app)

        // 设置全局快捷键监听
        setupGlobalHotkey()

        // 监听设置变化
        observeSettingsChanges()

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

    // MARK: - System Settings

    private func applySystemSettings() {
        let settings = settingsManager.currentSettings

        // 隐藏 Dock 图标（默认）
        setDockIconVisibility(false)

        // 应用开机自启动设置
        launchManager.setLaunchAtLogin(settings.launchAtLogin)
    }

    private func setupGlobalHotkey() {
        // 使用 KeyboardShortcuts 监听快捷键
        KeyboardShortcuts.onKeyUp(for: .toggleCalendar) { [weak self] in
            self?.toggleCalendar()
        }

        Logger.info("Global hotkey registered using KeyboardShortcuts", category: Logger.app)
    }

    @objc private func toggleCalendar() {
        // 检查快捷键是否已启用
        guard settingsManager.currentSettings.globalHotkeyEnabled else {
            Logger.info("Global hotkey is disabled, ignoring key press", category: Logger.app)
            return
        }

        menuBarController?.togglePopover(nil)
    }

    // MARK: - Settings Observation

    private func observeSettingsChanges() {
        // 监听设置变化（通过 UserDefaults）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: UserDefaults.didChangeNotification,
            object: nil
        )
    }

    @objc private func settingsDidChange() {
        // 当设置变化时，日志记录当前状态
        let enabled = settingsManager.currentSettings.globalHotkeyEnabled
        Logger.info("Settings changed - Global hotkey enabled: \(enabled)", category: Logger.app)
    }

    /// 设置 Dock 图标显示/隐藏
    func setDockIconVisibility(_ show: Bool) {
        if show {
            NSApp.setActivationPolicy(.regular)
            Logger.info("Dock icon shown", category: Logger.app)
        } else {
            NSApp.setActivationPolicy(.accessory)
            Logger.info("Dock icon hidden", category: Logger.app)
        }
    }
}
