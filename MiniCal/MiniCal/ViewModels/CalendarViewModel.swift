//
//  CalendarViewModel.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation
import Combine

class CalendarViewModel: ObservableObject {
    @Published var currentMonth: Date
    @Published var calendarDates: [CalendarDate] = []
    @Published var monthYearText: String = ""
    @Published var selectedDate: Date?

    private let calendarService: CalendarService
    private let settingsManager: SettingsManager
    private var cancellables = Set<AnyCancellable>()

    init(calendarService: CalendarService = CalendarService(),
         settingsManager: SettingsManager = SettingsManager()) {
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
    }

    // MARK: - Data Loading

    func loadCurrentMonth() {
        let secondaryCalendar = settingsManager.currentSettings.secondaryCalendarType
        calendarDates = calendarService.generateMonth(for: currentMonth, secondaryCalendar: secondaryCalendar)
        monthYearText = calendarService.monthYearText(for: currentMonth)
    }

    // MARK: - Navigation

    func goToPreviousMonth() {
        currentMonth = calendarService.previousMonth(from: currentMonth)
        loadCurrentMonth()
    }

    func goToNextMonth() {
        currentMonth = calendarService.nextMonth(from: currentMonth)
        loadCurrentMonth()
    }

    func goToToday() {
        currentMonth = calendarService.today()
        selectedDate = currentMonth
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
        return ["日", "一", "二", "三", "四", "五", "六"]
    }
}
