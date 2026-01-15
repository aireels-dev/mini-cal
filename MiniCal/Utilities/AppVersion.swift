//
//  AppVersion.swift
//  MiniCal
//
//  Created on 2025/10/28.
//

import Foundation

/// 应用版本信息管理
enum AppVersion {

    // MARK: - Version Info

    /// 获取应用版本号 (CFBundleShortVersionString)
    static var version: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }

    /// 获取构建号 (CFBundleVersion)
    static var build: String {
        return Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    /// 获取完整版本字符串 (版本号 (构建号))
    static var fullVersion: String {
        return "\(version) (\(build))"
    }

    /// 获取应用名称
    static var appName: String {
        return AppBrand.displayName
    }

    /// 获取Bundle标识符
    static var bundleIdentifier: String {
        return Bundle.main.bundleIdentifier ?? "com.minical.app"
    }

    // MARK: - System Info

    /// 获取macOS版本
    static var macOSVersion: String {
        let version = ProcessInfo.processInfo.operatingSystemVersion
        return "\(version.majorVersion).\(version.minorVersion).\(version.patchVersion)"
    }

    /// 获取系统架构
    static var architecture: String {
        #if arch(arm64)
        return "Apple Silicon"
        #elseif arch(x86_64)
        return "Intel"
        #else
        return "Unknown"
        #endif
    }

    // MARK: - Version Comparison

    /// 比较版本号
    /// - Parameters:
    ///   - version1: 版本号1 (如 "1.0.0")
    ///   - version2: 版本号2 (如 "1.1.0")
    /// - Returns: 比较结果 (.orderedAscending: v1 < v2, .orderedSame: v1 == v2, .orderedDescending: v1 > v2)
    static func compare(_ version1: String, with version2: String) -> ComparisonResult {
        return version1.compare(version2, options: .numeric)
    }

    /// 检查是否有新版本
    /// - Parameter latestVersion: 最新版本号
    /// - Returns: true表示当前版本低于最新版本
    static func hasNewVersion(latestVersion: String) -> Bool {
        return compare(version, with: latestVersion) == .orderedAscending
    }

    // MARK: - Version Check (Placeholder)

    /// 检查更新（占位实现，未来可集成Sparkle或自定义更新服务）
    /// - Parameter completion: 回调 (是否有新版本, 最新版本号, 错误信息)
    static func checkForUpdates(completion: @escaping (Bool, String?, Error?) -> Void) {
        // 占位实现：当前总是返回无新版本
        // 未来可以集成：
        // 1. Sparkle框架 (推荐用于Mac App Store外分发)
        // 2. 自定义API检查
        // 3. GitHub Releases API

        Logger.info("Version check requested (placeholder implementation)", category: Logger.app)

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            completion(false, nil, nil)
        }
    }

    // MARK: - Debug Info

    /// 获取调试信息字符串
    static var debugInfo: String {
        return """
        App: \(appName) \(fullVersion)
        Bundle ID: \(bundleIdentifier)
        macOS: \(macOSVersion)
        Architecture: \(architecture)
        """
    }
}
