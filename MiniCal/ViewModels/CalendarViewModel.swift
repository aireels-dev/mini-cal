//
//  CalendarViewModel.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import Combine

// MARK: - Navigation Direction
enum NavigationDirection {
    case forward  // 前进
    case backward // 后退
    case none     // 无方向（如跳转到今天）
}

// MARK: - Navigation Type
enum NavigationType {
    case month  // 月份切换（使用上下动效）
    case year   // 年份切换（使用左右动效）
    case none   // 无类型
}

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var calendarDates: [CalendarDate] = []
    @Published var monthYearText: String = ""
    @Published var selectedDate: Date?
    @Published var navigationDirection: NavigationDirection = .none
    @Published var navigationType: NavigationType = .none

    // 立即生效的导航状态，解决动效方向切换延迟问题
    var currentNavigationType: NavigationType = .none
    var currentNavigationDirection: NavigationDirection = .none

    private let calendarService: CalendarService
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()
    private var loadTask: Task<Void, Never>?

    // 计算属性：判断当前显示的是否是今天所在的月份
    var isCurrentMonth: Bool {
        let calendar = Calendar.current
        let today = Date()
        return calendar.isDate(currentMonth, equalTo: today, toGranularity: .month)
    }

  
    // MARK: - Setup

    private func setupObservers() {
        // 监听设置变更，重新加载日历数据
        settingsManager.$currentSettings
            .sink { [weak self] _ in
                self?.loadCurrentMonth()
            }
            .store(in: &cancellables)

        // 监听时区变更，重新加载日历数据
        NotificationCenter.default.publisher(for: .NSSystemTimeZoneDidChange)
            .sink { [weak self] _ in
                Logger.info("Time zone changed, reloading calendar", category: Logger.calendar)
                self?.loadCurrentMonth()
            }
            .store(in: &cancellables)
    }

    // MARK: - Data Loading

    func loadCurrentMonth() {
        // 取消之前的加载任务（防抖）
        loadTask?.cancel()

        loadTask = Task { @MainActor in
            let complete = Logger.measureTimeAsync(operation: "Load calendar month", category: Logger.performance)

            let secondaryCalendar = settingsManager.currentSettings.secondaryCalendarType
            calendarDates = await calendarService.generateMonth(for: currentMonth, secondaryCalendar: secondaryCalendar)
            monthYearText = calendarService.monthYearText(for: currentMonth)

            // 加载当月事件并填充到 calendarDates
            await loadAndPopulateEvents()

            // 动画完成后重置立即生效的状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.currentNavigationType = .none
                self.currentNavigationDirection = .none
            }

            complete()
        }
    }

    /// 加载当月事件并填充到日历日期中
    private func loadAndPopulateEvents() async {
        let performanceStart = Date()

        let calendar = Calendar.current
        guard let startDate = calendar.dateInterval(of: .month, for: currentMonth)?.start,
              let endDate = calendar.date(byAdding: .month, value: 1, to: startDate) else {
            Logger.error("Failed to calculate date range for month", category: Logger.calendar)
            return
        }

        do {
            let fetchedEvents = try await eventService.getEvents(in: DateRange(startDate: startDate, endDate: endDate))

            await MainActor.run {
                events = fetchedEvents

                // 将事件追加到对应的 calendarDates（保留节假日和系统日历事件）
                for index in calendarDates.indices {
                    let date = calendarDates[index].gregorianDate
                    let dayEvents = fetchedEvents.filter { event in
                        calendar.isDate(event.startDate, inSameDayAs: date)
                    }

                    // 重要：追加而不是覆盖，保留 CalendarService 已填充的节假日
                    // 先去重（避免重复添加）
                    let existingIds = Set(calendarDates[index].calendarEvents.map { $0.id })
                    let newEvents = dayEvents.filter { !existingIds.contains($0.id) }
                    calendarDates[index].calendarEvents.append(contentsOf: newEvents)
                }

                isLoadingEvents = false
                eventLoadError = nil
            }

            let duration = Date().timeIntervalSince(performanceStart)
            Logger.debug("Loaded \(fetchedEvents.count) events for current month in \(String(format: "%.2f", duration))s", category: Logger.calendar)

            // 性能警告：如果加载时间超过1秒
            if duration > 1.0 {
                Logger.warning("Event loading took \(String(format: "%.2f", duration))s, consider optimization", category: Logger.performance)
            }
        } catch {
            await MainActor.run {
                isLoadingEvents = false
                eventLoadError = error
            }
            Logger.error("Failed to load events for month: \(error)", category: Logger.calendar)
        }
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        navigationDirection = .backward
        navigationType = .month
        currentNavigationType = .month      // 立即设置，确保动效计算时使用正确值
        currentNavigationDirection = .backward // 立即设置，确保动效方向正确
        Logger.measureTime(operation: "Navigate to previous month", category: Logger.performance) {
            currentMonth = calendarService.previousMonth(from: currentMonth)
        }
        loadCurrentMonth()
    }

    func goToNextMonth() {
        navigationDirection = .forward
        navigationType = .month
        currentNavigationType = .month       // 立即设置，确保动效计算时使用正确值
        currentNavigationDirection = .forward  // 立即设置，确保动效方向正确
        Logger.measureTime(operation: "Navigate to next month", category: Logger.performance) {
            currentMonth = calendarService.nextMonth(from: currentMonth)
        }
        loadCurrentMonth()
    }

    func goToToday() {
        navigationDirection = .none
        navigationType = .none
        currentNavigationType = .none         // 立即设置，确保动效计算时使用正确值
        currentNavigationDirection = .none    // 立即设置，确保动效方向正确
        currentMonth = calendarService.today()
        selectedDate = currentMonth
        loadCurrentMonth()
    }

    func goToPreviousYear() {
        navigationDirection = .backward
        navigationType = .year
        currentNavigationType = .year       // 立即设置，确保动效计算时使用正确值
        currentNavigationDirection = .backward // 立即设置，确保动效方向正确
        Logger.measureTime(operation: "Navigate to previous year", category: Logger.performance) {
            let calendar = Calendar.current
            currentMonth = calendar.date(byAdding: .year, value: -1, to: currentMonth) ?? currentMonth
        }
        loadCurrentMonth()
    }

    func goToNextYear() {
        navigationDirection = .forward
        navigationType = .year
        currentNavigationType = .year        // 立即设置，确保动效计算时使用正确值
        currentNavigationDirection = .forward  // 立即设置，确保动效方向正确
        Logger.measureTime(operation: "Navigate to next year", category: Logger.performance) {
            let calendar = Calendar.current
            currentMonth = calendar.date(byAdding: .year, value: 1, to: currentMonth) ?? currentMonth
        }
        loadCurrentMonth()
    }

    // MARK: - Selection

    func selectDate(_ date: CalendarDate) {
        selectedDate = date.gregorianDate
    }

    func isSelected(_ date: CalendarDate) -> Bool {
        guard let selected = selectedDate else { return false }
        return Calendar.current.isDate(selected, inSameDayAs: date.gregorianDate)
    }

    // MARK: - Week Headers

    func weekdayHeaders() -> [String] {
        return ["周日", "周一", "周二", "周三", "周四", "周五", "周六"]
    }

    // MARK: - Event Management

    @Published var events: [CalendarEvent] = []
    @Published var isLoadingEvents = false
    @Published var eventLoadError: Error?

    private let eventService: CalendarEventService
    private let subscriptionService: CalendarSubscriptionService
    let syncStatusMonitor: SyncStatusMonitor

    init(calendarService: CalendarService = CalendarService(),
         settingsManager: SettingsManager = SettingsManager.shared,
         eventService: CalendarEventService = CalendarEventService(),
         subscriptionService: CalendarSubscriptionService = CalendarSubscriptionService(),
         syncStatusMonitor: SyncStatusMonitor = SyncStatusMonitor()) {
        self.calendarService = calendarService
        self.settingsManager = settingsManager
        self.eventService = eventService
        self.subscriptionService = subscriptionService
        self.syncStatusMonitor = syncStatusMonitor
        self.currentMonth = Date()

        setupObservers()
        loadCurrentMonth()
        setupEventObservers()
    }

    private func setupEventObservers() {
        // 监听同步状态变化
        syncStatusMonitor.$overallSyncStatus
            .sink { [weak self] status in
                if status == .idle {
                    self?.loadEventsForCurrentMonth()
                }
            }
            .store(in: &cancellables)

        // 移除重复的 selectedDate 观察者逻辑
        // 事件加载由 loadCurrentMonth() 统一处理
    }

    func loadEventsForCurrentMonth() {
        let calendar = Calendar.current
        let startDate = calendar.dateInterval(of: .month, for: currentMonth)?.start ?? currentMonth
        let endDate = calendar.date(byAdding: .month, value: 1, to: startDate)!

        loadEvents(in: DateRange(startDate: startDate, endDate: endDate))
    }

    func loadEvents(for date: Date) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        loadEvents(in: DateRange(startDate: startOfDay, endDate: endOfDay))
    }

    func loadEvents(in dateRange: DateRange) {
        isLoadingEvents = true
        eventLoadError = nil

        Task { @MainActor in
            do {
                let fetchedEvents = try await eventService.getEvents(in: dateRange)
                events = fetchedEvents
                isLoadingEvents = false
            } catch {
                eventLoadError = error
                isLoadingEvents = false
                Logger.error("Failed to load events: \(error)", category: Logger.calendar)
            }
        }
    }

    func getEventsForDate(_ date: Date) -> [CalendarEvent] {
        // 优化：直接从 calendarDates 获取，避免重复过滤
        guard let calendarDate = calendarDates.first(where: {
            Calendar.current.isDate($0.gregorianDate, inSameDayAs: date)
        }) else {
            return []
        }
        return calendarDate.calendarEvents
    }

    func refreshEvents() {
        loadEventsForCurrentMonth()
    }

    // MARK: - Event Actions

    func createEvent(_ event: CalendarEvent) async throws {
        try await eventService.createEvent(event)
        refreshEvents()
    }

    func updateEvent(_ event: CalendarEvent) async throws {
        try await eventService.updateEvent(event)
        refreshEvents()
    }

    func deleteEvent(_ event: CalendarEvent) async throws {
        try await eventService.deleteEvent(event.id)
        refreshEvents()
    }

    // MARK: - Subscription Management

    func refreshAllSubscriptions() async {
        do {
            try await subscriptionService.getAllSubscriptions()
                .sink(receiveCompletion: { _ in }, receiveValue: { _ in })
                .store(in: &cancellables)
        } catch {
            Logger.error("Failed to refresh subscriptions: \(error)", category: Logger.calendar)
        }
    }

    func addSubscription(_ subscription: CalendarSubscription) async throws {
        try await subscriptionService.addSubscription(subscription)
        refreshEvents()
    }

    func removeSubscription(_ subscriptionId: UUID) async throws {
        try await subscriptionService.removeSubscription(subscriptionId)
        refreshEvents()
    }
}
