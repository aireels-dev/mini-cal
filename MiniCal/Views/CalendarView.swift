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
                        // 事件点击处理 - 可以显示事件详情
                        print("Event tapped: \(event.title)")
                    },
                    onManageEvents: {
                        // 关闭事件详情弹窗
                        showEventDetail = false
                        // 打开设置窗口（订阅管理部分）
                        openSettingsAction?()
                        // 发送通知定位到订阅管理标签
                        NotificationCenter.default.post(name: .openSubscriptionManagement, object: nil)
                    },
                    onSaveEvent: { event in
                        Task {
                            do {
                                try await viewModel.createEvent(event)
                                Logger.info("Created local event: \(event.title)", category: Logger.calendar)

                                // 保存选中的日期
                                let savedDate = selectedDateForDetail?.gregorianDate ?? Date()

                                // 立即刷新日历数据
                                await MainActor.run {
                                    viewModel.loadCurrentMonth()
                                }

                                // 等待数据加载完成后重新打开Popover显示更新后的事件
                                try await Task.sleep(nanoseconds: 300_000_000)  // 0.3秒

                                await MainActor.run {
                                    // 关闭Popover
                                    showEventDetail = false

                                    // 短暂延迟后重新打开，显示更新后的数据
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        // 重新查找更新后的日期数据
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
        .alert("recommendation.security_alert.title".localized(), isPresented: $showingSecurityAlert) {
            Button("recommendation.security_alert.cancel".localized(), role: .cancel) {
                pendingSubscription = nil
            }
            Button("recommendation.security_alert.confirm".localized()) {
                confirmSubscribe()
            }
        } message: {
            if let recommendation = pendingSubscription {
                Text(String(
                    format: "recommendation.security_alert.message".localized(),
                    recommendation.name.localized(),
                    recommendation.provider
                ))
            }
        }
    }

    // MARK: - Keyboard Shortcuts Monitor

    private func setupSettingsKeyMonitor() {
        // 移除旧监听器（如果存在）
        removeSettingsKeyMonitor()

        // 添加快捷键监听（Command+,, Command+/-, Command+=）
        settingsKeyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // 检查窗口焦点：只在日历浮窗有焦点时响应
            guard self.isCalendarWindowActive() else {
                return event
            }

            // 检查文本输入焦点：避免拦截文本框输入
            if NSApp.keyWindow?.firstResponder as? NSTextView != nil {
                return event
            }

            // 必须按下 Command 键
            guard event.modifierFlags.contains(.command) else {
                return event
            }

            let key = event.charactersIgnoringModifiers ?? ""

            // Command+, 打开设置
            if key == "," {
                self.openSettingsAction?()
                return nil
            }
            // Command+- 减小日历尺寸
            else if key == "-" {
                self.settingsManager.decreaseCalendarSize()
                return nil
            }
            // Command+= 或 Command++ 增大日历尺寸
            else if key == "=" || key == "+" {
                self.settingsManager.increaseCalendarSize()
                return nil
            }

            return event
        }
    }

    /// 检查日历窗口是否处于活动状态
    private func isCalendarWindowActive() -> Bool {
        guard let keyWindow = NSApp.keyWindow else { return false }
        // 检查是否是 NSPopover 的窗口（日历浮窗）
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
            // 获取新的日历类型
            if let calendarType = notification.userInfo?["calendarType"] as? CalendarType {
                // 检查是否有推荐
                let recommendations = self.recommendationService.getRecommendations(
                    for: calendarType,
                    excludeDismissed: true,
                    limit: 3
                )

                // 如果有推荐，显示推荐卡片
                if !recommendations.isEmpty {
                    self.recommendedCalendarType = calendarType
                    withAnimation(.spring(response: 0.3)) {
                        self.showRecommendationCard = true
                    }

                    // 标记推荐已显示
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
        // 设置中添加订阅时，所有推荐源都需要显示安全确认弹窗
        pendingSubscription = recommendation
        showingSecurityAlert = true
    }

    private func confirmSubscribe() {
        guard let recommendation = pendingSubscription else { return }

        Task {
            do {
                try await recommendationService.subscribe(recommendation, userConfirmed: true)
                Logger.info("Successfully subscribed to: \(recommendation.name.localized())", category: Logger.app)

                // 订阅成功后关闭推荐卡片
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
