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
    case month  // 月份切换（使用左右动效）
    case year   // 年份切换（使用上下动效）
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

    init(calendarService: CalendarService = CalendarService(),
         settingsManager: SettingsManager = SettingsManager.shared) {
        self.calendarService = calendarService
        self.settingsManager = settingsManager
        self.currentMonth = Date()

        setupObservers()
        loadCurrentMonth()
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

            // 动画完成后重置立即生效的状态
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                self.currentNavigationType = .none
                self.currentNavigationDirection = .none
            }

            complete()
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
}
