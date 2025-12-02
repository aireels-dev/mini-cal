//
//  MenuBarViewModel.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import Combine
import SwiftUI
import AppKit

class MenuBarViewModel: ObservableObject {
    @Published var displayText: String = ""

    private var timer: Timer?
    var cancellables = Set<AnyCancellable>()
    private let settingsManager: SettingsManager

    init(settingsManager: SettingsManager = SettingsManager.shared) {
        self.settingsManager = settingsManager

        updateDisplayText()
        scheduleNextUpdate()
        observeSettingsChanges()
        observeTimeZoneChanges()
        observeLocalizationChanges()
        observeSystemWakeup()
    }

    deinit {
        timer?.invalidate()
    }

    // MARK: - Timer Management

    /// 智能调度下次更新：根据显示内容计算精确的下次更新时间点
    private func scheduleNextUpdate() {
        timer?.invalidate()

        let settings = settingsManager.currentSettings
        let now = Date()
        let calendar = Calendar.current

        // 计算到下一个时间边界的间隔
        let timeInterval: TimeInterval

        switch settings.menuBarFormat {
        case .dateOnly:
            // 仅显示日期：在每天的 00:00:00 更新
            timeInterval = calculateIntervalToNextDay(from: now, calendar: calendar)
            Logger.info("Menu bar update scheduled: next day boundary", category: Logger.ui)

        case .timeOnly, .dateTime, .custom:
            if settings.showSeconds {
                // 显示秒：在每秒的开始时刻更新
                timeInterval = calculateIntervalToNextSecond(from: now)
                Logger.info("Menu bar update scheduled: next second", category: Logger.ui)
            } else {
                // 显示分钟（不显示秒）：在每分钟的开始时刻更新
                timeInterval = calculateIntervalToNextMinute(from: now, calendar: calendar)
                Logger.info("Menu bar update scheduled: next minute", category: Logger.ui)
            }
        }

        // 使用单次触发的 Timer，触发后重新调度
        timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) { [weak self] _ in
            self?.handleTimerFired()
        }
    }

    /// Timer 触发时的处理
    private func handleTimerFired() {
        updateDisplayText()
        scheduleNextUpdate()
    }

    // MARK: - Time Calculation

    /// 计算到下一秒的时间间隔（精确到毫秒）
    private func calculateIntervalToNextSecond(from date: Date) -> TimeInterval {
        let currentTimeInterval = date.timeIntervalSinceReferenceDate
        let nextSecond = ceil(currentTimeInterval)
        let interval = nextSecond - currentTimeInterval
        // 至少 0.01 秒，避免立即触发
        return max(interval, 0.01)
    }

    /// 计算到下一分钟的时间间隔
    private func calculateIntervalToNextMinute(from date: Date, calendar: Calendar) -> TimeInterval {
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        guard let currentMinute = calendar.date(from: components),
              let nextMinute = calendar.date(byAdding: .minute, value: 1, to: currentMinute) else {
            return 60.0 // 降级方案
        }
        let interval = nextMinute.timeIntervalSince(date)
        return max(interval, 0.1)
    }

    /// 计算到下一天的时间间隔
    private func calculateIntervalToNextDay(from date: Date, calendar: Calendar) -> TimeInterval {
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let startOfToday = calendar.date(from: components),
              let startOfTomorrow = calendar.date(byAdding: .day, value: 1, to: startOfToday) else {
            return 3600.0 // 降级方案：1小时后重试
        }
        let interval = startOfTomorrow.timeIntervalSince(date)
        return max(interval, 1.0)
    }

    // MARK: - Display Text Update

    func updateDisplayText() {
        let currentDate = Date()
        let settings = settingsManager.currentSettings
        displayText = settings.menuBarFormat.format(
            date: currentDate,
            show24Hour: settings.show24Hour,
            showWeekday: settings.showWeekday,
            showSeconds: settings.showSeconds,
            customFormat: settings.customFormat
        )
    }

    // MARK: - Settings Observer

    private func observeSettingsChanges() {
        settingsManager.$currentSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self = self else { return }
                Logger.info("Settings changed, updating display and rescheduling timer", category: Logger.ui)
                // 立即更新显示文本
                self.updateDisplayText()
                // 重新调度定时器（根据新的显示设置）
                self.scheduleNextUpdate()
            }
            .store(in: &cancellables)
    }

    private func observeTimeZoneChanges() {
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                Logger.info("Time zone changed, updating display and rescheduling timer", category: Logger.ui)
                self?.updateDisplayText()
                self?.scheduleNextUpdate()
            }
            .store(in: &cancellables)
    }

    private func observeLocalizationChanges() {
        NotificationCenter.default.publisher(for: .localizationDidChange)
            .sink { [weak self] _ in
                Logger.info("Localization changed, updating menu bar display", category: Logger.ui)
                self?.updateDisplayText()
            }
            .store(in: &cancellables)
    }

    private func observeSystemWakeup() {
        NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
            .sink { [weak self] _ in
                Logger.info("System woke from sleep, resynchronizing time and display", category: Logger.ui)
                self?.handleSystemWakeup()
            }
            .store(in: &cancellables)
    }

    // MARK: - System Wakeup Handler

    /// 处理系统唤醒事件：重新同步时间和刷新显示
    private func handleSystemWakeup() {
        // 立即更新显示文本（使用当前真实时间）
        updateDisplayText()
        // 重新调度定时器（基于唤醒后的真实时间）
        scheduleNextUpdate()
        Logger.info("Time synchronization completed after system wake", category: Logger.ui)
    }

    // MARK: - Public Methods

    func refreshDisplay() {
        updateDisplayText()
        scheduleNextUpdate()
    }
}
