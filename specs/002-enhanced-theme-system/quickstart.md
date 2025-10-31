# Enhanced Theme System - 快速开始指南

**版本**: 1.0
**日期**: 2025-10-30
**特性**: 002-Enhanced Theme System

## 概述

本指南将帮助开发者快速集成和使用增强主题系统。该系统提供了类似 Chrome 浏览器的丰富主题选择，支持独立的深色/浅色模式主题配置，以及实时预览功能。

## 快速集成

### 1. 基本设置

在你的应用中添加主题系统支持：

```swift
import SwiftUI

@main
struct MiniCalApp: App {
    @StateObject private var themeManager = EnhancedThemeManager.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .environment(\.themeConfiguration, themeManager.effectiveTheme)
        }
    }
}
```

### 2. 主题感知视图

创建响应主题变化的视图：

```swift
struct CalendarView: View {
    @EnvironmentObject private var themeManager: EnhancedThemeManager

    var body: some View {
        VStack(spacing: 16) {
            // 日期头部
            headerView

            // 日历网格
            calendarGrid

            // 底部操作栏
            footerView
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.colors.background.main))
        .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))
        .animation(.easeInOut(duration: 0.3), value: themeManager.effectiveTheme.id)
    }

    private var headerView: some View {
        HStack {
            Text("2025年10月")
                .font(.title2)
                .fontWeight(.semibold)

            Spacer()

            Button(action: {}) {
                Image(systemName: "calendar")
                    .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.accent.main))
            }
        }
        .padding(.horizontal)
    }

    private var calendarGrid: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 8) {
            ForEach(1...31, id: \.self) { day in
                Text("\(day)")
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color(hex: themeManager.effectiveTheme.colors.surface.main))
                    )
                    .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))
            }
        }
        .padding(.horizontal)
    }

    private var footerView: some View {
        HStack {
            Button("今天") {
                // 今天的操作
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: themeManager.effectiveTheme.colors.accent.main))

            Spacer()

            Button("设置") {
                // 打开设置
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: themeManager.effectiveTheme.colors.accent.main))
        }
        .padding(.horizontal)
    }
}
```

### 3. 主题设置界面

创建主题选择界面：

```swift
struct ThemeSettingsView: View {
    @EnvironmentObject private var themeManager: EnhancedThemeManager
    @State private var selectedMode: ThemeMode = .auto

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // 标题
            Text("主题设置")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding(.bottom)

            // 模式选择
            modeSelectionSection

            // 主题选择
            themeSelectionSection

            Spacer()
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.colors.background.main))
        .onAppear {
            selectedMode = themeManager.currentMode
        }
    }

    private var modeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主题模式")
                .font(.headline)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))

            Picker("模式", selection: $selectedMode) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    Label(mode.displayName, systemImage: mode.systemImageName)
                        .tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: selectedMode) { newMode in
                themeManager.switchToMode(newMode)
            }
        }
    }

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主题选择")
                .font(.headline)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))

            switch selectedMode {
            case .light:
                ThemeSelectionView(category: .light)
            case .dark:
                ThemeSelectionView(category: .dark)
            case .auto:
                VStack(spacing: 20) {
                    ThemeSelectionView(category: .light, title: "浅色模式主题")
                    Divider()
                    ThemeSelectionView(category: .dark, title: "深色模式主题")
                }
            }
        }
    }
}
```

### 4. 主题选择组件

创建主题选择网格：

```swift
struct ThemeSelectionView: View {
    let category: ThemeCategory
    let title: String?

    @EnvironmentObject private var themeManager: EnhancedThemeManager

    private var themes: [ThemeConfiguration] {
        themeManager.themes(for: category)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let title = title {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                ForEach(themes) { theme in
                    ThemeCard(theme: theme, isSelected: isSelected(theme))
                        .onTapGesture {
                            themeManager.setTheme(theme, for: category)
                        }
                }
            }
        }
    }

    private func isSelected(_ theme: ThemeConfiguration) -> Bool {
        switch category {
        case .light:
            return theme.id == themeManager.lightTheme.id
        case .dark:
            return theme.id == themeManager.darkTheme.id
        }
    }
}

struct ThemeCard: View {
    let theme: ThemeConfiguration
    let isSelected: Bool

    @EnvironmentObject private var themeManager: EnhancedThemeManager
    @State private var isHovering = false

    var body: some View {
        VStack(spacing: 8) {
            // 主题预览颜色
            HStack(spacing: 4) {
                ForEach(theme.previewColors.prefix(4), id: \.self) { color in
                    Rectangle()
                        .fill(Color(hex: color))
                        .frame(width: 20, height: 20)
                        .cornerRadius(4)
                }
            }

            // 主题名称
            Text(theme.computedDisplayName)
                .font(.caption)
                .foregroundColor(.primary)
                .lineLimit(1)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(hex: themeManager.effectiveTheme.colors.surface.main))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            isSelected ? Color(hex: themeManager.effectiveTheme.colors.accent.main) : Color.clear,
                            lineWidth: isSelected ? 2 : 0
                        )
                )
        )
        .scaleEffect(isHovering ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovering)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
```

## 主题预览功能

### 1. 实时预览

实现主题实时预览：

```swift
struct ThemePreviewManager: ViewModifier {
    let theme: ThemeConfiguration
    let isPreview: Bool

    func body(content: Content) -> some View {
        content
            .background(
                Group {
                    if isPreview {
                        Color(hex: theme.colors.background.main)
                    } else {
                        Color.clear
                    }
                }
            )
            .foregroundColor(
                Group {
                    if isPreview {
                        Color(hex: theme.colors.text.main)
                    } else {
                        Color.primary
                    }
                }
            )
            .animation(.easeInOut(duration: 0.3), value: isPreview)
    }
}

extension View {
    func themePreview(_ theme: ThemeConfiguration?, isPreview: Bool) -> some View {
        if let theme = theme {
            modifier(ThemePreviewManager(theme: theme, isPreview: isPreview))
        } else {
            self
        }
    }
}
```

### 2. 预览控制

创建主题预览控制组件：

```swift
struct ThemePreviewControl: View {
    let theme: ThemeConfiguration
    @EnvironmentObject private var themeManager: EnhancedThemeManager
    @State private var isPreviewing = false

    var body: some View {
        HStack {
            // 主题信息
            VStack(alignment: .leading, spacing: 4) {
                Text(theme.computedDisplayName)
                    .font(.headline)

                Text(theme.description ?? "无描述")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // 预览按钮
            Button(isPreviewing ? "停止预览" : "预览主题") {
                if isPreviewing {
                    themeManager.stopPreview()
                    isPreviewing = false
                } else {
                    themeManager.startPreview(theme: theme)
                    isPreviewing = true

                    // 3秒后自动停止预览
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                        if themeManager.previewTheme?.id == theme.id {
                            themeManager.stopPreview()
                            isPreviewing = false
                        }
                    }
                }
            }
            .buttonStyle(.bordered)
            .tint(Color(hex: themeManager.effectiveTheme.colors.accent.main))

            // 应用按钮
            Button("应用主题") {
                themeManager.setTheme(theme, for: theme.category)
                themeManager.stopPreview()
                isPreviewing = false
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: themeManager.effectiveTheme.colors.accent.main))
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.colors.surface.main))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
}
```

## 菜单栏集成

### 1. 菜单栏控制器

扩展菜单栏控制器以支持主题：

```swift
extension MenuBarController {
    private func observeThemeChanges() {
        // 监听主题变化
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.updateMenuBarAppearance()
                }
            }
            .store(in: &cancellables)

        // 监听有效主题变化（自动模式下系统外观变化）
        NotificationCenter.default.publisher(for: .effectiveThemeDidChange)
            .sink { [weak self] notification in
                DispatchQueue.main.async {
                    self?.updateMenuBarAppearance()
                }
            }
            .store(in: &cancellables)
    }

    private func updateMenuBarAppearance() {
        guard let button = statusItem.button else { return }

        let theme = themeManager.effectiveTheme

        // 更新按钮文字颜色
        button.contentTintColor = NSColor.from(hex: theme.colors.primary.main)

        // 如果有弹窗，也更新其外观
        if popover.isShown {
            updatePopoverAppearance()
        }

        // 更新设置窗口外观
        if let settingsWindow = settingsWindow {
            settingsWindow.appearance = theme.category == .dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)
        }

        print("🎨 Menu bar appearance updated to theme: \(theme.computedDisplayName)")
    }

    private func updatePopoverAppearance() {
        let theme = themeManager.effectiveTheme

        // 设置弹窗背景色
        popover.appearance = theme.category == .dark ? NSAppearance(named: .darkAqua) : NSAppearance(named: .aqua)

        // 更新内容视图的主题环境
        if let hostingController = popover.contentViewController as? NSHostingController<AnyView> {
            let currentView = hostingController.rootView
            hostingController.rootView = AnyView(currentView.environment(\.themeConfiguration, theme))
        }
    }
}
```

### 2. 主题感知的弹窗内容

创建支持主题的弹窗内容：

```swift
struct ThemedPopoverContent: View {
    @EnvironmentObject private var themeManager: EnhancedThemeManager
    @Environment(\.themeConfiguration) private var theme

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView

            Divider()
                .background(Color(hex: theme.colors.border.main))

            // 日历内容
            calendarView

            Divider()
                .background(Color(hex: theme.colors.border.main))

            // 底部工具栏
            toolbarView
        }
        .frame(width: 320, height: 400)
        .background(Color(hex: theme.colors.background.main))
    }

    private var headerView: some View {
        HStack {
            Text("MiniCal")
                .font(.headline)
                .foregroundColor(Color(hex: theme.colors.text.main))

            Spacer()

            Button(action: {}) {
                Image(systemName: "gear")
                    .foregroundColor(Color(hex: theme.colors.textSecondary.main))
            }
            .buttonStyle(.plain)
        }
        .padding()
    }

    private var calendarView: some View {
        // 日历视图内容
        Text("日历内容")
            .foregroundColor(Color(hex: theme.colors.text.main))
    }

    private var toolbarView: some View {
        HStack {
            Button("今天") {}
                .buttonStyle(.bordered)
                .tint(Color(hex: theme.colors.accent.main))

            Spacer()

            Button("设置") {}
                .buttonStyle(.borderedProminent)
                .tint(Color(hex: theme.colors.accent.main))
        }
        .padding()
    }
}
```

## 自定义主题创建

### 1. 主题编辑器

创建主题编辑界面：

```swift
struct ThemeEditorView: View {
    @State private var theme: ThemeConfiguration
    @State private var selectedColorCategory: ColorCategory = .primary
    @EnvironmentObject private var themeManager: EnhancedThemeManager

    enum ColorCategory: String, CaseIterable {
        case primary = "主要颜色"
        case secondary = "次要颜色"
        case background = "背景颜色"
        case surface = "表面颜色"
        case text = "文本颜色"
        case accent = "强调色"
    }

    init(theme: ThemeConfiguration = ThemeConfiguration.sampleTheme(category: .light)) {
        _theme = State(initialValue: theme)
    }

    var body: some View {
        NavigationView {
            VStack {
                // 主题基本信息
                basicInfoSection

                Divider()

                // 颜色编辑
                colorEditingSection

                Spacer()

                // 保存按钮
                saveButton
            }
            .padding()
            .background(Color(hex: themeManager.effectiveTheme.colors.background.main))
            .navigationTitle("主题编辑器")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private var basicInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("基本信息")
                .font(.headline)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))

            VStack(spacing: 8) {
                TextField("主题名称", text: $theme.name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                TextField("描述", text: Binding(
                    get: { theme.description ?? "" },
                    set: { theme.description = $0.isEmpty ? nil : $0 }
                ))
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Picker("主题分类", selection: Binding(
                    get: { theme.category },
                    set: { theme = ThemeConfiguration(
                        id: theme.id,
                        name: theme.name,
                        displayName: theme.displayName,
                        category: $0,
                        author: theme.author,
                        version: theme.version,
                        description: theme.description,
                        colors: theme.colors,
                        metadata: theme.metadata,
                        isBuiltIn: theme.isBuiltIn,
                        isEnabled: theme.isEnabled,
                        previewColors: theme.previewColors
                    )}
                )) {
                    ForEach(ThemeCategory.allCases, id: \.self) { category in
                        Text(category.displayName).tag(category)
                    }
                }
                .pickerStyle(.segmented)
            }
        }
    }

    private var colorEditingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("颜色配置")
                .font(.headline)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.colors.text.main))

            // 颜色类别选择
            Picker("颜色类别", selection: $selectedColorCategory) {
                ForEach(ColorCategory.allCases, id: \.self) { category in
                    Text(category.rawValue).tag(category)
                }
            }
            .pickerStyle(.segmented)

            // 颜色编辑器
            colorEditorForCategory(selectedColorCategory)
        }
    }

    private func colorEditorForCategory(_ category: ColorCategory) -> some View {
        VStack(spacing: 12) {
            switch category {
            case .primary:
                ColorPickerView(
                    title: "主要颜色",
                    color: Binding(
                        get: { theme.colors.primary.main },
                        set: { theme.colors.primary = ColorSet(main: $0) }
                    )
                )
            case .secondary:
                ColorPickerView(
                    title: "次要颜色",
                    color: Binding(
                        get: { theme.colors.secondary.main },
                        set: { theme.colors.secondary = ColorSet(main: $0) }
                    )
                )
            case .background:
                ColorPickerView(
                    title: "背景颜色",
                    color: Binding(
                        get: { theme.colors.background.main },
                        set: { theme.colors.background = ColorSet(main: $0) }
                    )
                )
            case .surface:
                ColorPickerView(
                    title: "表面颜色",
                    color: Binding(
                        get: { theme.colors.surface.main },
                        set: { theme.colors.surface = ColorSet(main: $0) }
                    )
                )
            case .text:
                ColorPickerView(
                    title: "文本颜色",
                    color: Binding(
                        get: { theme.colors.text.main },
                        set: { theme.colors.text = ColorSet(main: $0) }
                    )
                )
            case .accent:
                ColorPickerView(
                    title: "强调色",
                    color: Binding(
                        get: { theme.colors.accent.main },
                        set: { theme.colors.accent = ColorSet(main: $0) }
                    )
                )
            }
        }
    }

    private var saveButton: some View {
        Button("保存主题") {
            saveTheme()
        }
        .buttonStyle(.borderedProminent)
        .tint(Color(hex: themeManager.effectiveTheme.colors.accent.main))
    }

    private func saveTheme() {
        // 生成唯一ID
        let newTheme = ThemeConfiguration(
            id: "custom_\(UUID().uuidString)",
            name: theme.name,
            displayName: theme.displayName,
            category: theme.category,
            author: "Custom User",
            version: "1.0.0",
            description: theme.description,
            colors: theme.colors,
            metadata: nil,
            isBuiltIn: false,
            isEnabled: true,
            previewColors: generatePreviewColors()
        )

        // 保存主题
        themeManager.cacheTheme(newTheme)
        themeManager.setTheme(newTheme, for: newTheme.category)
    }

    private func generatePreviewColors() -> [String] {
        return [
            theme.colors.primary.main,
            theme.colors.secondary.main,
            theme.colors.background.main,
            theme.colors.accent.main,
            theme.colors.text.main
        ]
    }
}

struct ColorPickerView: View {
    let title: String
    @Binding var color: String
    @State private var selectedColor: Color

    init(title: String, color: Binding<String>) {
        self.title = title
        self._color = color
        self._selectedColor = State(initialValue: Color(hex: color.wrappedValue))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)

            HStack {
                ColorPicker("", selection: $selectedColor)
                    .labelsHidden()

                TextField("HEX颜色", text: $color)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 100)

                Rectangle()
                    .fill(selectedColor)
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
        }
        .onChange(of: selectedColor) { newColor in
            color = newColor.toHex()
        }
    }
}
```

## 故障排除

### 1. 常见问题

**问题**: 主题切换后界面没有立即更新
```swift
// 解决方案：确保在主线程上更新UI
DispatchQueue.main.async {
    themeManager.switchToMode(.dark)
}
```

**问题**: 自定义主题没有保存
```swift
// 解决方案：确保调用了缓存方法
themeManager.cacheTheme(customTheme)
themeManager.setTheme(customTheme, for: .light)
```

**问题**: 菜单栏颜色没有更新
```swift
// 解决方案：检查是否正确设置了主题监听
private func observeThemeChanges() {
    NotificationCenter.default.publisher(for: .themeDidChange)
        .sink { [weak self] _ in
            DispatchQueue.main.async {
                self?.updateMenuBarAppearance()
            }
        }
        .store(in: &cancellables)
}
```

### 2. 调试技巧

启用主题系统调试日志：

```swift
// 在应用启动时
#if DEBUG
EnhancedThemeManager.shared.enableDebugLogging()
SystemAppearanceMonitor.shared.enableDebugLogging()
#endif
```

监听主题变化通知：

```swift
NotificationCenter.default.addObserver(
    forName: .themeDidChange,
    object: nil,
    queue: .main
) { notification in
    print("Theme changed: \(notification.userInfo)")
}
```

## 最佳实践

### 1. 性能优化

- 使用 `@EnvironmentObject` 传递主题管理器实例
- 避免在 `body` 中进行复杂计算
- 使用 `@Published` 属性的 `removeDuplicates()` 操作符
- 合理使用动画，避免过度动画

### 2. 用户体验

- 提供实时预览功能
- 保存用户的主题偏好设置
- 支持键盘快捷键切换主题
- 为主题变化提供平滑的过渡动画

### 3. 代码组织

- 将主题相关的代码组织到独立的模块中
- 使用协议定义清晰的接口边界
- 实现依赖注入以便于测试
- 为所有服务提供模拟对象用于单元测试

## 总结

本快速开始指南提供了增强主题系统的完整集成方案，包括：

1. **基本集成**: 如何在应用中引入主题系统
2. **主题感知视图**: 创建响应主题变化的UI组件
3. **设置界面**: 构建用户友好的主题选择界面
4. **预览功能**: 实现实时主题预览
5. **菜单栏集成**: 在菜单栏应用中支持主题
6. **自定义主题**: 允许用户创建和编辑主题
7. **故障排除**: 常见问题和解决方案

遵循本指南，你可以快速为你的应用添加专业级的主题系统功能。