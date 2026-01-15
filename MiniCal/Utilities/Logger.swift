//
//  Logger.swift
//  MiniCal
//
//  Created on 2025/10/28.
//

import Foundation
import os.log

/// 统一的日志管理系统
enum Logger {

    // MARK: - Subsystems

    private static let subsystem = Bundle.main.bundleIdentifier ?? "com.minical"

    // MARK: - Categories

    // 恢复为静态常量，现在是安全的（不会触发 Bundle 访问）
    static let app = OSLog(subsystem: subsystem, category: "App")
    static let ui = OSLog(subsystem: subsystem, category: "UI")
    static let calendar = OSLog(subsystem: subsystem, category: "Calendar")
    static let settings = OSLog(subsystem: subsystem, category: "Settings")
    static let theme = OSLog(subsystem: subsystem, category: "Theme")
    static let events = OSLog(subsystem: subsystem, category: "Events")
    static let performance = OSLog(subsystem: subsystem, category: "Performance")

    // MARK: - Logging Methods

    /// 记录调试信息
    static func debug(_ message: String, category: OSLog) {
        os_log(.debug, log: category, "%{public}@", message)
    }

    /// 记录一般信息
    static func info(_ message: String, category: OSLog) {
        os_log(.info, log: category, "%{public}@", message)
    }

    /// 记录警告
    static func warning(_ message: String, category: OSLog) {
        os_log(.error, log: category, "⚠️ %{public}@", message)
    }

    /// 记录错误
    static func error(_ message: String, error: Error? = nil, category: OSLog) {
        if let error = error {
            os_log(.fault, log: category, "❌ %{public}@: %{public}@", message, error.localizedDescription)
        } else {
            os_log(.fault, log: category, "❌ %{public}@", message)
        }
    }

    /// 记录性能指标
    static func measure(_ operation: String, duration: TimeInterval, category: OSLog) {
        let milliseconds = duration * 1000
        os_log(.info, log: category, "⏱️ %{public}@ completed in %.2f ms", operation, milliseconds)
    }
}

// MARK: - Performance Measurement Helper

extension Logger {
    /// 测量代码块执行时间
    static func measureTime<T>(operation: String, category: OSLog, block: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - start
        measure(operation, duration: duration, category: category)
        return result
    }

    /// 测量异步代码块执行时间
    static func measureTimeAsync(operation: String, category: OSLog) -> (() -> Void) {
        let start = CFAbsoluteTimeGetCurrent()
        return {
            let duration = CFAbsoluteTimeGetCurrent() - start
            measure(operation, duration: duration, category: category)
        }
    }
}
