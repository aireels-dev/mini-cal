//
//  LaunchAtLoginManager.swift
//  MiniCal
//
//  Created by MiniCal on 2025/11/14.
//  开机自启动管理器
//

import Foundation
import ServiceManagement

class LaunchAtLoginManager {

    static let shared = LaunchAtLoginManager()

    private init() {}

    /// 设置开机自启动
    func setLaunchAtLogin(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            // macOS 13+ 使用新 API
            do {
                if enabled {
                    try SMAppService.mainApp.register()
                    Logger.info("Launch at login enabled (macOS 13+)", category: Logger.app)
                } else {
                    try SMAppService.mainApp.unregister()
                    Logger.info("Launch at login disabled (macOS 13+)", category: Logger.app)
                }
            } catch {
                Logger.error("Failed to set launch at login: \(error)", category: Logger.app)
            }
        } else {
            // macOS 12 及以下使用旧 API
            #if compiler(>=5.5)
            SMLoginItemSetEnabled("com.minical.MiniCal" as CFString, enabled)
            Logger.info("Launch at login \(enabled ? "enabled" : "disabled") (legacy)", category: Logger.app)
            #endif
        }
    }

    /// 获取当前开机自启动状态
    func isLaunchAtLoginEnabled() -> Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            // 旧版本无法准确获取状态，返回设置值
            return SettingsManager.shared.currentSettings.launchAtLogin
        }
    }
}
