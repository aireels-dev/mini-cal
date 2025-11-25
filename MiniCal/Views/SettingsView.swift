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
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTab = 0

    init(calendarViewModel: CalendarViewModel? = nil) {
        self.calendarViewModel = calendarViewModel ?? CalendarViewModel()
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            // 菜单栏设置
            MenuBarSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("菜单栏", systemImage: "menubar.rectangle")
                }
                .tag(0)

            // 日历设置
            CalendarSettingsView(settingsManager: settingsManager, calendarViewModel: calendarViewModel)
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }
                .tag(1)

            // 外观设置
            AppearanceSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("外观", systemImage: "paintbrush")
                }
                .tag(2)
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
            self.selectedTab = 1  // 切换到日历tab
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
            Section("应用设置") {
                // 全局快捷键
                Toggle("启用全局快捷键", isOn: $localSettings.globalHotkeyEnabled)
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
                Toggle("开机自动启动", isOn: $localSettings.launchAtLogin)
                    .onChange(of: localSettings.launchAtLogin) { newValue in
                        var updated = settingsManager.currentSettings
                        updated.launchAtLogin = newValue
                        updated.lastUpdated = Date()
                        settingsManager.saveSettings(updated)
                        // 应用设置
                        LaunchAtLoginManager.shared.setLaunchAtLogin(newValue)
                    }
            }

            // 菜单栏显示
            Section("菜单栏显示") {
                // 实时预览
                VStack(alignment: .leading, spacing: 4) {
                    Text("实时预览")
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
                Picker("格式", selection: $localSettings.menuBarFormat) {
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

                Toggle("24小时制", isOn: $localSettings.show24Hour)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
                    .onChange(of: localSettings.show24Hour) { newValue in
                        settingsManager.updateShow24Hour(newValue)
                    }

                Toggle("显示星期", isOn: $localSettings.showWeekday)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
                    .onChange(of: localSettings.showWeekday) { newValue in
                        settingsManager.updateShowWeekday(newValue)
                    }

                Toggle("显示秒", isOn: $localSettings.showSeconds)
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
            Section("日历交互") {
                Toggle("启用悬浮展示", isOn: $localSettings.hoverToShowEnabled)
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
                            Text("延迟时间")
                        }
                        .onChange(of: localSettings.hoverDelay) { newValue in
                            settingsManager.updateHoverSettings(enabled: localSettings.hoverToShowEnabled, delay: newValue)
                        }
                        Text("延迟: \(String(format: "%.1f", localSettings.hoverDelay))秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
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
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                // 输入态
                TextField("自定义格式", text: $customFormat)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        // 回车键切换到展示态并保存
                        isEditing = false
                        onFormatChange(customFormat)
                    }
                    .onAppear {
                        isFocused = true
                    }

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
                    .help("编辑格式")
                }
            }
        }
    }
}

// MARK: - 格式说明视图

struct FormatGuideView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("支持的格式符号：")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)

            FormatExampleView(symbol: "yyyy", description: "四位年份", example: "2025")
            FormatExampleView(symbol: "yy", description: "两位年份", example: "25")
            FormatExampleView(symbol: "M", description: "月份", example: "1, 12")
            FormatExampleView(symbol: "MM", description: "月份（补零）", example: "01, 12")
            FormatExampleView(symbol: "d", description: "日期", example: "1, 31")
            FormatExampleView(symbol: "dd", description: "日期（补零）", example: "01, 31")
            FormatExampleView(symbol: "E", description: "星期", example: "周一")
            FormatExampleView(symbol: "w", description: "第几周", example: "1-53")
            FormatExampleView(symbol: "W", description: "月中第几周", example: "1-5")
            FormatExampleView(symbol: "HH", description: "24小时", example: "00-23")
            FormatExampleView(symbol: "h", description: "12小时", example: "1-12")
            FormatExampleView(symbol: "mm", description: "分钟", example: "00-59")
            FormatExampleView(symbol: "ss", description: "秒", example: "00-59")
            FormatExampleView(symbol: "a", description: "上午/下午", example: "AM, PM")

            Text("示例：M月d日 HH:mm → 1月15日 14:30")
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
    let description: String
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

            Text("→")
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
    @StateObject private var themeManager = ThemeManager.shared
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
        Form {
            // Section 1: 本地历法
            Section("本地历法") {
                Picker("历法类型", selection: $localSettings.secondaryCalendarType) {
                    Text("不显示").tag(nil as CalendarType?)
                    ForEach(CalendarType.allCases.filter { $0 != .gregorian }, id: \.self) { type in
                        Text(type.displayName).tag(type as CalendarType?)
                    }
                }
                .onChange(of: localSettings.secondaryCalendarType) { newValue in
                    settingsManager.updateSecondaryCalendar(newValue)
                }

                Text("在公历日期下方显示本地历法")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            // Section 2: 系统同步
            Section {
                systemCalendarSyncContent
            } header: {
                HStack {
                    Text("系统同步")
                    Spacer()
                    permissionStatusBadge
                }
            }

            // Section 3: 外部订阅（包含按钮）
            Section("外部订阅") {
                externalSubscriptionContent
            }

            // Section 4: 本地管理
            Section("本地管理") {
                localEventGroupContent
            }
        }
        .formStyle(.grouped)
        .onAppear {
            localSettings = settingsManager.currentSettings
            subscriptionViewModel.loadSubscriptions()
            loadSystemCalendarEventCounts()
            loadLocalGroupEventCounts()
        }
        .onChange(of: settingsManager.currentSettings) { newValue in
            localSettings = newValue
        }
        .onChange(of: calendarViewModel.events) { oldValue, newValue in
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
        .alert("添加订阅失败", isPresented: $showingAddError) {
            Button("确定", role: .cancel) {
                showingAddError = false
            }
        } message: {
            Text(addErrorMessage)
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

                    Text("需要访问日历权限")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.primary)
                }

                Text("授权后可同步 iCloud 和本地日历的事件")
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
                        Text(permissionManager.authorizationStatus == .denied ? "打开系统设置" : "请求权限")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(permissionManager.authorizationStatus == .denied ? Color.orange : Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())

                if permissionManager.authorizationStatus == .denied {
                    Text("提示:点击按钮将打开系统设置,在「隐私与安全性」>「日历」中授权")
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
                        isEnabled: .constant(true),
                        themeColors: themeManager.effectiveColors,
                        permissionManager: permissionManager,
                        eventCount: systemCalendarEventCounts[calendar.calendarIdentifier] ?? 0,
                        onToggle: {
                            // TODO: 实现切换系统日历启用状态
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
                    Text("暂无可用的系统日历")
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
                        Text("暂无外部订阅")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.secondary)

                        Text("点击下方「添加订阅」按钮开始")
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
                        themeColors: themeManager.effectiveColors,
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
                        Text("添加订阅")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("添加新的外部日历订阅")

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
                            Text("刷新全部")
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
                    .help("刷新所有订阅的日历数据")
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
                    themeColors: themeManager.effectiveColors,
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
                        Text("添加类别")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.blue)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .help("添加新的本地事件类别")

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
        let defaultGroupId = localGroupService.defaultGroupId

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
            return "已授权"
        case .denied:
            return "已拒绝"
        case .restricted:
            return "受限"
        case .notDetermined:
            return "未询问"
        @unknown default:
            return "未知"
        }
    }

    private var statusColor: Color {
        switch permissionManager.authorizationStatus {
        case .authorized:
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
    @FocusState private var isTitleFieldFocused: Bool

    var body: some View {
        VStack(spacing: 20) {
            // 标题
            Text("添加本地类别")
                .font(.title2)
                .fontWeight(.semibold)

            // 类别名称输入
            VStack(alignment: .leading, spacing: 8) {
                Text("类别名称")
                    .font(.headline)

                TextField("例如：工作、个人、提醒", text: $groupTitle)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .focused($isTitleFieldFocused)
                    .onSubmit {
                        // 回车键提交
                        if !groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                            onAdd(groupTitle, selectedColor)
                        }
                    }
            }

            // 颜色选择
            VStack(alignment: .leading, spacing: 8) {
                Text("颜色")
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
                Button("取消") {
                    onCancel()
                }
                .keyboardShortcut(.escape, modifiers: [])

                Spacer()

                Button("添加") {
                    onAdd(groupTitle, selectedColor)
                }
                .disabled(groupTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(width: 400)
        .onAppear {
            isTitleFieldFocused = true
        }
    }
}

// MARK: - Add Subscription Sheet View

struct AddSubscriptionSheetView: View {
    @Binding var isProcessing: Bool
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    @State private var urlString = ""
    @FocusState private var isURLFieldFocused: Bool

    var body: some View {
        ZStack {
            // 主内容
            VStack(spacing: 20) {
                // 标题
                Text("添加外部订阅")
                    .font(.title2)
                    .fontWeight(.semibold)

                // URL 输入
                VStack(alignment: .leading, spacing: 8) {
                    Text("订阅 URL")
                        .font(.headline)

                    TextField("https://calendar.example.com/calendar.ics", text: $urlString)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .focused($isURLFieldFocused)
                        .disabled(isProcessing)
                        .onSubmit {
                            // 回车键提交
                            if !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !isProcessing {
                                onAdd(urlString)
                            }
                        }

                    Text("支持 http://、https:// 和 webcal:// 协议")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                // 按钮
                HStack(spacing: 12) {
                    Button("取消") {
                        onCancel()
                    }
                    .keyboardShortcut(.escape, modifiers: [])
                    .disabled(isProcessing)

                    Spacer()

                    Button("添加") {
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
                        Text("正在添加订阅...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)

                        Text("正在验证并下载日历数据")
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
        .onAppear {
            isURLFieldFocused = true
        }
    }
}

// MARK: - 快捷键行视图

struct ShortcutRow: View {
    let key: String
    let description: String

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
    let gesture: String
    let description: String

    var body: some View {
        HStack(spacing: 12) {
            Text(gesture)
                .font(.caption)
                .foregroundColor(.primary)
                .frame(width: 80, alignment: .leading)

            Text("→")
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
    @State private var localSettings: UserSettings
    @State private var isSystemDarkMode: Bool = NSApp.effectiveAppearance.name == .darkAqua

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self._localSettings = State(initialValue: settingsManager.currentSettings)
    }

    var body: some View {
        Form {
            Section("面板大小") {
                Picker("尺寸档位", selection: $localSettings.calendarSize) {
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
                        Text("当前尺寸：")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(localSettings.calendarSize.sizeDescription)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }

                    Text("单元格大小：\(Int(localSettings.calendarSize.cellSize)) × \(Int(localSettings.calendarSize.cellSize))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // 不透明度设置
            Section("浮窗透明度") {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text("不透明度")
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
                        Text("更透明")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("更不透明")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            // 主题选择（统一控制）
            Section("主题") {
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
                            Label("重置", systemImage: "arrow.counterclockwise")
                                .font(.caption)
                        }
                        .buttonStyle(.borderless)
                        .foregroundColor(.blue)
                        .help("重置为默认主题（自动模式 + 经典蓝/午夜蓝）")
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
                        Text("💡 系统外观变化时，将自动切换到对应模式下您选择的主题")
                            .font(.caption)
                            .foregroundColor(.blue)
                            .padding(.top, 4)
                    }
                }
            }

            Section("快捷键与手势") {
                VStack(alignment: .leading, spacing: 8) {
                    // 日期切换（箭头键）
                    Group {
                        Text("箭头键切换")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "←", description: "上个月")
                                ShortcutRow(key: "↑", description: "下一年")
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "→", description: "下个月")
                                ShortcutRow(key: "↓", description: "上一年")
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // WASD键切换
                    Group {
                        Text("WASD键切换")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "A", description: "上个月")
                                ShortcutRow(key: "W", description: "下一年")
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "D", description: "下个月")
                                ShortcutRow(key: "S", description: "上一年")
                            }
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // 缩放调整
                    Group {
                        Text("缩放调整")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            ShortcutRow(key: "⌘-", description: "缩小")
                            ShortcutRow(key: "⌘+", description: "放大")
                        }
                    }

                    Divider()
                        .padding(.vertical, 2)

                    // 触摸板手势
                    Group {
                        Text("触摸板手势")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        VStack(alignment: .leading, spacing: 2) {
                            GestureRow(gesture: "左滑", description: "下个月")
                            GestureRow(gesture: "右滑", description: "上个月")
                            GestureRow(gesture: "上滑", description: "下一年")
                            GestureRow(gesture: "下滑", description: "上一年")
                        }
                    }
                }
                .padding(.vertical, 2)
            }

            Section("说明") {
                Text("调整面板大小可以获得更好的视觉体验")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("日历弹窗使用 macOS Glass 效果")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 4)
            }
        }
        .formStyle(.grouped)
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
        VStack(spacing: 8) {
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
                            Text("今日")
                                .font(.system(size: 11, weight: .medium))
                            Text("13")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                    }

                    // 底部：星期文字
                    HStack(spacing: 6) {
                        ForEach(["日", "一", "二", "三", "四"], id: \.self) { day in
                            Text(day)
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

            // 主题名称
            Text(theme.displayName)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(1)

            // 选中标记
            HStack(spacing: 4) {
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: theme.colors.accent))
                    Text("当前主题")
                        .font(.system(size: 10))
                        .foregroundColor(Color(hex: theme.colors.accent))
                }
            }
            .frame(height: 14)  // 固定高度避免跳动
        }
        .frame(width: 130, height: 120)
        .padding(8)
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
        // 主题网格（3列布局，方案C）
        LazyVGrid(
            columns: Array(repeating: GridItem(.fixed(146), spacing: 20), count: 3),
            spacing: 20
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

#Preview {
    SettingsView()
}
