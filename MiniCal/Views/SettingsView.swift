//
//  SettingsView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI
import Combine
import EventKit

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @ObservedObject var calendarViewModel: CalendarViewModel
    @State private var selectedTab: SettingsTab = .menuBar

    init(calendarViewModel: CalendarViewModel? = nil) {
        self.calendarViewModel = calendarViewModel ?? CalendarViewModel()
    }

    var body: some View {
        VStack(spacing: 12) {
            Picker("", selection: $selectedTab) {
                ForEach(SettingsTab.allCases, id: \.self) { tab in
                    Label(tab.titleKey.localized(), systemImage: tab.systemImageName)
                        .tag(tab)
                }
            }
            .pickerStyle(.segmented)

            Group {
                switch selectedTab {
                case .menuBar:
                    MenuBarSettingsView(settingsManager: settingsManager)
                case .calendar:
                    CalendarSettingsView(settingsManager: settingsManager, calendarViewModel: calendarViewModel)
                case .appearance:
                    AppearanceSettingsView(settingsManager: settingsManager)
                }
            }
        }
        .frame(width: 580, height: 700)
        .padding()
        .onAppear {
            setupTabNavigationNotification()
        }
    }

    private func setupTabNavigationNotification() {
        NotificationCenter.default.addObserver(
            forName: .openSubscriptionManagement,
            object: nil,
            queue: .main
        ) { [self] _ in
            self.selectedTab = .calendar  // 切换到日历tab
        }
    }
}

private enum SettingsTab: Int, CaseIterable {
    case menuBar
    case calendar
    case appearance

    var titleKey: String {
        switch self {
        case .menuBar:
            return "menu_bar.title"
        case .calendar:
            return "menu_bar.calendar"
        case .appearance:
            return "menu_bar.appearance"
        }
    }

    var systemImageName: String {
        switch self {
        case .menuBar:
            return "menubar.rectangle"
        case .calendar:
            return "calendar"
        case .appearance:
            return "paintbrush"
        }
    }
}

// MARK: - 菜单栏设置

struct MenuBarSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @State private var isEditingCustomFormat = false
    @State private var localSettings: UserSettings

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self._localSettings = State(initialValue: settingsManager.currentSettings)
    }

    var body: some View {
        Form {
            // 应用设置
            section("settings.app.section") {
                // 全局快捷键
                Toggle("settings.app.global_hotkey", isOn: $localSettings.globalHotkeyEnabled)
                    .onChange(of: localSettings.globalHotkeyEnabled) { newValue in
                        var updated = settingsManager.currentSettings
                        updated.globalHotkeyEnabled = newValue
                        updated.lastUpdated = Date()
                        settingsManager.saveSettings(updated)
                    }

                if localSettings.globalHotkeyEnabled {
                    HotkeyRecorder()
                }

                // 开机自启动
                Toggle("settings.app.launch_at_login", isOn: $localSettings.launchAtLogin)
                    .onChange(of: localSettings.launchAtLogin) { newValue in
                        var updated = settingsManager.currentSettings
                        updated.launchAtLogin = newValue
                        updated.lastUpdated = Date()
                        settingsManager.saveSettings(updated)
                        // 应用设置
                        LaunchAtLoginManager.shared.setLaunchAtLogin(newValue)
                    }

                // 重新显示引导
                Button("settings.app.show_onboarding".localized()) {
                    // 发送通知请求显示引导
                    NotificationCenter.default.post(name: .showOnboardingRequested, object: nil)
                }
                .buttonStyle(.link)
            }

            // 菜单栏显示
            section("settings.menu_bar.display") {
                // 实时预览
                VStack(alignment: .leading, spacing: 4) {
                    Text("event.live_preview")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(previewText)
                        .font(.system(size: 13))
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                }
                .padding(.bottom, 8)

                // 显示格式
                Picker("settings.menu_bar.format", selection: $localSettings.menuBarFormat) {
                    ForEach(MenuBarFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .onChange(of: localSettings.menuBarFormat) { newValue in
                    // 切换到自定义格式时自动进入编辑态
                    if newValue == .custom {
                        isEditingCustomFormat = true
                    }
                    settingsManager.updateMenuBarFormat(newValue)
                }

                // 自定义格式编辑组件
                if localSettings.menuBarFormat == .custom {
                    CustomFormatEditor(
                        customFormat: $localSettings.customFormat,
                        isEditing: $isEditingCustomFormat,
                        onFormatChange: { newFormat in
                            var updated = settingsManager.currentSettings
                            updated.customFormat = newFormat
                            settingsManager.saveSettings(updated)
                        }
                    )
                }

                let isCustomFormat = localSettings.menuBarFormat == .custom

                Toggle("settings.menu_bar.24hour", isOn: $localSettings.show24Hour)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
                    .onChange(of: localSettings.show24Hour) { newValue in
                        settingsManager.updateShow24Hour(newValue)
                    }

                Toggle("settings.menu_bar.show_weekday", isOn: $localSettings.showWeekday)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
                    .onChange(of: localSettings.showWeekday) { newValue in
                        settingsManager.updateShowWeekday(newValue)
                    }

                Toggle("settings.menu_bar.show_seconds", isOn: $localSettings.showSeconds)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
                    .onChange(of: localSettings.showSeconds) { newValue in
                        var updated = settingsManager.currentSettings
                        updated.showSeconds = newValue
                        updated.lastUpdated = Date()
                        settingsManager.saveSettings(updated)
                    }
            }

            // 日历交互
            section("settings.calendar.interaction") {
                Toggle("settings.calendar.hover_enable", isOn: $localSettings.hoverToShowEnabled)
                    .onChange(of: localSettings.hoverToShowEnabled) { newValue in
                        settingsManager.updateHoverSettings(enabled: newValue, delay: localSettings.hoverDelay)
                    }

                if localSettings.hoverToShowEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Slider(
                            value: $localSettings.hoverDelay,
                            in: 0.1...2.0,
                            step: 0.1
                        ) {
                            Text("event.hover_delay")
                        }
                        .onChange(of: localSettings.hoverDelay) { newValue in
                            settingsManager.updateHoverSettings(enabled: localSettings.hoverToShowEnabled, delay: newValue)
                        }
                        Text(String(format: NSLocalizedString("settings.calendar.hover_delay_seconds", comment: ""), localSettings.hoverDelay))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }

            // 每周起始日
            section("settings.week_start.section") {
                Picker(selection: $localSettings.weekStartDay) {
                    ForEach(WeekStartDay.allCases, id: \.self) { weekStart in
                        VStack(alignment: .leading) {
                            Text(weekStart.displayName)
                                .font(.body)
                            Text(weekStart.shortDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(weekStart)
                    }
                } label: {
                    Text("settings.week_start.label".localized())
                }
                .onChange(of: localSettings.weekStartDay) { newValue in
                    settingsManager.updateWeekStartDay(newValue)
                }

                Text("settings.week_start.description".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .groupedFormStyleIfAvailable()
        .onAppear {
            localSettings = settingsManager.currentSettings
        }
        .onChange(of: settingsManager.currentSettings) { newValue in
            localSettings = newValue
        }
    }

    private var previewText: String {
        let format = settingsManager.currentSettings.menuBarFormat
        return format.format(
            date: Date(),
            show24Hour: settingsManager.currentSettings.show24Hour,
            showWeekday: settingsManager.currentSettings.showWeekday,
            showSeconds: settingsManager.currentSettings.showSeconds,
            customFormat: settingsManager.currentSettings.customFormat
        )
    }
}

// MARK: - 自定义格式编辑器

struct CustomFormatEditor: View {
    @Binding var customFormat: String
    @Binding var isEditing: Bool
    let onFormatChange: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                // 输入态
                TextField("settings.format.custom", text: $customFormat, onCommit: {
                    // 回车键切换到展示态并保存
                    isEditing = false
                    onFormatChange(customFormat)
                })
                .textFieldStyle(.roundedBorder)

                // 输入态时显示格式说明
                FormatGuideView()
            } else {
                // 展示态
                HStack {
                    Text(customFormat)
                        .font(.system(size: 13))
                        .foregroundColor(.primary)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.1))
                        .cornerRadius(6)
                        .onTapGesture {
                            // 点击切换到输入态
                            isEditing = true
                        }

                    Button(action: {
                        isEditing = true
                    }) {
                        Image(systemName: "pencil")
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                    .help("settings.format.edit_help")
                }
            }
        }
    }
}

// MARK: - 格式说明视图

struct FormatGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("event.format_symbols")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            FormatExampleView(symbol: "yyyy", description: "settings.format.year_4digit", example: "2025")
            FormatExampleView(symbol: "yy", description: "settings.format.year_2digit", example: "25")
            FormatExampleView(symbol: "M", description: "settings.format.month", example: "1, 12")
            FormatExampleView(symbol: "MM", description: "settings.format.month_padded", example: "01, 12")
            FormatExampleView(symbol: "d", description: "settings.format.day", example: "1, 31")
            FormatExampleView(symbol: "dd", description: "settings.format.day_padded", example: "01, 31")
            FormatExampleView(symbol: "E", description: "settings.format.weekday", example: "周一")
            FormatExampleView(symbol: "w", description: "settings.format.week_of_year", example: "1-53")
            FormatExampleView(symbol: "W", description: "settings.format.week_of_month", example: "1-5")
            FormatExampleView(symbol: "HH", description: "settings.format.hour_24", example: "00-23")
            FormatExampleView(symbol: "h", description: "settings.format.hour_12", example: "1-12")
            FormatExampleView(symbol: "mm", description: "settings.format.minute", example: "00-59")
            FormatExampleView(symbol: "ss", description: "settings.format.second", example: "00-59")
            FormatExampleView(symbol: "a", description: "settings.format.am_pm", example: "AM, PM")

            Text("event.format_example")
                .font(.caption)
                .foregroundColor(.blue)
                .padding(.top, 4)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 格式示例视图

struct FormatExampleView: View {
    let symbol: String
    let description: LocalizedStringKey
    let example: String

    var body: some View {
        HStack(spacing: 8) {
            Text(symbol)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.primary)
                .frame(width: 40, alignment: .leading)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 80, alignment: .leading)

            Text("common.arrow")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(example)
                .font(.caption)
                .foregroundColor(.blue)
        }
    }
}

// MARK: - 日历设置

struct CalendarSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject var calendarViewModel: CalendarViewModel
    @State private var localSettings: UserSettings
    @StateObject private var permissionManager = PermissionManager.shared
    @StateObject private var subscriptionViewModel = SubscriptionManagerViewModel()
    @StateObject private var localGroupService = LocalEventGroupService.shared

    @State private var showingAddSubscription = false
    @State private var showingAddError = false
    @State private var addErrorMessage = ""
    @State private var isAddingSubscription = false
    @State private var systemCalendarEventCounts: [String: Int] = [:]  // 系统日历ID -> 事件数
    @State private var localGroupEventCounts: [UUID: Int] = [:]  // 本地组ID -> 事件数
    @State private var showingAddLocalGroup = false

    init(settingsManager: SettingsManager, calendarViewModel: CalendarViewModel) {
        self.settingsManager = settingsManager
        self.calendarViewModel = calendarViewModel
        self._localSettings = State(initialValue: settingsManager.currentSettings)
    }

    var body: some View {
        if #available(macOS 12.0, *) {
            contentView
                .alert("subscription.add_failed", isPresented: $showingAddError) {
                    Button("common.ok", role: .cancel) {
                        showingAddError = false
                    }
                } message: {
                    Text(addErrorMessage)
                }
        } else {
            contentView
                .alert(isPresented: $showingAddError) {
                    let title = Text("subscription.add_failed".localized())
                    let message = Text(addErrorMessage)
                    let cancel = Alert.Button.cancel(Text("common.ok".localized())) {
                        showingAddError = false
                    }
                    return Alert(title: title, message: message, dismissButton: cancel)
                }
        }
    }

    private var contentView: some View {
        Form {
            // Section 1: 本地历法
            section("settings.calendar.secondary") {
                Picker("settings.calendar.type_label", selection: $localSettings.secondaryCalendarType) {
                    Text("settings.calendar.none").tag(nil as CalendarType?)
                    ForEach(CalendarType.allCases.filter { $0 != .gregorian }, id: \.self) { type in
                        Text(type.displayName).tag(type as CalendarType?)
                    }
                }
                .onChange(of: localSettings.secondaryCalendarType) { newValue in
                    settingsManager.updateSecondaryCalendar(newValue)
                }

                Text("settings.calendar.description")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Section 2: 系统同步
            Section {
                systemCalendarSyncContent
            } header: {
                HStack {
                    Text("settings.calendar.system_sync")
                    Spacer()
                    permissionStatusBadge
                }
            }

            // Section 3: 外部订阅（包含按钮）
            section("settings.calendar.external_subscriptions") {
                externalSubscriptionContent
            }

            // Section 4: 本地管理
            section("settings.calendar.local_management") {
                localEventGroupContent
            }
        }
        .groupedFormStyleIfAvailable()
        .onAppear {
            localSettings = settingsManager.currentSettings
            subscriptionViewModel.loadSubscriptions()
            loadSystemCalendarEventCounts()
            loadLocalGroupEventCounts()
        }
        .onChange(of: settingsManager.currentSettings) { newValue in
            localSettings = newValue
        }
        .onChange(of: calendarViewModel.events) { _ in
            // 事件列表变化时重新统计事件数
            loadSystemCalendarEventCounts()
            loadLocalGroupEventCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .localEventGroupsDidUpdate)) { _ in
            // 本地组配置变化时重新加载事件数
            loadLocalGroupEventCounts()
        }
        .onReceive(NotificationCenter.default.publisher(for: .subscriptionDidUpdate)) { _ in
            // 订阅配置变化时重新加载订阅
            subscriptionViewModel.loadSubscriptions()
        }
        .sheet(isPresented: $showingAddSubscription) {
            AddSubscriptionSheetView(
                isProcessing: $isAddingSubscription,
                onAdd: { urlString in
                    print("📅 [Subscription] Adding subscription: \(urlString)")
                    Logger.info("Adding subscription: \(urlString)", category: Logger.calendar)
                    isAddingSubscription = true
                    Task {
                        do {
                            print("🔄 [Subscription] Calling addSubscription...")
                            try await subscriptionViewModel.addSubscription(urlString: urlString)
                            print("✅ [Subscription] Successfully added subscription")
                            Logger.info("Successfully added subscription", category: Logger.calendar)
                            await MainActor.run {
                                isAddingSubscription = false
                                showingAddSubscription = false
                            }
                        } catch {
                            print("❌ [Subscription] Failed to add subscription: \(error.localizedDescription)")
                            Logger.error("Failed to add subscription: \(error.localizedDescription)", category: Logger.calendar)
                            await MainActor.run {
                                isAddingSubscription = false
                                showingAddSubscription = false  // 关闭弹窗
                                addErrorMessage = error.localizedDescription
                                showingAddError = true
                            }
                        }
                    }
                },
                onCancel: {
                    showingAddSubscription = false
                }
            )
        }
    }

    // MARK: - System Calendar Sync Content

    @ViewBuilder
    private var systemCalendarSyncContent: some View {
        if !permissionManager.isAuthorized {
            // 未授权状态
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))

                    Text("permission.calendar.required")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }

                Text("permission.calendar.description")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)

                Button(action: {
                    print("🔘 [UI] Permission request button clicked")
                    Logger.info("Permission request button clicked", category: Logger.app)
                    Task {
                        print("🔄 [UI] Task started, calling requestEventKitAccess()")
                        Logger.info("Calling permissionManager.requestEventKitAccess()", category: Logger.app)
                        let granted = await permissionManager.requestEventKitAccess()
                        print("📬 [UI] requestEventKitAccess() returned: \(granted)")
                        Logger.info("requestEventKitAccess() returned: \(granted)", category: Logger.app)
                        if !granted && permissionManager.authorizationStatus == .denied {
                            // 权限被拒绝,已自动打开系统设置
                            print("⚠️ [UI] Permission denied, System Preferences should be opened")
                            Logger.info("Permission denied, opened System Preferences", category: Logger.app)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: permissionManager.authorizationStatus == .denied ? "gear" : "lock.open.fill")
                        Text(permissionManager.authorizationStatus == .denied ? "permission.calendar.open_settings" : "permission.calendar.request")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(permissionManager.authorizationStatus == .denied ? Color.orange : Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)

                if permissionManager.authorizationStatus == .denied {
                    Text("permission.calendar.hint")
                        .font(.system(size: 11))
                        .foregroundColor(.orange)
                        .padding(.top, 4)
                }
            }
            .padding(.vertical, 8)
        } else {
            // 已授权状态 - 显示系统日历列表
            VStack(alignment: .leading, spacing: 8) {
                ForEach(permissionManager.systemCalendars, id: \.calendarIdentifier) { calendar in
                    SystemCalendarRow(
                        calendar: calendar,
                        isEnabled: Binding(
                            get: { permissionManager.isCalendarEnabled(calendarIdentifier: calendar.calendarIdentifier) },
                            set: { newValue in permissionManager.setCalendarEnabled(calendarIdentifier: calendar.calendarIdentifier, enabled: newValue) }
                        ),
                        permissionManager: permissionManager,
                        eventCount: systemCalendarEventCounts[calendar.calendarIdentifier] ?? 0,
                        onToggle: {
                            // 触发日历数据重新加载
                            NotificationCenter.default.post(name: .calendarEnabledStateChanged, object: nil)
                        },
                        onColorUpdate: { newColor in
                            permissionManager.updateCalendarColor(
                                calendarIdentifier: calendar.calendarIdentifier,
                                color: newColor
                            )
                        }
                    )
                }

                if permissionManager.systemCalendars.isEmpty {
                    Text("common.no_system_calendars")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                        .padding(.vertical, 8)
                }
            }
        }
    }

    // MARK: - External Subscription Content

    @ViewBuilder
    private var externalSubscriptionContent: some View {
        VStack(spacing: 0) {
            // 订阅列表或空状态
            if subscriptionViewModel.subscriptions.isEmpty {
                // 空状态提示
                VStack(spacing: 8) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                    VStack(spacing: 4) {
                        Text("common.no_subscriptions")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("subscription.click_to_add")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                // 订阅列表
                ForEach(subscriptionViewModel.subscriptions) { subscription in
                    ExternalSubscriptionCompactRow(
                        subscription: subscription,
                        onToggle: {
                            Task {
                                await subscriptionViewModel.toggleSubscription(subscription.id)
                            }
                        },
                        onUpdate: { updatedSubscription in
                            Task {
                                await subscriptionViewModel.updateSubscription(updatedSubscription)
                            }
                        },
                        onDelete: {
                            subscriptionViewModel.confirmDelete(subscription)
                        }
                    )
                }
            }

            // 操作按钮（在列表底部）
            Divider()
                .padding(.top, 8)
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                // 添加订阅按钮（主按钮）
                Button(action: {
                    showingAddSubscription = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("subscription.add")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("subscription.add_help")

                // 刷新全部按钮（仅在有订阅时显示）
                if !subscriptionViewModel.subscriptions.isEmpty {
                    Button(action: {
                        Task {
                            await subscriptionViewModel.refreshAllSubscriptions()
                        }
                    }) {
                        HStack(spacing: 6) {
                            if subscriptionViewModel.isRefreshing {
                                ProgressView()
                                    .scaleEffect(0.6)
                                    .frame(width: 12, height: 12)
                            } else {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                            }
                            Text("subscription.refresh_all")
                        }
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 7)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .disabled(subscriptionViewModel.isRefreshing)
                    .help("subscription.refresh_all_help")
                }

                Spacer()
            }
        }
    }

    // MARK: - Local Event Group Content

    @ViewBuilder
    private var localEventGroupContent: some View {
        VStack(spacing: 0) {
            // 类别列表
            ForEach(localGroupService.groups) { group in
                LocalEventGroupCompactRow(
                    group: group,
                    eventCount: localGroupEventCounts[group.id] ?? 0,
                    onUpdate: { updatedGroup in
                        localGroupService.updateGroup(updatedGroup)
                        // 刷新日历视图
                        CalendarGroupService.shared.reloadAllGroups()
                    },
                    onDelete: {
                        // 删除类别并迁移事件到默认
                        let success = localGroupService.deleteGroup(id: group.id)
                        if success {
                            // 迁移该类别的所有事件到默认
                            migrateEventsToDefaultGroup(fromGroupId: group.id)
                            // 重新加载事件数
                            loadLocalGroupEventCounts()
                            // 刷新日历视图
                            CalendarGroupService.shared.reloadAllGroups()
                        }
                    }
                )
            }

            // 操作按钮（在列表底部）
            Divider()
                .padding(.top, 8)
                .padding(.bottom, 8)

            HStack(spacing: 12) {
                // 添加组按钮
                Button(action: {
                    showingAddLocalGroup = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("local_group.add")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("local_group.add_help")

                Spacer()
            }
        }
        .sheet(isPresented: $showingAddLocalGroup) {
            AddLocalGroupSheetView(
                onAdd: { title, color in
                    localGroupService.addGroup(title: title, color: color)
                    // 重新加载事件数
                    loadLocalGroupEventCounts()
                    // 刷新日历视图
                    CalendarGroupService.shared.reloadAllGroups()
                    showingAddLocalGroup = false
                },
                onCancel: {
                    showingAddLocalGroup = false
                }
            )
        }
    }

    // MARK: - Helper Methods

    private func loadSystemCalendarEventCounts() {
        // 从calendarViewModel获取所有事件，统计每个系统日历的事件数
        let allEvents = calendarViewModel.events

        var counts: [String: Int] = [:]
        for calendar in permissionManager.systemCalendars {
            // 统计该日历的事件数（通过eventIdentifier或calendarIdentifier匹配）
            let count = allEvents.filter { event in
                event.source == .eventKit &&
                event.eventIdentifier?.contains(calendar.calendarIdentifier) == true
            }.count

            counts[calendar.calendarIdentifier] = count
        }

        systemCalendarEventCounts = counts
    }

    private func loadLocalGroupEventCounts() {
        // 统计每个本地类别的事件数
        let allEvents = calendarViewModel.events

        var counts: [UUID: Int] = [:]
        for group in localGroupService.groups {
            if group.isDefault {
                // 默认类别：包含subscriptionId为该类别ID的事件 + subscriptionId为nil的事件
                let count = allEvents.filter { event in
                    event.source == .user && (event.subscriptionId == group.id || event.subscriptionId == nil)
                }.count
                counts[group.id] = count
            } else {
                // 其他类别：仅统计subscriptionId匹配的事件
                let count = allEvents.filter { event in
                    event.source == .user && event.subscriptionId == group.id
                }.count
                counts[group.id] = count
            }
        }

        localGroupEventCounts = counts
    }

    private func migrateEventsToDefaultGroup(fromGroupId: UUID) {
        // 将指定组的所有事件迁移到默认组
        let defaultGroupId = localGroupService.defaultGroupId

        // 获取需要迁移的事件
        let eventsToMigrate = calendarViewModel.events.filter { event in
            event.source == .user && event.subscriptionId == fromGroupId
        }

        // 更新每个事件的subscriptionId
        Task {
            for var event in eventsToMigrate {
                event.subscriptionId = defaultGroupId
                // 使用 calendarViewModel 更新事件
                try? await calendarViewModel.updateEvent(event)
            }

            Logger.info("Migrated \(eventsToMigrate.count) events from group \(fromGroupId) to default group", category: Logger.calendar)
        }
    }

    // MARK: - Permission Status Badge

    private var permissionStatusBadge: some View {
        HStack(spacing: 4) {
            statusIcon
            Text(statusText)
                .font(.system(size: 10))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .background(statusColor.opacity(0.1))
        .cornerRadius(4)
    }

    private var statusIcon: some View {
        Group {
            switch permissionManager.authorizationStatus {
            case .authorized:
                // macOS 13 及更早版本
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
            case .fullAccess:
                // macOS 14+ 完全访问
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
            case .writeOnly:
                // macOS 14+ 仅写入权限
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
            case .denied, .restricted:
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 8))
            case .notDetermined:
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 8))
            @unknown default:
                Image(systemName: "exclamationmark.circle")
                    .font(.system(size: 8))
            }
        }
    }

    private var statusText: String {
        switch permissionManager.authorizationStatus {
        case .authorized:
            // macOS 13 及更早版本
            return NSLocalizedString("permission.status.authorized", comment: "")
        case .fullAccess:
            // macOS 14+ 完全访问
            return NSLocalizedString("permission.status.full_access", comment: "")
        case .writeOnly:
            // macOS 14+ 仅写入权限
            return NSLocalizedString("permission.status.write_only", comment: "")
        case .denied:
            return NSLocalizedString("permission.status.denied", comment: "")
        case .restricted:
            return NSLocalizedString("permission.status.restricted", comment: "")
        case .notDetermined:
            return NSLocalizedString("permission.status.not_determined", comment: "")
        @unknown default:
            return NSLocalizedString("permission.status.unknown", comment: "")
        }
    }

    private var statusColor: Color {
        switch permissionManager.authorizationStatus {
        case .authorized:
            // macOS 13 及更早版本
            return .green
        case .fullAccess, .writeOnly:
            // macOS 14+ 完全访问或仅写入权限
            return .green
        case .denied, .restricted:
            return .red
        case .notDetermined:
            return .gray
        @unknown default:
            return .orange
        }
    }
}

// MARK: - Add Local Group Sheet View

struct AddLocalGroupSheetView: View {
    let onAdd: (String, EventColor) -> Void
    let onCancel: () -> Void

    @State private var groupTitle = ""
    @State private var selectedColor: EventColor = .blue

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("local_group.add_title")
                .font(.title2)
                .fontWeight(.semibold)

            // 类别名称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("local_group.name")
                    .font(.headline)

                TextField("local_group.placeholder", text: $groupTitle, onCommit: {
                    // 回车键提交
                    if !groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        onAdd(groupTitle, selectedColor)
                    }
                })
                .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("common.color")
                    .font(.headline)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(EventColor.allCases, id: \.self) { color in
                            Button(action: {
                                selectedColor = color
                            }) {
                                ZStack {
                                    Circle()
                                        .fill(color.swiftUIColor)
                                        .frame(width: 36, height: 36)

                                    if color == selectedColor {
                                        Image(systemName: "checkmark")
                                            .font(.system(size: 14, weight: .bold))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                            .buttonStyle(PlainButtonStyle())
                        }
                    }
                }
            }

            // 按钮
            HStack(spacing: 12) {
                Button("common.cancel") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("common.add") {
                    onAdd(groupTitle, selectedColor)
                }
                .disabled(groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
    }
}

// MARK: - Add Subscription Sheet View

struct AddSubscriptionSheetView: View {
    @Binding var isProcessing: Bool
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    @State private var urlString = ""

    var body: some View {
        ZStack {
            // 主内容
            VStack(spacing: 20) {
                // 标题
                Text("subscription.add_title")
                    .font(.title2)
                    .fontWeight(.semibold)

                // URL 输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("subscription.url")
                        .font(.headline)

                    TextField("https://calendar.example.com/calendar.ics", text: $urlString, onCommit: {
                        // 回车键提交
                        if !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing {
                            onAdd(urlString)
                        }
                    })
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .disabled(isProcessing)

                    Text("subscription.protocol_hint")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 按钮
                HStack(spacing: 12) {
                    Button("common.cancel") {
                        onCancel()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(isProcessing)

                    Spacer()

                    Button("common.add") {
                        onAdd(urlString)
                    }
                    .disabled(urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isProcessing)
                }
            }
            .padding(24)
            .frame(width: 400)
            .opacity(isProcessing ? 0.5 : 1.0)
            .allowsHitTesting(!isProcessing)

            // Loading 遮罩
            if isProcessing {
                VStack(spacing: 16) {
                    ProgressView()
                        .scaleEffect(1.5)
                        .frame(width: 40, height: 40)

                    VStack(spacing: 4) {
                        Text("subscription.adding")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Text("subscription.downloading")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                .padding(24)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.background)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                )
            }
        }
        .frame(width: 400)
    }
}

// MARK: - 快捷键行视图

struct ShortcutRow: View {
    let key: String
    let description: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Text(key)
                .font(.system(.caption, design: .monospaced))
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.horizontal, 6)
                .padding(.vertical, 4)
                .background(Color.secondary.opacity(0.15))
                .cornerRadius(4)

            Text(description)
                .font(.caption)
                .foregroundColor(.secondary)

            Spacer()
        }
    }
}

// MARK: - 手势行视图

struct GestureRow: View {
    let gesture: LocalizedStringKey
    let description: LocalizedStringKey

    var body: some View {
        HStack(spacing: 12) {
            Text(gesture)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            Text("common.arrow")
                .font(.caption)
                .foregroundColor(.secondary)

            Text(description)
                .font(.caption)
                .foregroundColor(.blue)

            Spacer()
        }
    }
}

// MARK: - 外观设置

struct AppearanceSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject private var themeManager = ThemeManager.shared
    @ObservedObject private var localizationManager = LocalizationManager.shared
    @State private var localSettings: UserSettings
    @State private var isSystemDarkMode: Bool = NSApp.effectiveAppearance.name == .darkAqua
    @State private var selectedInterfaceLocale: SupportedLocale?

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self._localSettings = State(initialValue: settingsManager.currentSettings)
        self._selectedInterfaceLocale = State(initialValue: LocalizationManager.shared.context.interfaceLocale)
    }

    var body: some View {
        Form {
            // 语言设置
            section("settings.language.section") {
                Picker("settings.language.interface", selection: $selectedInterfaceLocale) {
                    // 自动选项（nil 值）
                    Text("settings.language.auto").tag(nil as SupportedLocale?)

                    Divider()

                    // 手动选择的语言
                    ForEach(SupportedLocale.allCases, id: \.self) { locale in
                        Text(locale.displayName).tag(locale as SupportedLocale?)
                    }
                }
                .onChange(of: selectedInterfaceLocale) { newValue in
                    let newContext = LocalizationContext(
                        interfaceLocale: newValue,
                        calendarLocale: localizationManager.context.calendarLocale
                    )
                    localizationManager.updateContext(newContext)

                    // 重启应用以应用语言更改
                    AppRestarter.restartUsingWorkspace()
                }

                // 显示当前实际使用的语言（仅在自动模式下）
                if selectedInterfaceLocale == nil {
                    HStack {
                        Text("settings.language.current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(localizationManager.context.effectiveInterfaceLocale.displayName)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text("settings.language.description")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            section("settings.appearance.panel_size") {
                Picker("settings.appearance.size_level", selection: $localSettings.calendarSize) {
                    ForEach(CalendarSize.allCases, id: \.self) { size in
                        HStack {
                            Text(size.displayName)
                            Spacer()
                            Text(size.shortDescription)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .tag(size)
                    }
                }
                .onChange(of: localSettings.calendarSize) { newValue in
                    var updated = settingsManager.currentSettings
                    updated.calendarSize = newValue
                    updated.lastUpdated = Date()
                    settingsManager.saveSettings(updated)
                }

                // 尺寸预览说明
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("settings.appearance.current_size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(localSettings.calendarSize.sizeDescription)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Text(String(format: NSLocalizedString("settings.appearance.cell_size", comment: ""), Int(localSettings.calendarSize.cellSize), Int(localSettings.calendarSize.cellSize)))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 不透明度设置
            section("settings.appearance.opacity") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("settings.appearance.opacity_label")
                            .font(.body)
                        Spacer()
                        Text("\(Int(localSettings.calendarOpacity * 100))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .frame(width: 40, alignment: .trailing)
                    }

                    Slider(
                        value: Binding(
                            get: { localSettings.calendarOpacity },
                            set: { newValue in
                                localSettings.calendarOpacity = newValue
                                // 保存设置
                                var updated = settingsManager.currentSettings
                                updated.calendarOpacity = newValue
                                updated.lastUpdated = Date()
                                settingsManager.saveSettings(updated)
                                // 触发预览
                                NotificationCenter.default.post(name: .themePreviewRequested, object: nil)
                            }
                        ),
                        in: 0.0...1.0,
                        step: 0.05
                    )

                    HStack {
                        Text("settings.appearance.more_transparent")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("settings.appearance.more_opaque")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // 主题选择（统一控制）
            section("settings.appearance.theme") {
                VStack(alignment: .leading, spacing: 12) {
                    // 主题模式选择和重置按钮
                    HStack(spacing: 8) {
                        ForEach(ThemeMode.allCases, id: \.self) { mode in
                            ThemeModeButton(
                                mode: mode,
                                isSelected: localSettings.themeMode == mode,
                                action: {
                                    localSettings.themeMode = mode
                                    themeManager.setThemeMode(mode)
                                }
                            )
                        }
                    }

                    // 模式描述和重置按钮
                    HStack {
                        Text(localSettings.themeMode.description)
                            .font(.caption)
                            .foregroundColor(.secondary)

                        Spacer()

                        Button(action: resetToDefault) {
                            Label("settings.appearance.reset", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        .help(NSLocalizedString("settings.reset_theme", comment: ""))
                    }

                    // 根据模式显示对应的主题选择
                    if localSettings.themeMode == .light {
                        // 浅色模式：仅显示浅色主题
                        ThemeSelectionGrid(
                            themes: themeManager.lightThemes,
                            selectedThemeId: themeManager.currentLightTheme.id,
                            onThemeSelect: { theme in
                                handleThemeSelection(theme)
                            }
                        )
                    } else if localSettings.themeMode == .dark {
                        // 深色模式：仅显示深色主题
                        ThemeSelectionGrid(
                            themes: themeManager.darkThemes,
                            selectedThemeId: themeManager.currentDarkTheme.id,
                            onThemeSelect: { theme in
                                handleThemeSelection(theme)
                            }
                        )
                    } else {
                        // 自动模式：根据当前系统外观显示对应主题
                        if isSystemDarkMode {
                            ThemeSelectionGrid(
                                themes: themeManager.darkThemes,
                                selectedThemeId: themeManager.currentDarkTheme.id,
                                onThemeSelect: { theme in
                                    handleThemeSelection(theme)
                                }
                            )
                        } else {
                            ThemeSelectionGrid(
                                themes: themeManager.lightThemes,
                                selectedThemeId: themeManager.currentLightTheme.id,
                                onThemeSelect: { theme in
                                    handleThemeSelection(theme)
                                }
                            )
                        }

                        // 自动模式提示
                        Text("settings.theme_auto_switch")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
            }

            section("settings.shortcuts.section") {
                VStack(alignment: .leading, spacing: 8) {
                    // 日期切换（箭头键）
                    Group {
                        Text("settings.shortcuts.arrow_keys")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "←", description: "settings.shortcuts.prev_month")
                                ShortcutRow(key: "↑", description: "settings.shortcuts.next_year")
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "→", description: "settings.shortcuts.next_month")
                                ShortcutRow(key: "↓", description: "settings.shortcuts.prev_year")
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // WASD键切换
                    Group {
                        Text("settings.shortcuts.wasd_keys")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "A", description: "settings.shortcuts.prev_month")
                                ShortcutRow(key: "W", description: "settings.shortcuts.next_year")
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "D", description: "settings.shortcuts.next_month")
                                ShortcutRow(key: "S", description: "settings.shortcuts.prev_year")
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // 缩放调整
                    Group {
                        Text("settings.shortcuts.zoom")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            ShortcutRow(key: "⌘-", description: "settings.shortcuts.zoom_out")
                            ShortcutRow(key: "⌘+", description: "settings.shortcuts.zoom_in")
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // 触摸板手势
                    Group {
                        Text("settings.shortcuts.trackpad")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            GestureRow(gesture: "settings.gestures.swipe_left", description: "settings.shortcuts.next_month")
                            GestureRow(gesture: "settings.gestures.swipe_right", description: "settings.shortcuts.prev_month")
                            GestureRow(gesture: "settings.gestures.swipe_up", description: "settings.shortcuts.next_year")
                            GestureRow(gesture: "settings.gestures.swipe_down", description: "settings.shortcuts.prev_year")
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            section("settings.notes.section") {
                Text("settings.notes.panel_size")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("settings.notes.glass_effect")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .groupedFormStyleIfAvailable()
        .onAppear {
            localSettings = settingsManager.currentSettings
            isSystemDarkMode = NSApp.effectiveAppearance.name == .darkAqua
        }
        .onChange(of: settingsManager.currentSettings) { newValue in
            localSettings = newValue
        }
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { _ in
            // 监听主题变化，更新系统外观状态
            DispatchQueue.main.async {
                isSystemDarkMode = NSApp.effectiveAppearance.name == .darkAqua
            }
        }
    }

    // 处理主题选择
    private func handleThemeSelection(_ theme: ThemeConfiguration) {
        // 根据主题类别调用不同的设置方法
        if theme.category == .light {
            themeManager.setLightTheme(theme)
        } else {
            themeManager.setDarkTheme(theme)
        }

        // 更新本地设置
        var updated = settingsManager.currentSettings
        if theme.category == .light {
            updated.lightThemeId = theme.id
        } else {
            updated.darkThemeId = theme.id
        }
        updated.lastUpdated = Date()
        settingsManager.saveSettings(updated)

        // 发送主题预览请求通知，触发日历浮窗显示
        NotificationCenter.default.post(name: .themePreviewRequested, object: nil)

        Logger.debug("Theme preview requested for '\(theme.displayName)'", category: Logger.ui)
    }

    // 重置为默认主题
    private func resetToDefault() {
        // 调用 ThemeManager 重置
        themeManager.resetToDefault()

        // 更新本地状态
        localSettings = settingsManager.currentSettings

        // 发送主题预览请求通知，触发日历浮窗显示
        NotificationCenter.default.post(name: .themePreviewRequested, object: nil)

        Logger.info("Theme reset to default (Auto mode + Classic Blue/Midnight Blue)", category: Logger.ui)
    }
}

// MARK: - 主题卡片视图（方案C：分层设计）

struct ThemeCard: View {
    let theme: ThemeConfiguration
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 6) {
            // 分层预览卡片
            ZStack {
                // 第一层：Background 背景色
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: theme.colors.background))
                    .frame(width: 130, height: 86)

                // 第二层：Surface 卡片层（内嵌，带阴影）
                VStack(spacing: 8) {
                    Spacer()

                    // 中央：Accent 今日标记
                    ZStack {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(hex: theme.colors.accent))
                            .frame(width: 80, height: 32)

                        HStack(spacing: 4) {
                            Text("calendar.today")
                                .font(.system(size: 11, weight: .medium))
                            Text("13")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }

                    // 底部：星期文字
                    HStack(spacing: 6) {
                        ForEach(["sun", "mon", "tue", "wed", "thu"], id: \.self) { dayKey in
                            Text(NSLocalizedString("weekday.\(dayKey)", comment: ""))
                                .font(.system(size: 9))
                                .foregroundColor(Color(hex: theme.colors.textSecondary))
                        }
                    }

                    Spacer()
                }
                .frame(width: 114, height: 70)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(hex: theme.colors.surface))
                        .shadow(
                            color: Color.black.opacity(isHovering ? 0.15 : 0.1),
                            radius: isHovering ? 4 : 3,
                            x: 0,
                            y: 2
                        )
                )
            }

            // 主题名称（带选中标记）
            HStack(spacing: 4) {
                Text(theme.localizedDisplayName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(Color(hex: theme.colors.accent))
                }
            }
            .frame(height: 18)  // 固定高度避免跳动
        }
        .frame(width: 130, height: 110)
        .padding(6)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(
                    isSelected ? Color.accentColor : (isHovering ? Color.gray.opacity(0.3) : Color.clear),
                    lineWidth: isSelected ? 2 : (isHovering ? 1 : 0)
                )
        )
        .scaleEffect(isSelected || isHovering ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
        .onTapGesture {
            onTap()
        }
    }
}

// MARK: - 主题模式按钮

struct ThemeModeButton: View {
    let mode: ThemeMode
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: mode.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)

                Text(mode.displayName)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isSelected ? Color.accentColor : Color.secondary.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
}

// MARK: - 主题选择网格

struct ThemeSelectionGrid: View {
    let themes: [ThemeConfiguration]
    let selectedThemeId: String
    let onThemeSelect: (ThemeConfiguration) -> Void

    var body: some View {
        // 主题网格（3列布局，更紧凑的间距）
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(142), spacing: 12), count: 3),
            spacing: 12
        ) {
            ForEach(themes, id: \.id) { theme in
                ThemeCard(
                    theme: theme,
                    isSelected: theme.id == selectedThemeId,
                    onTap: { onThemeSelect(theme) }
                )
            }
        }
    }
}

private struct GroupedFormStyleIfAvailable: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content.formStyle(.grouped)
        } else {
            content
        }
    }
}

@ViewBuilder
private func section(_ title: LocalizedStringKey, @ViewBuilder content: () -> some View) -> some View {
    if #available(macOS 12.0, *) {
        Section(title, content: content)
    } else {
        Section(header: Text(title), content: content)
    }
}

private extension View {
    func groupedFormStyleIfAvailable() -> some View {
        modifier(GroupedFormStyleIfAvailable())
    }
}

#Preview {
    SettingsView()
}
