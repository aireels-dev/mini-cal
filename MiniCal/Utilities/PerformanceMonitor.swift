//
//  PerformanceMonitor.swift
//  MiniCal
//
//  性能监控工具 - 测量操作耗时、内存使用和性能统计
//

import Foundation
import os.log

/// 性能监控工具 - 基于 Swift 最佳实践
class PerformanceMonitor {
    static let shared = PerformanceMonitor()

    private let metricsQueue = DispatchQueue(label: "com.minical.metrics")
    private var metrics: [String: [TimeInterval]] = [:]

    // 性能阈值（秒）
    private let thresholds = [
        "calendar.generate_month": 0.05,      // 50ms
        "events.fetch": 0.12,                 // 120ms
        "subscription.sync": 3.0,             // 3s
        "ui.popup.open": 0.1,                 // 100ms
        "localization.format": 0.01,         // 10ms
    ]

    private init() {}

    // MARK: - 同步操作测量

    /// 测量同步操作耗时
    /// - Parameters:
    ///   - name: 操作名称
    ///   - block: 要测量的操作闭包
    /// - Returns: 操作的返回值
    func measure<T>(_ name: String, block: () -> T) -> T {
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let duration = CFAbsoluteTimeGetCurrent() - start

        recordMetric(name: name, duration: duration)

        let milliseconds = duration * 1000

        // 添加控制台输出以确保性能日志可见
        print("⏱️ [PERF] \(name): \(String(format: "%.2f", milliseconds))ms")

        // 检查是否超过阈值
        let threshold = thresholds[name] ?? 0.1
        if duration > threshold {
            Logger.warning(
                "Performance: \(name) took \(String(format: "%.2f", milliseconds))ms (threshold: \(String(format: "%.2f", threshold * 1000))ms)",
                category: Logger.performance
            )
        } else {
            Logger.debug(
                "Performance: \(name) completed in \(String(format: "%.2f", milliseconds))ms",
                category: Logger.performance
            )
        }

        return result
    }

    // MARK: - 异步操作测量

    /// 测量异步操作耗时
    /// - Parameters:
    ///   - name: 操作名称
    ///   - block: 要测量的异步操作闭包
    /// - Returns: 操作的返回值
    func measureAsync<T>(_ name: String, block: () async throws -> T) async rethrows -> T {
        let start = CFAbsoluteTimeGetCurrent()

        // 执行闭包并捕获结果
        let result = try await block()

        // 计算耗时
        let duration = CFAbsoluteTimeGetCurrent() - start

        // 捕获需要的值，避免在 Task.detached 中强捕获 self
        let threshold = self.thresholds[name] ?? 0.5

        // 使用 Task 避免阻塞主流程，同时保持主执行器隔离
        // 使用 [weak self] 避免强引用循环
        Task { [weak self] in
            guard let self = self else { return }

            // 后台记录指标
            self.recordMetric(name: name, duration: duration)

            let milliseconds = duration * 1000

            #if DEBUG
            print("⏱️ [PERF] \(name): \(String(format: "%.2f", milliseconds))ms")

            // 异步操作的阈值通常更宽松
            if duration > threshold {
                Logger.warning(
                    "Performance: \(name) took \(String(format: "%.2f", milliseconds))ms (threshold: \(String(format: "%.2f", threshold * 1000))ms)",
                    category: Logger.performance
                )
            } else {
                Logger.debug(
                    "Performance: \(name) completed in \(String(format: "%.2f", milliseconds))ms",
                    category: Logger.performance
                )
            }
            #endif
        }

        return result
    }

    // MARK: - 内存监控

    /// 记录当前内存使用情况
    /// - Parameter context: 上下文描述（如操作名称）
    func recordMemoryUsage(for context: String) {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let result: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(
                    mach_task_self_,
                    task_flavor_t(MACH_TASK_BASIC_INFO),
                    $0,
                    &count
                )
            }
        }

        if result == KERN_SUCCESS {
            let usedMB = Double(info.resident_size) / 1024 / 1024

            // 内存使用警告阈值：100MB
            if usedMB > 100 {
                Logger.warning(
                    "Memory: \(context) - \(String(format: "%.2f", usedMB))MB ⚠️ High usage",
                    category: Logger.performance
                )
            } else {
                Logger.info(
                    "Memory: \(context) - \(String(format: "%.2f", usedMB))MB",
                    category: Logger.performance
                )
            }
        }
    }

    // MARK: - 指标统计

    /// 记录性能指标
    private func recordMetric(name: String, duration: TimeInterval) {
        metricsQueue.async { [weak self] in
            self?.metrics[name, default: []].append(duration)

            // 只保留最近 100 次记录
            if var metrics = self?.metrics[name], metrics.count > 100 {
                metrics.removeFirst()
                self?.metrics[name] = metrics
            }
        }
    }

    /// 获取性能统计报告
    /// - Parameter name: 操作名称
    /// - Returns: 统计数据（平均、最小、最大值和样本数）
    func getReport(for name: String) -> (avg: TimeInterval, min: TimeInterval, max: TimeInterval, count: Int)? {
        guard let durations = metrics[name], !durations.isEmpty else {
            return nil
        }

        return (
            avg: durations.reduce(0, +) / Double(durations.count),
            min: durations.min() ?? 0,
            max: durations.max() ?? 0,
            count: durations.count
        )
    }

    /// 打印所有指标的性能报告
    func printAllReports() {
        metricsQueue.sync { [weak self] in
            guard let self = self else { return }

            Logger.info("========== Performance Report ==========", category: Logger.performance)

            for (name, _) in self.metrics.sorted(by: { $0.key < $1.key }) {
                if let report = self.getReport(for: name) {
                    Logger.info(
                        """
                        \(name):
                          - Avg: \(String(format: "%.2f", report.avg * 1000))ms
                          - Min: \(String(format: "%.2f", report.min * 1000))ms
                          - Max: \(String(format: "%.2f", report.max * 1000))ms
                          - Count: \(report.count)
                        """,
                        category: Logger.performance
                    )
                }
            }

            Logger.info("=====================================", category: Logger.performance)
        }
    }

    /// 清除所有指标
    func resetMetrics() {
        metricsQueue.async { [weak self] in
            self?.metrics.removeAll()
            Logger.info("Performance metrics reset", category: Logger.performance)
        }
    }
}

// MARK: - 性能测量辅助宏（便于使用）

/// 测量同步操作的性能
func measurePerformance<T>(_ name: String, block: () -> T) -> T {
    return PerformanceMonitor.shared.measure(name, block: block)
}

/// 测量异步操作的性能
func measurePerformanceAsync<T>(_ name: String, block: () async throws -> T) async rethrows -> T {
    return try await PerformanceMonitor.shared.measureAsync(name, block: block)
}
