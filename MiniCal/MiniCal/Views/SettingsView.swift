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

            // 主题设置
            ThemeSettingsView(settingsManager: settingsManager)
                .tabItem {
                    Label("主题", systemImage: "paintbrush")
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
                Picker("格式", selection: $settingsManager.currentSettings.menuBarFormat) {
                    ForEach(MenuBarFormat.allCases, id: \.self) { format in
                        Text(format.displayName).tag(format)
                    }
                }
                .onChange(of: settingsManager.currentSettings.menuBarFormat) { newValue in
                    // 切换到自定义格式时自动进入编辑态
                    if newValue == .custom {
                        isEditingCustomFormat = true
                    }
                }

                // 自定义格式编辑组件
                if settingsManager.currentSettings.menuBarFormat == .custom {
                    CustomFormatEditor(
                        customFormat: $settingsManager.currentSettings.customFormat,
                        isEditing: $isEditingCustomFormat
                    )
                }

                let isCustomFormat = settingsManager.currentSettings.menuBarFormat == .custom

                Toggle("24小时制", isOn: $settingsManager.currentSettings.show24Hour)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)

                Toggle("显示星期", isOn: $settingsManager.currentSettings.showWeekday)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)

                Toggle("显示秒", isOn: $settingsManager.currentSettings.showSeconds)
                    .disabled(isCustomFormat)
                    .foregroundColor(isCustomFormat ? .secondary : .primary)
            }

            Section("鼠标悬浮展示日历") {
                Toggle("启用悬浮展示", isOn: $settingsManager.currentSettings.hoverToShowEnabled)

                if settingsManager.currentSettings.hoverToShowEnabled {
                    VStack(alignment: .leading, spacing: 4) {
                        Slider(
                            value: $settingsManager.currentSettings.hoverDelay,
                            in: 0.1...2.0,
                            step: 0.1
                        ) {
                            Text("延迟时间")
                        }
                        Text("延迟: \(String(format: "%.1f", settingsManager.currentSettings.hoverDelay))秒")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: settingsManager.currentSettings) { newValue in
            settingsManager.saveSettings(newValue)
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
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if isEditing {
                // 输入态
                TextField("自定义格式", text: $customFormat)
                    .textFieldStyle(.roundedBorder)
                    .focused($isFocused)
                    .onSubmit {
                        // 回车键切换到展示态
                        isEditing = false
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

    var body: some View {
        Form {
            Section("副日历") {
                Picker("副日历类型", selection: $settingsManager.currentSettings.secondaryCalendarType) {
                    Text("无").tag(nil as CalendarType?)
                    ForEach(CalendarType.allCases.filter { $0 != .gregorian }, id: \.self) { type in
                        Text(type.displayName).tag(type as CalendarType?)
                    }
                }
            }

            Section("说明") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("副日历将显示在每个日期下方")
                        .font(.caption)
                    Text("支持: 农历、伊斯兰历、希伯来历、波斯历、和历、佛历")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .onChange(of: settingsManager.currentSettings) { newValue in
            settingsManager.saveSettings(newValue)
        }
    }
}

// MARK: - 主题设置

struct ThemeSettingsView: View {
    @ObservedObject var settingsManager: SettingsManager
    @ObservedObject private var themeManager = ThemeManager.shared

    var body: some View {
        Form {
            Section("主题选择") {
                // 动态加载所有可用主题
                Picker("主题", selection: $settingsManager.currentSettings.themeId) {
                    ForEach(themeManager.availableThemes, id: \.id) { theme in
                        Text(theme.name).tag(theme.id)
                    }
                }
                .onChange(of: settingsManager.currentSettings.themeId) { newThemeId in
                    // 当主题ID变化时，应用新主题
                    themeManager.applyTheme(withId: newThemeId)
                }
            }

            Section("主题预览") {
                // 显示所有可用主题的预览卡片
                ForEach(themeManager.availableThemes, id: \.id) { theme in
                    ThemePreviewCard(
                        theme: theme,
                        isSelected: settingsManager.currentSettings.themeId == theme.id
                    )
                    .onTapGesture {
                        settingsManager.currentSettings.themeId = theme.id
                    }
                }
            }

            Section("说明") {
                Text("日历弹窗使用 macOS Glass 效果")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text("自动适配系统外观")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .formStyle(.grouped)
        .onChange(of: settingsManager.currentSettings) { newValue in
            settingsManager.saveSettings(newValue)
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
