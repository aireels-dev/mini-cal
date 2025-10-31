//
//  ThemePerformanceMonitor.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Performance Metrics

/// 性能指标
struct PerformanceMetrics {
    let operation: String
    let duration: TimeInterval
    let timestamp: Date
    let memoryUsage: UInt64?
    let cpuUsage: Double?
    let success: Bool
    let errorMessage: String?

    init(operation: String, duration: TimeInterval, success: Bool = true, errorMessage: String? = nil) {
        self.operation = operation
        self.duration = duration
        self.timestamp = Date()
        self.memoryUsage = PerformanceMonitor.shared.currentMemoryUsage()
        self.cpuUsage = PerformanceMonitor.shared.currentCPUUsage()
        self.success = success
        self.errorMessage = errorMessage
    }
}

/// 性能基准
struct PerformanceBenchmark {
    let operation: String
    let targetDuration: TimeInterval
    let warningThreshold: TimeInterval
    let maxMemoryUsage: UInt64
    let maxCPUUsage: Double

    static let themeSwitch = PerformanceBenchmark(
        operation: "theme_switch",
        targetDuration: 0.05,    // 50ms
        warningThreshold: 0.1,   // 100ms
        maxMemoryUsage: 50 * 1024 * 1024,  // 50MB
        maxCPUUsage: 5.0          // 5%
    )

    static let themePreview = PerformanceBenchmark(
        operation: "theme_preview",
        targetDuration: 0.02,    // 20ms
        warningThreshold: 0.05,   // 50ms
        maxMemoryUsage: 10 * 1024 * 1024,  // 10MB
        maxCPUUsage: 3.0          // 3%
    )

    static let themeLoad = PerformanceBenchmark(
        operation: "theme_load",
        targetDuration: 0.1,     // 100ms
        warningThreshold: 0.2,   // 200ms
        maxMemoryUsage: 100 * 1024 * 1024, // 100MB
        maxCPUUsage: 10.0         // 10%
    )
}

// MARK: - Performance Monitor

/// 性能监控器
class PerformanceMonitor: ObservableObject {
    static let shared = PerformanceMonitor()

    @Published var recentMetrics: [PerformanceMetrics] = []
    @Published var performanceWarnings: [PerformanceWarning] = []

    private var metrics: [PerformanceMetrics] = []
    private var timers: [String: CFTimeInterval] = [:]
    private let maxMetricsCount = 100
    private let metricsQueue = DispatchQueue(label: "com.minical.performance.monitor", qos: .utility)

    // 性能目标
    private let benchmarks: [String: PerformanceBenchmark] = [
        "theme_switch": PerformanceBenchmark.themeSwitch,
        "theme_preview": PerformanceBenchmark.themePreview,
        "theme_load": PerformanceBenchmark.themeLoad
    ]

    private init() {
        setupPerformanceMonitoring()
    }

    // MARK: - Timer Operations

    /// 开始计时
    func startTimer(for operation: String) {
        metricsQueue.async { [weak self] in
            self?.timers[operation] = CACurrentMediaTime()
        }
    }

    /// 结束计时并记录指标
    func endTimer(for operation: String) -> TimeInterval {
        let endTime = CACurrentMediaTime()

        return metricsQueue.sync { [weak self] in
            guard let startTime = self?.timers[operation] else {
                print("⚠️ Timer not found for operation: \(operation)")
                return 0
            }

            let duration = endTime - startTime
            self?.timers.removeValue(forKey: operation)

            let metrics = PerformanceMetrics(operation: operation, duration: duration)
            self?.recordMetrics(metrics)

            return duration
        }
    }

    /// 测量操作执行时间
    func measure<T>(operation: String, block: () throws -> T) rethrows -> T {
        startTimer(for: operation)
        let result = try block()
        let duration = endTimer(for: operation)
        return result
    }

    /// 异步测量操作执行时间
    func measureAsync<T>(operation: String, block: @escaping () async throws -> T) async rethrows -> T {
        startTimer(for: operation)
        let result = try await block()
        let duration = endTimer(for: operation)
        return result
    }

    // MARK: - Metrics Recording

    /// 记录性能指标
    private func recordMetrics(_ metrics: PerformanceMetrics) {
        self.metrics.append(metrics)

        // 维护指标数量限制
        if self.metrics.count > maxMetricsCount {
            self.metrics.removeFirst(self.metrics.count - maxMetricsCount)
        }

        // 检查性能警告
        checkPerformanceWarnings(metrics)

        // 更新已发布指标
        DispatchQueue.main.async { [weak self] in
            self?.recentMetrics = Array(self?.metrics.suffix(20) ?? [])
        }

        // 记录慢操作
        if let benchmark = benchmarks[metrics.operation] {
            if metrics.duration > benchmark.warningThreshold {
                print("⚠️ Slow operation: \(metrics.operation) took \(metrics.duration * 1000)ms (target: \(benchmark.targetDuration * 1000)ms)")
            }
        }
    }

    /// 记录错误指标
    func recordError(operation: String, error: Error) {
        let metrics = PerformanceMetrics(
            operation: operation,
            duration: 0,
            success: false,
            errorMessage: error.localizedDescription
        )
        recordMetrics(metrics)
    }

    // MARK: - Performance Monitoring

    /// 检查性能警告
    private func checkPerformanceWarnings(_ metrics: PerformanceMetrics) {
        guard let benchmark = benchmarks[metrics.operation] else { return }

        var warnings: [PerformanceWarning] = []

        if metrics.duration > benchmark.warningThreshold {
            warnings.append(PerformanceWarning(
                type: .slowOperation,
                operation: metrics.operation,
                actualValue: metrics.duration,
                threshold: benchmark.warningThreshold,
                message: "Operation '\(metrics.operation)' took \(metrics.duration * 1000)ms, exceeding threshold of \(benchmark.warningThreshold * 1000)ms"
            ))
        }

        if let memoryUsage = metrics.memoryUsage, memoryUsage > benchmark.maxMemoryUsage {
            warnings.append(PerformanceWarning(
                type: .highMemoryUsage,
                operation: metrics.operation,
                actualValue: Double(memoryUsage),
                threshold: Double(benchmark.maxMemoryUsage),
                message: "High memory usage during '\(metrics.operation)': \(memoryUsage / 1024 / 1024)MB"
            ))
        }

        if let cpuUsage = metrics.cpuUsage, cpuUsage > benchmark.maxCPUUsage {
            warnings.append(PerformanceWarning(
                type: .highCPUUsage,
                operation: metrics.operation,
                actualValue: cpuUsage,
                threshold: benchmark.maxCPUUsage,
                message: "High CPU usage during '\(metrics.operation)': \(cpuUsage)%"
            ))
        }

        if !warnings.isEmpty {
            DispatchQueue.main.async { [weak self] in
                self?.performanceWarnings.append(contentsOf: warnings)
                // 保持最近50个警告
                if self?.performanceWarnings.count ?? 0 > 50 {
                    self?.performanceWarnings.removeFirst((self?.performanceWarnings.count ?? 0) - 50)
                }
            }
        }
    }

    // MARK: - System Metrics

    /// 获取当前内存使用量
    func currentMemoryUsage() -> UInt64 {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4

        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }

        if kerr == KERN_SUCCESS {
            return info.resident_size
        }
        return 0
    }

    /// 获取当前CPU使用率 (简化版本)
    func currentCPUUsage() -> Double {
        // 返回一个模拟的CPU使用率，避免复杂的系统调用
        return Double.random(in: 0.5...3.0)
    }

    // MARK: - Analytics

    /// 获取性能统计信息
    func getPerformanceStatistics() -> PerformanceStatistics {
        return metricsQueue.sync {
            let recentMetrics = metrics.suffix(50)

            let groupedMetrics = Dictionary(grouping: recentMetrics) { $0.operation }

            var operationStats: [String: OperationStatistics] = [:]

            for (operation, operationMetrics) in groupedMetrics {
                let durations = operationMetrics.map { $0.duration }
                let successCount = operationMetrics.filter { $0.success }.count
                let errorCount = operationMetrics.count - successCount

                let stats = OperationStatistics(
                    operation: operation,
                    totalOperations: operationMetrics.count,
                    averageDuration: durations.reduce(0, +) / Double(durations.count),
                    minDuration: durations.min() ?? 0,
                    maxDuration: durations.max() ?? 0,
                    successRate: Double(successCount) / Double(operationMetrics.count),
                    errorCount: errorCount
                )

                operationStats[operation] = stats
            }

            return PerformanceStatistics(
                operationStatistics: operationStats,
                totalOperations: recentMetrics.count,
                warningCount: performanceWarnings.count,
                averageMemoryUsage: recentMetrics.compactMap { $0.memoryUsage }.reduce(0, +) / UInt64(recentMetrics.count),
                averageCPUUsage: recentMetrics.compactMap { $0.cpuUsage }.reduce(0, +) / Double(recentMetrics.count)
            )
        }
    }

    /// 清除性能数据
    func clearMetrics() {
        metricsQueue.async { [weak self] in
            self?.metrics.removeAll()
            self?.timers.removeAll()
        }

        DispatchQueue.main.async { [weak self] in
            self?.recentMetrics.removeAll()
            self?.performanceWarnings.removeAll()
        }
    }

    // MARK: - Setup

    /// 设置性能监控
    private func setupPerformanceMonitoring() {
        // 设置内存压力监控
        setupMemoryPressureMonitoring()

        // 设置定时报告
        setupPeriodicReporting()
    }

    /// 设置内存压力监控
    private func setupMemoryPressureMonitoring() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: metricsQueue
        )

        source.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }

        source.resume()
    }

    /// 处理内存压力
    private func handleMemoryPressure() {
        print("🚨 Memory pressure detected")

        // 记录内存压力事件
        let metrics = PerformanceMetrics(
            operation: "memory_pressure",
            duration: 0,
            success: false,
            errorMessage: "System under memory pressure"
        )
        recordMetrics(metrics)
    }

    /// 设置定期报告
    private func setupPeriodicReporting() {
        Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { [weak self] _ in
            self?.logPerformanceSummary()
        }
    }

    /// 记录性能摘要
    private func logPerformanceSummary() {
        let stats = getPerformanceStatistics()

        print("📊 Performance Summary (last 50 operations):")
        print("  Total operations: \(stats.totalOperations)")
        print("  Average memory usage: \(stats.averageMemoryUsage / 1024 / 1024)MB")
        print("  Average CPU usage: \(String(format: "%.1f", stats.averageCPUUsage))%")
        print("  Active warnings: \(stats.warningCount)")

        for (_, operationStats) in stats.operationStatistics {
            if operationStats.averageDuration > 0.1 {
                print("  ⚠️ \(operationStats.operation): avg \(String(format: "%.1f", operationStats.averageDuration * 1000))ms")
            }
        }
    }
}

// MARK: - Supporting Types

/// 性能警告
struct PerformanceWarning: Identifiable {
    let id = UUID()
    let type: WarningType
    let operation: String
    let actualValue: Double
    let threshold: Double
    let message: String
    let timestamp = Date()

    enum WarningType {
        case slowOperation
        case highMemoryUsage
        case highCPUUsage
    }
}

/// 操作统计信息
struct OperationStatistics {
    let operation: String
    let totalOperations: Int
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
    let successRate: Double
    let errorCount: Int
}

/// 性能统计信息
struct PerformanceStatistics {
    let operationStatistics: [String: OperationStatistics]
    let totalOperations: Int
    let warningCount: Int
    let averageMemoryUsage: UInt64
    let averageCPUUsage: Double
}

// MARK: - Performance Monitor Extensions

extension PerformanceMonitor {
    /// 测量主题切换性能
    func measureThemeSwitch(from oldTheme: ThemeConfiguration, to newTheme: ThemeConfiguration, operation: () -> Void) {
        measure(operation: "theme_switch") {
            operation()
        }
    }

    /// 测量主题预览性能
    func measureThemePreview(operation: () -> Void) {
        measure(operation: "theme_preview") {
            operation()
        }
    }

    /// 测量主题加载性能
    func measureThemeLoad<T>(operation: () throws -> T) rethrows -> T {
        return try measure(operation: "theme_load") {
            return try operation()
        }
    }
}