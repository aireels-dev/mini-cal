//
//  SettingsView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var settingsManager = SettingsManager.shared
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        TabView {
            // 菜单栏设置
            MenuBarSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("菜单栏", systemImage: "menubar.rectangle")
                }

            // 日历设置
            CalendarSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("日历", systemImage: "calendar")
                }

            // 外观设置
            AppearanceSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("外观", systemImage: "paintbrush")
                }
        }
        .frame(width: 500, height: 400)
        .padding()
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
            // 预览区域 - 移到最上方
            Section("预览") {
                Text(previewText)
                    .font(.system(size: 13))
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }

            Section("显示格式") {
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

            Section("鼠标悬浮展示日历") {
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
    @State private var localSettings: UserSettings

    init(settingsManager: SettingsManager) {
        self.settingsManager = settingsManager
        self._localSettings = State(initialValue: settingsManager.currentSettings)
    }

    var body: some View {
        Form {
            Section("本地日历") {
                Picker("历法类型", selection: $localSettings.secondaryCalendarType) {
                    Text("不显示").tag(nil as CalendarType?)
                    ForEach(CalendarType.allCases.filter { $0 != .gregorian }, id: \.self) { type in
                        Text(type.displayName).tag(type as CalendarType?)
                    }
                }
                .onChange(of: localSettings.secondaryCalendarType) { newValue in
                    settingsManager.updateSecondaryCalendar(newValue)
                }
            }

            Section("说明") {
                Text("在公历日期下方显示本地历法")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Text("中国用户推荐选择「农历」")
                    .font(.caption)
                    .foregroundColor(.blue)
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

            Section("主题选择") {
                // 动态加载所有可用主题
                Picker("主题", selection: $localSettings.themeId) {
                    ForEach(themeManager.availableThemes, id: \.id) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .onChange(of: localSettings.themeId) { newThemeId in
                    // 当主题ID变化时，应用新主题并保存
                    themeManager.applyTheme(withId: newThemeId)
                    settingsManager.updateTheme(newThemeId)
                }
            }

            Section("主题预览") {
                // 显示所有可用主题的预览卡片
                ForEach(themeManager.availableThemes, id: \.id) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: localSettings.themeId == theme.id
                    )
                    .onTapGesture {
                        localSettings.themeId = theme.id
                        themeManager.applyTheme(withId: theme.id)
                        settingsManager.updateTheme(theme.id)
                    }
                }
            }

            Section("快捷键与手势") {
                VStack(alignment: .leading, spacing: 8) {
                    // 日期切换（键盘快捷键）
                    Group {
                        Text("日期切换")
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)

                        HStack(spacing: 20) {
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "←", description: "上个月")
                                ShortcutRow(key: "↑", description: "上一年")
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                ShortcutRow(key: "→", description: "下个月")
                                ShortcutRow(key: "↓", description: "下一年")
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

                        HStack(spacing: 20) {
                            GestureRow(gesture: "左右滑动", description: "月份切换")
                            GestureRow(gesture: "上下滑动", description: "年份切换")
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

                Text("自动适配系统外观")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
}

// MARK: - 主题预览卡片

struct ThemePreviewCard: View {
    let theme: Theme
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            // 主题名称
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.name)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.primary)

                Text(theme.id)
                    .font(.system(size: 11))
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 颜色预览块
            HStack(spacing: 6) {
                ColorPreviewDot(color: theme.colors.backgroundColor)
                ColorPreviewDot(color: theme.colors.textColor)
                ColorPreviewDot(color: theme.colors.todayHighlightColor)
                ColorPreviewDot(color: theme.colors.weekendTextColor)
            }

            // 选中标记
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 16))
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected ? Color.blue.opacity(0.1) : Color.secondary.opacity(0.05))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
    }
}

// MARK: - 颜色预览圆点

struct ColorPreviewDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 16, height: 16)
            .overlay(
                Circle()
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    SettingsView()
}
