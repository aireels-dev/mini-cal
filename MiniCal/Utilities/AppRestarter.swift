//
//  AppRestarter.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation
import AppKit

/// 应用重启助手
class AppRestarter {

    /// 重启应用
    static func restart() {
        let bundlePath = Bundle.main.bundlePath

        // 使用 NSWorkspace 重新打开应用
        // 设置延迟以确保当前应用完全退出
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            let task = Process()
            task.launchPath = "/usr/bin/open"
            task.arguments = [bundlePath]

            do {
                try task.run()
                // 终止当前应用
                NSApp.terminate(nil)
            } catch {
                print("❌ Failed to restart app: \(error)")
                NSApp.terminate(nil)
            }
        }
    }

    /// 使用 NSWorkspace 重启（推荐方法）
    static func restartUsingWorkspace() {
        let url = URL(fileURLWithPath: Bundle.main.bundlePath)
        let configuration = NSWorkspace.OpenConfiguration()

        // 设置为新实例
        configuration.createsNewApplicationInstance = true

        // 在短暂延迟后重启
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
                if let error = error {
                    print("❌ Failed to restart app: \(error)")
                }
                // 无论成功与否都退出当前实例
                NSApp.terminate(nil)
            }
        }
    }
}
