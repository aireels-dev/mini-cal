# UI Components Interface Contract

**Version**: 1.0
**Date**: 2025-10-30
**Interface**: Theme-aware UI Components

## Overview

定义支持主题系统的UI组件接口，确保所有界面元素能够正确响应主题变化。

## Theme-Aware View Protocol

```swift
protocol ThemeAwareView: View {
    associatedtype ThemeType = EnhancedThemeManager

    var themeManager: ThemeType { get }
    func applyTheme(_ theme: ThemeConfiguration)
}
```

## Core UI Components

### 1. Themeable Calendar View

```swift
struct ThemeableCalendarView: View, ThemeAwareView {
    @ObservedObject var themeManager: EnhancedThemeManager
    @State private var calendarViewModel: CalendarViewModel

    var body: some View {
        VStack(spacing: 0) {
            headerView
            gridView
        }
        .background(Color(themeManager.effectiveTheme.background.main))
        .foregroundColor(Color(themeManager.effectiveTheme.text.primary))
        .onReceive(NotificationCenter.default.publisher(for: .themeDidChange)) { notification in
            if let theme = notification.object as? ThemeConfiguration {
                withAnimation(.easeInOut(duration: 0.3)) {
                    applyTheme(theme)
                }
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("日历")
                .font(.headline)
                .foregroundColor(Color(themeManager.effectiveTheme.text.primary))

            Spacer()

            Button(action: {}) {
                Image(systemName: "calendar")
                    .foregroundColor(Color(themeManager.effectiveTheme.primary.main))
            }
            .buttonStyle(ThemeableButtonStyle(theme: themeManager.effectiveTheme))
        }
        .padding()
        .background(Color(themeManager.effectiveTheme.surface.main))
    }

    private var gridView: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 1) {
            ForEach(calendarViewModel.days, id: \.id) { day in
                ThemeableCalendarDayView(
                    day: day,
                    theme: themeManager.effectiveTheme
                )
            }
        }
        .padding()
    }

    func applyTheme(_ theme: ThemeConfiguration) {
        // 主题变化时的自定义逻辑
        calendarViewModel.refreshDisplay()
    }
}
```

### 2. Themeable Settings View

```swift
struct ThemeableSettingsView: View {
    @ObservedObject var themeManager: EnhancedThemeManager
    @State private var selectedMode: ThemeMode
    @State private var previewState = ThemePreviewState()

    init(themeManager: EnhancedThemeManager) {
        self.themeManager = themeManager
        self._selectedMode = State(initialValue: themeManager.currentMode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                themeModeSection
                themeSelectionSection
                advancedOptionsSection
            }
            .padding()
        }
        .background(Color(themeManager.effectiveTheme.background.main))
        .navigationTitle("主题设置")
        .onAppear {
            selectedMode = themeManager.currentMode
        }
        .onDisappear {
            if previewState.isPreviewing {
                themeManager.stopPreview()
            }
        }
    }

    private var themeModeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("主题模式")
                .font(.headline)
                .foregroundColor(Color(themeManager.effectiveTheme.text.primary))

            ThemeableSegmentedControl(
                selection: $selectedMode,
                options: ThemeMode.allCases
            ) { mode in
                Text(mode.displayName)
            }
            .onChange(of: selectedMode) { newMode in
                themeManager.switchToMode(newMode)
            }
        }
        .padding()
        .background(Color(themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("选择主题")
                .font(.headline)
                .foregroundColor(Color(themeManager.effectiveTheme.text.primary))

            ThemeableThemeGridView(
                themes: themesForCurrentMode,
                selectedTheme: currentThemeForMode,
                previewState: previewState,
                theme: themeManager.effectiveTheme,
                onThemeSelect: { theme in
                    handleThemeSelection(theme)
                },
                onThemeHover: { theme in
                    handleThemePreview(theme)
                }
            )
        }
        .padding()
        .background(Color(themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("高级选项")
                .font(.headline)
                .foregroundColor(Color(themeManager.effectiveTheme.text.primary))

            ThemeableToggle(
                isOn: Binding(
                    get: { themeManager.userPreferences.enableRealTimePreview },
                    set: { value in
                        themeManager.userPreferences.enableRealTimePreview = value
                        themeManager.savePreferences()
                    }
                ),
                title: "实时预览",
                description: "悬停时预览主题效果"
            )

            ThemeableToggle(
                isOn: Binding(
                    get: { themeManager.userPreferences.enableSmoothTransitions },
                    set: { value in
                        themeManager.userPreferences.enableSmoothTransitions = value
                        themeManager.savePreferences()
                    }
                ),
                title: "平滑过渡",
                description: "启用主题切换动画"
            )
        }
        .padding()
        .background(Color(themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var themesForCurrentMode: [ThemeConfiguration] {
        switch selectedMode {
        case .light:
            return themeManager.themes(for: .light)
        case .dark:
            return themeManager.themes(for: .dark)
        case .auto:
            return themeManager.themes(for: .light) + themeManager.themes(for: .dark)
        }
    }

    private var currentThemeForMode: ThemeConfiguration? {
        switch selectedMode {
        case .light:
            return themeManager.lightTheme
        case .dark:
            return themeManager.darkTheme
        case .auto:
            return themeManager.effectiveTheme
        }
    }

    private func handleThemeSelection(_ theme: ThemeConfiguration) {
        switch selectedMode {
        case .light:
            themeManager.setTheme(theme, for: .light)
        case .dark:
            themeManager.setTheme(theme, for: .dark)
        case .auto:
            if theme.category == .light {
                themeManager.setTheme(theme, for: .light)
            } else {
                themeManager.setTheme(theme, for: .dark)
            }
        }

        previewState.stopPreview()
    }

    private func handleThemePreview(_ theme: ThemeConfiguration) {
        if themeManager.userPreferences.enableRealTimePreview {
            themeManager.startPreview(theme: theme)
            previewState.startPreview(
                themeId: theme.id,
                originalThemeId: currentThemeForMode?.id ?? ""
            )
        }
    }
}
```

### 3. Themeable Theme Grid View

```swift
struct ThemeableThemeGridView: View {
    let themes: [ThemeConfiguration]
    let selectedTheme: ThemeConfiguration?
    let previewState: ThemePreviewState
    let theme: ThemeConfiguration
    let onThemeSelect: (ThemeConfiguration) -> Void
    let onThemeHover: (ThemeConfiguration) -> Void

    private let columns = Array(repeating: GridItem(.flexible()), count: 2)
    private let themeSize: CGFloat = 120

    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(themes) { themeItem in
                ThemeableThemeCard(
                    theme: themeItem,
                    isSelected: selectedTheme?.id == themeItem.id,
                    isPreviewing: previewState.previewThemeId == themeItem.id,
                    baseTheme: theme,
                    onTap: {
                        onThemeSelect(themeItem)
                    },
                    onHover: {
                        onThemeHover(themeItem)
                    }
                )
                .frame(height: themeSize)
            }
        }
    }
}
```

### 4. Themeable Theme Card

```swift
struct ThemeableThemeCard: View {
    let theme: ThemeConfiguration
    let isSelected: Bool
    let isPreviewing: Bool
    let baseTheme: ThemeConfiguration
    let onTap: () -> Void
    let onHover: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 预览色块
            HStack(spacing: 4) {
                ForEach(theme.previewColors, id: \.self) { colorHex in
                    Rectangle()
                        .fill(Color(hex: colorHex))
                        .frame(height: 40)
                }
            }
            .cornerRadius(8)

            // 主题名称
            Text(theme.displayName)
                .font(.caption)
                .foregroundColor(Color(baseTheme.text.primary))
                .lineLimit(1)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            if hovering {
                onHover()
            }
        }
        .scaleEffect(isPreviewing ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isPreviewing)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(baseTheme.primary.main).opacity(0.1)
        } else {
            return Color(baseTheme.surface.main)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color(baseTheme.primary.main)
        } else {
            return Color(baseTheme.surface.main)
        }
    }
}
```

## Themeable UI Components

### 1. Themeable Button Style

```swift
struct ThemeableButtonStyle: ButtonStyle {
    let theme: ThemeConfiguration

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ?
                           Color(theme.primary.dark ?? theme.primary.main) :
                           Color(theme.primary.main))
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(configuration.isPressed ?
                          Color(theme.surface.dark ?? theme.surface.main) :
                          Color(theme.surface.main))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
```

### 2. Themeable Segmented Control

```swift
struct ThemeableSegmentedControl<T: CaseIterable & Hashable>: View where T: CustomStringConvertible {
    @Binding var selection: T
    let options: [T]
    let content: (T) -> AnyView
    let theme: ThemeConfiguration

    init(
        selection: Binding<T>,
        options: [T] = T.allCases,
        @ViewBuilder content: @escaping (T) -> some View
    ) {
        self._selection = selection
        self.options = options
        self.content = { view in AnyView(content(view)) }
        self.theme = EnhancedThemeManager.shared.effectiveTheme
    }

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.self) { option in
                Button(action: { selection = option }) {
                    content(option)
                        .font(.caption)
                        .foregroundColor(selection == option ?
                                     Color(theme.surface.main) :
                                     Color(theme.text.primary))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(selection == option ?
                                      Color(theme.primary.main) :
                                      Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(theme.surface.main))
        )
    }
}
```

### 3. Themeable Toggle

```swift
struct ThemeableToggle: View {
    @Binding var isOn: Bool
    let title: String
    let description: String?
    let theme: ThemeConfiguration

    init(
        isOn: Binding<Bool>,
        title: String,
        description: String? = nil
    ) {
        self._isOn = isOn
        self.title = title
        self.description = description
        self.theme = EnhancedThemeManager.shared.effectiveTheme
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.body)
                    .foregroundColor(Color(theme.text.primary))

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(Color(theme.text.secondary))
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .toggleStyle(ThemeableToggleStyle(theme: theme))
        }
    }
}

struct ThemeableToggleStyle: ToggleStyle {
    let theme: ThemeConfiguration

    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration.label

            Spacer()

            RoundedRectangle(cornerRadius: 16)
                .fill(configuration.isOn ?
                      Color(theme.primary.main) :
                      Color(theme.text.secondary).opacity(0.3))
                .frame(width: 48, height: 28)
                .overlay(
                    Circle()
                        .fill(Color.white)
                        .frame(width: 24, height: 24)
                        .offset(x: configuration.isOn ? 10 : -10)
                        .animation(.easeInOut(duration: 0.2), value: configuration.isOn)
                )
                .onTapGesture {
                    configuration.isOn.toggle()
                }
        }
    }
}
```

## Theme Transition Animation

```swift
struct ThemeTransition: ViewModifier {
    let isActive: Bool

    func body(content: Content) -> some View {
        content
            .animation(
                isActive ?
                .easeInOut(duration: 0.3) :
                .easeInOut(duration: 0.1),
                value: isActive
            )
    }
}

extension View {
    func themeTransition(isActive: Bool = true) -> some View {
        modifier(ThemeTransition(isActive: isActive))
    }
}
```

## Color Extensions

```swift
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
```

## Performance Requirements

### 1. Animation Performance

- 主题切换动画: 60fps
- 动画持续时间: 200-300ms
- CPU使用峰值: < 5%

### 2. Rendering Optimization

- 使用 `LazyVGrid` 进行虚拟化渲染
- 预览色块使用缓存的颜色
- 避免不必要的视图重建

### 3. Memory Management

- 主题卡图片按需加载
- 及时释放预览状态资源
- 使用弱引用避免循环引用

## Accessibility Support

### 1. VoiceOver Support

- 所有交互元素支持VoiceOver
- 主题选择提供语音反馈
- 颜色变化配合文本描述

### 2. Color Contrast

- 确保文本与背景对比度 ≥ 4.5:1
- 大文本对比度 ≥ 3:1
- 提供高对比度主题选项

### 3. Keyboard Navigation

- 完整的键盘导航支持
- Tab键顺序逻辑清晰
- 焦点指示器清晰可见

---

**Related Contracts**:
- [theme-manager-interface.md](./theme-manager-interface.md)
- [color-utilities-interface.md](./color-utilities-interface.md)