//
//  CalendarService.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

// MARK: - LRU Cache for Secondary Calendar Conversion

/// 副历转换的 LRU 缓存
private class SecondaryDateCache {
    private var cache: [Date: SecondaryDateInfo] = [:]
    private var accessOrder: [Date] = []
    private let maxCacheSize: Int
    private let queue = DispatchQueue(label: "com.minical.secondarycache", attributes: .concurrent)

    init(maxSize: Int = 200) {
        self.maxCacheSize = maxSize
    }

    /// 获取缓存的副历信息
    func get(_ date: Date) -> SecondaryDateInfo? {
        return queue.sync {
            if let info = cache[date] {
                // 更新访问顺序（LRU）
                updateAccessOrder(date)
                return info
            }
            return nil
        }
    }

    /// 设置缓存
    func set(_ date: Date, info: SecondaryDateInfo) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            // 如果已存在，先移除旧位置
            if self.cache[date] != nil {
                self.accessOrder.removeAll { $0 == date }
            }

            // 添加新值
            self.cache[date] = info
            self.accessOrder.append(date)

            // 如果超过最大缓存大小，移除最旧的
            if self.accessOrder.count > self.maxCacheSize {
                let oldestDate = self.accessOrder.removeFirst()
                self.cache.removeValue(forKey: oldestDate)
            }
        }
    }

    /// 批量获取缓存（返回未命中的日期）
    func getBatch(_ dates: [Date]) -> (cached: [Date: SecondaryDateInfo], uncached: [Date]) {
        return queue.sync {
            var cached: [Date: SecondaryDateInfo] = [:]
            var uncached: [Date] = []

            for date in dates {
                if let info = cache[date] {
                    cached[date] = info
                    updateAccessOrder(date)
                } else {
                    uncached.append(date)
                }
            }

            return (cached, uncached)
        }
    }

    /// 批量设置缓存
    func setBatch(_ results: [Date: SecondaryDateInfo]) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }

            for (date, info) in results {
                // 如果已存在，先移除旧位置
                if self.cache[date] != nil {
                    self.accessOrder.removeAll { $0 == date }
                }

                // 添加新值
                self.cache[date] = info
                self.accessOrder.append(date)
            }

            // 如果超过最大缓存大小，移除最旧的
            while self.accessOrder.count > self.maxCacheSize {
                let oldestDate = self.accessOrder.removeFirst()
                self.cache.removeValue(forKey: oldestDate)
            }
        }
    }

    /// 清空缓存
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            self?.cache.removeAll()
            self?.accessOrder.removeAll()
        }
    }

    /// 更新访问顺序
    private func updateAccessOrder(_ date: Date) {
        // 移到末尾（最近访问）
        accessOrder.removeAll { $0 == date }
        accessOrder.append(date)
    }
}

class CalendarService {
    private let gregorianCalendar: Calendar
    private let secondaryCalendarConverter: SecondaryCalendarConverter
    private let unifiedEventService: UnifiedEventService
    private let settingsManager: SettingsManager

    // 副历转换缓存
    private let secondaryDateCache = SecondaryDateCache(maxSize: 200)

    init(
        secondaryCalendarConverter: SecondaryCalendarConverter = SecondaryCalendarConverter(),
        unifiedEventService: UnifiedEventService = UnifiedEventService.shared,
        settingsManager: SettingsManager = SettingsManager.shared
    ) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "zh_CN")
        calendar.timeZone = TimeZone.current
        self.gregorianCalendar = calendar
        self.secondaryCalendarConverter = secondaryCalendarConverter
        self.unifiedEventService = unifiedEventService
        self.settingsManager = settingsManager
    }

    // MARK: - Month Generation

    /// 生成指定月份的日历数据
    func generateMonth(for date: Date, secondaryCalendar: CalendarType? = nil) async -> [CalendarDate] {
        var dates: [Date] = []

        let monthStart = gregorianCalendar.firstDayOfMonth(for: date)
        let numberOfDaysInMonth = gregorianCalendar.numberOfDaysInMonth(for: date)

        // 添加调试日志
        print("📅 [CalendarService] Generating month for date: \(date)")
        print("📅 [CalendarService] Month start: \(monthStart)")
        print("📅 [CalendarService] Days in month: \(numberOfDaysInMonth)")
        Logger.debug("Generating month for \(date), days in month: \(numberOfDaysInMonth)", category: Logger.calendar)

        // 验证输入
        guard numberOfDaysInMonth > 0 else {
            Logger.error("Invalid number of days in month: \(numberOfDaysInMonth)", category: Logger.calendar)
            return []
        }

        // 修复: 在 MainActor 上下文中访问 currentSettings，避免并发问题
        let weekStartDay = await MainActor.run {
            settingsManager.currentSettings.weekStartDay
        }
        print("📅 [CalendarService] Week start day: \(weekStartDay)")
        Logger.debug("Week start day: \(weekStartDay)", category: Logger.calendar)

        // 计算需要显示的上个月的日期数量（基于每周起始日设置）
        let previousMonthDays = gregorianCalendar.previousMonthDays(for: date, weekStartDay: weekStartDay)

        // 收集所有需要显示的日期
        // 添加上个月的日期
        if previousMonthDays > 0, let previousMonthStart = gregorianCalendar.date(byAdding: .day, value: -previousMonthDays, to: monthStart) {
            for dayOffset in 0..<previousMonthDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: previousMonthStart) {
                    dates.append(dayDate)
                }
            }
        }

        // 添加当月的日期
        for day in 0..<numberOfDaysInMonth {
            if let dayDate = gregorianCalendar.date(byAdding: .day, value: day, to: monthStart) {
                dates.append(dayDate)
            }
        }

        // 添加下个月的日期，填充到6行 (42天)
        let remainingDays = 42 - dates.count
        if remainingDays > 0 {
            let lastDayOfMonth = gregorianCalendar.date(byAdding: .day, value: numberOfDaysInMonth - 1, to: monthStart)!
            let nextMonthStart = gregorianCalendar.date(byAdding: .day, value: 1, to: lastDayOfMonth)!
            for dayOffset in 0..<remainingDays {
                if let dayDate = gregorianCalendar.date(byAdding: .day, value: dayOffset, to: nextMonthStart) {
                    dates.append(dayDate)
                }
            }
        }

        // 添加防御性检查：确保 dates 数组不为空
        Logger.debug("Generated \(dates.count) dates total (expected: 42)", category: Logger.calendar)
        guard !dates.isEmpty else {
            Logger.error("Dates array is empty after generation for date: \(date)", category: Logger.calendar)
            return []
        }

        // 批量转换本地历法信息（使用 LRU 缓存优化）
        var secondaryInfoMap: [Date: SecondaryDateInfo] = [:]
        if let calendarType = secondaryCalendar {
            // 先尝试从缓存获取
            let (cached, uncached) = secondaryDateCache.getBatch(dates)
            secondaryInfoMap = cached

            // 只转换未缓存的日期
            if !uncached.isEmpty {
                Logger.debug("Cache hit: \(cached.count)/\(dates.count), converting \(uncached.count) uncached dates", category: Logger.calendar)

                // 使用 autoreleasepool 分批处理，降低内存峰值
                let batchSize = 10
                for batchStart in stride(from: 0, to: uncached.count, by: batchSize) {
                    let batchEnd = min(batchStart + batchSize, uncached.count)
                    let batch = Array(uncached[batchStart..<batchEnd])

                    autoreleasepool {
                        let batchResults = secondaryCalendarConverter.batchConvert(dates: batch, to: calendarType)
                        secondaryInfoMap.merge(batchResults) { $1 }
                    }
                }

                // 将新转换的结果加入缓存
                secondaryDateCache.setBatch(secondaryInfoMap)

                Logger.debug("Converted \(uncached.count) dates to secondary calendar (total: \(secondaryInfoMap.count))", category: Logger.calendar)
            } else {
                Logger.debug("All \(dates.count) dates served from cache", category: Logger.calendar)
            }
        }

        // 获取所有事件（系统+外部订阅+本地）使用统一事件服务
        // 注意：节假日数据现在通过外部订阅获取，不再从本地 JSON 加载
        // 重要：获取实际显示范围内的所有事件（包括非当月日期）
        guard let displayStartDate = dates.first,
              let displayEndDate = dates.last else {
            Logger.error("Failed to get display date range", category: Logger.calendar)
            return []
        }

        let allEvents: [CalendarEvent]
        do {
            // 使用实际显示的日期范围，包括上月末尾和下月开头
            allEvents = try await unifiedEventService.getEvents(in: DateRange(startDate: displayStartDate, endDate: displayEndDate))
            Logger.debug("📅 Loaded \(allEvents.count) events from UnifiedEventService (including non-current month dates)", category: Logger.calendar)
        } catch {
            Logger.error("Failed to load events from UnifiedEventService: \(error)", category: Logger.calendar)
            allEvents = []
        }

        // 按日期分组事件（使用预分配优化）
        var eventsMap: [String: [CalendarEvent]] = [:]
        eventsMap.reserveCapacity(allEvents.count)

        // 复用 DateFormatter 对象（避免在循环中创建）
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        for event in allEvents {
            let dateString = dateFormatter.string(from: event.startDate)
            if eventsMap[dateString] == nil {
                eventsMap[dateString] = []
            }
            eventsMap[dateString]?.append(event)
        }

        // 创建 CalendarDate 对象（重用已计算的monthStart）
        var calendarDates: [CalendarDate] = []

        for dateValue in dates {
            let isCurrentMonth = gregorianCalendar.isDate(dateValue, equalTo: monthStart, toGranularity: .month)
            var calendarDate = CalendarDate(date: dateValue, isCurrentMonth: isCurrentMonth)

            // 添加副历信息
            if let secondaryInfo = secondaryInfoMap[dateValue] {
                calendarDate.secondaryDate = secondaryInfo
            }

            // 添加所有事件（系统日历、外部订阅、本地事件）
            let dateString = dateFormatter.string(from: dateValue)
            if let dayEvents = eventsMap[dateString] {
                calendarDate.calendarEvents.append(contentsOf: dayEvents)
                Logger.debug("  ✅ Added \(dayEvents.count) events on \(dateString)", category: Logger.calendar)
            }

            calendarDates.append(calendarDate)
        }

        return calendarDates
    }

    // MARK: - Navigation Helpers

    /// 获取上个月的日期
    func previousMonth(from date: Date) -> Date {
        return gregorianCalendar.date(byAdding: .month, value: -1, to: date) ?? date
    }

    /// 获取下个月的日期
    func nextMonth(from date: Date) -> Date {
        return gregorianCalendar.date(byAdding: .month, value: 1, to: date) ?? date
    }

    /// 获取今天的日期
    func today() -> Date {
        return Date()
    }

    // MARK: - Month/Year Info

    /// 获取月份和年份的显示文本
    func monthYearText(for date: Date) -> String {
        let formatter = DateFormatter()
        let localeId = LocalizationManager.shared.context.effectiveInterfaceLocale.rawValue
        formatter.locale = Locale(identifier: localeId)
        formatter.dateFormat = DateFormatter.dateFormat(fromTemplate: "yyyyMMMM", options: 0, locale: Locale(identifier: localeId))
        return formatter.string(from: date)
    }
}
