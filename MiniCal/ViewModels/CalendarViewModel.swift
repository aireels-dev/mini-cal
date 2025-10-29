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
    case forward  // 向下个月前进
    case backward // 向上个月后退
    case none     // 无方向（如跳转到今天）
}

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var calendarDates: [CalendarDate] = []
    @Published var monthYearText: String = ""
    @Published var selectedDate: Date?
    @Published var navigationDirection: NavigationDirection = .none

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

            complete()
        }
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        navigationDirection = .backward
        Logger.measureTime(operation: "Navigate to previous month", category: Logger.performance) {
            currentMonth = calendarService.previousMonth(from: currentMonth)
        }
        loadCurrentMonth()
    }

    func goToNextMonth() {
        navigationDirection = .forward
        Logger.measureTime(operation: "Navigate to next month", category: Logger.performance) {
            currentMonth = calendarService.nextMonth(from: currentMonth)
        }
        loadCurrentMonth()
    }

    func goToToday() {
        navigationDirection = .none
        currentMonth = calendarService.today()
        selectedDate = currentMonth
        loadCurrentMonth()
    }

    func goToPreviousYear() {
        navigationDirection = .backward
        Logger.measureTime(operation: "Navigate to previous year", category: Logger.performance) {
            let calendar = Calendar.current
            currentMonth = calendar.date(byAdding: .year, value: -1, to: currentMonth) ?? currentMonth
        }
        loadCurrentMonth()
    }

    func goToNextYear() {
        navigationDirection = .forward
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
