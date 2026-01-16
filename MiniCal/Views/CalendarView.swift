//
//  CalendarView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject private var themeManager = ThemeManager.shared
    @StateObject private var recommendationService = SubscriptionRecommendationService.shared
    @State private var selectedDateForDetail: CalendarDate?
    @State private var showEventDetail = false
    @State private var settingsKeyMonitor: Any?
    @State private var showRecommendationCard = false
    @State private var recommendedCalendarType: CalendarType?
    @State private var showingSecurityAlert = false
    @State private var pendingSubscription: RecommendedSubscription?

    var openSettingsAction: (() -> Void)?

    init(viewModel: CalendarViewModel? = nil) {
        self.viewModel = viewModel ?? CalendarViewModel()
    }

    private var effectiveColors: ThemeColors {
        // 使用ThemeManager获取当前有效的主题颜色（处理系统跟随）
        themeManager.effectiveColors
    }

    private var calendarSize: CalendarSize {
        settingsManager.currentSettings.calendarSize
    }

    private var calendarOpacity: Double {
        settingsManager.currentSettings.calendarOpacity
    }

    var body: some View {
        if #available(macOS 12.0, *) {
            contentView
                .alert("recommendation.security_alert.title".localized(), isPresented: $showingSecurityAlert) {
                    Button("recommendation.security_alert.cancel".localized(), role: .cancel) {
                        pendingSubscription = nil
                    }
                    Button("recommendation.security_alert.confirm".localized()) {
                        confirmSubscribe()
                    }
                } message: {
                    if pendingSubscription != nil {
                        Text(securityAlertMessage)
                    }
                }
        } else {
            contentView
                .alert(isPresented: $showingSecurityAlert) {
                    let title = Text("recommendation.security_alert.title".localized())
                    let message = Text(securityAlertMessage)
                    let cancel = Alert.Button.cancel(Text("recommendation.security_alert.cancel".localized())) {
                        pendingSubscription = nil
                    }
                    let confirm = Alert.Button.default(Text("recommendation.security_alert.confirm".localized())) {
                        confirmSubscribe()
                    }
                    return Alert(title: title, message: message, primaryButton: confirm, secondaryButton: cancel)
                }
        }
    }

    private var contentView: some View {
        ZStack {
            // 背景层（应用不透明度）
            ZStack {
                // 第一层：Glass 效果背景
                VisualEffectView(
                    material: .hudWindow,
                    blendingMode: .behindWindow,
                    state: .active
                )

                // 第二层：主题表面色 - 使用 surface 而不是 background
                Color(hex: effectiveColors.surface)
                    .opacity(0.92)
            }
            .cornerRadius(12)
            .opacity(calendarOpacity)  // 背景层不透明度

            // 内容层（不应用不透明度，保持文字清晰）
            VStack(spacing: 0) {
                // 日历头部（通过颜色和间距区分层级）
                CalendarHeaderView(
                    viewModel: viewModel,
                    themeColors: effectiveColors
                )
                .padding(.bottom, 12)

                // 日历网格
                CalendarGridView(
                    viewModel: viewModel,
                    themeColors: effectiveColors,
                    calendarSize: calendarSize,
                    onDateTap: { date in
                        selectedDateForDetail = date
                        showEventDetail = true
                    }
                )
                .padding(.bottom, 16)

                Spacer()
            }

            // 推荐卡片层（底部）
            if showRecommendationCard, let calendarType = recommendedCalendarType {
                VStack {
                    Spacer()

                    CalendarSwitchRecommendationCard(
                        calendarType: calendarType,
                        recommendations: recommendationService.getRecommendations(for: calendarType, excludeDismissed: true, limit: 3),
                        onSubscribe: { recommendation in
                            handleSubscribe(recommendation)
                        },
                        onDismiss: {
                            showRecommendationCard = false
                            if let type = recommendedCalendarType {
                                recommendationService.dismissRecommendationForSession("\(type.rawValue)_switch")
                            }
                        },
                        onDismissForever: {
                            showRecommendationCard = false
                            if let type = recommendedCalendarType {
                                recommendationService.dismissRecommendationPermanently("\(type.rawValue)_switch")
                            }
                        }
                    )
                }
            }
        }
        .frame(width: calendarSize.width, height: calendarSize.height)
        .applyLocalizationContext()  // 应用本地化上下文（包括 RTL 布局）
        .popover(isPresented: $showEventDetail, arrowEdge: .bottom) {
            if let selectedDate = selectedDateForDetail {
                DayEventListView(
                    date: selectedDate.gregorianDate,
                    events: selectedDate.calendarEvents,
                    themeColors: effectiveColors,
                    calendarSize: calendarSize,
                    onEventTap: { event in
                        print("Event tapped: \(event.title)")
                    },
                    onManageEvents: {
                        showEventDetail = false
                        openSettingsAction?()
                        NotificationCenter.default.post(name: .openSubscriptionManagement, object: nil)
                    },
                    onSaveEvent: { event in
                        Task {
                            do {
                                try await viewModel.createEvent(event)
                                Logger.info("Created local event: \(event.title)", category: Logger.calendar)

                                let savedDate = selectedDateForDetail?.gregorianDate ?? Date()

                                await MainActor.run {
                                    viewModel.loadCurrentMonth()
                                }

                                try await Task.sleep(nanoseconds: 300_000_000)

                                await MainActor.run {
                                    showEventDetail = false

                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let updatedDate = viewModel.calendarDates.first(where: {
                                            Calendar.current.isDate($0.gregorianDate, inSameDayAs: savedDate)
                                        }) {
                                            selectedDateForDetail = updatedDate
                                            showEventDetail = true
                                        }
                                    }
                                }
                            } catch {
                                Logger.error("Failed to create event: \(error)", category: Logger.calendar)
                            }
                        }
                    }
                )
            }
        }
        .onAppear {
            setupSettingsKeyMonitor()
            setupResetNotification()
            setupCalendarTypeChangeNotification()
        }
        .onDisappear {
            removeSettingsKeyMonitor()
            removeResetNotification()
            removeCalendarTypeChangeNotification()
        }
    }

    private var securityAlertMessage: String {
        "recommendation.security_alert.message".localized(with: AppBrand.displayName)
    }

    // MARK: - Keyboard Shortcuts Monitor

    private func setupSettingsKeyMonitor() {
        removeSettingsKeyMonitor()

        settingsKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard self.isCalendarWindowActive() else {
                return event
            }

            if NSApp.keyWindow?.firstResponder as? NSTextView != nil {
                return event
            }

            guard event.modifierFlags.contains(.command) else {
                return event
            }

            let key = event.charactersIgnoringModifiers ?? ""

            if key == "," {
                self.openSettingsAction?()
                return nil
            } else if key == "-" {
                self.settingsManager.decreaseCalendarSize()
                return nil
            } else if key == "=" || key == "+" {
                self.settingsManager.increaseCalendarSize()
                return nil
            }

            return event
        }
    }

    private func isCalendarWindowActive() -> Bool {
        guard let keyWindow = NSApp.keyWindow else { return false }
        return keyWindow.className.contains("NSPopover")
    }

    private func removeSettingsKeyMonitor() {
        if let monitor = settingsKeyMonitor {
            NSEvent.removeMonitor(monitor)
            settingsKeyMonitor = nil
        }
    }

    // MARK: - Reset Notification

    private func setupResetNotification() {
        NotificationCenter.default.addObserver(
            forName: .resetCalendarToToday,
            object: nil,
            queue: .main
        ) { [weak viewModel] _ in
            viewModel?.goToToday()
        }
    }

    private func removeResetNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: .resetCalendarToToday,
            object: nil
        )
    }

    // MARK: - Calendar Type Change Notification

    private func setupCalendarTypeChangeNotification() {
        NotificationCenter.default.addObserver(
            forName: .calendarTypeDidChange,
            object: nil,
            queue: .main
        ) { notification in
            let calendarType = notification.userInfo?["calendarType"] as? CalendarType
            Task { @MainActor in
                guard let calendarType = calendarType else { return }

                let recommendations = self.recommendationService.getRecommendations(
                    for: calendarType,
                    excludeDismissed: true,
                    limit: 3
                )

                if !recommendations.isEmpty {
                    self.recommendedCalendarType = calendarType
                    withAnimation(.spring(response: 0.3)) {
                        self.showRecommendationCard = true
                    }

                    for recommendation in recommendations {
                        self.recommendationService.markRecommendationShown(recommendation.id)
                    }

                    Logger.info("Showing \(recommendations.count) recommendations for \(calendarType.displayName)", category: Logger.app)
                } else {
                    Logger.debug("No recommendations available for \(calendarType.displayName)", category: Logger.app)
                }
            }
        }
    }

    private func removeCalendarTypeChangeNotification() {
        NotificationCenter.default.removeObserver(
            self,
            name: .calendarTypeDidChange,
            object: nil
        )
    }

    // MARK: - Recommendation Handlers

    private func handleSubscribe(_ recommendation: RecommendedSubscription) {
        pendingSubscription = recommendation
        showingSecurityAlert = true
    }

    private func confirmSubscribe() {
        guard let recommendation = pendingSubscription else { return }

        Task {
            do {
                try await recommendationService.subscribe(recommendation, userConfirmed: true)
                Logger.info("Successfully subscribed to: \(recommendation.name.localized())", category: Logger.app)

                await MainActor.run {
                    showRecommendationCard = false
                    pendingSubscription = nil
                }
            } catch {
                Logger.error("Failed to subscribe: \(error)", category: Logger.app)
                await MainActor.run {
                    pendingSubscription = nil
                }
            }
        }
    }
}

#Preview {
    CalendarView()
}
