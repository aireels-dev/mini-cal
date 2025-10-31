# Theme Manager Interface Contract

**Version**: 1.0
**Date**: 2025-10-30
**Interface**: `EnhancedThemeManager`

## Overview

定义增强主题管理器的核心接口，负责主题加载、切换、预览和持久化存储。

## Core Protocol Definition

```swift
protocol EnhancedThemeManagerProtocol: ObservableObject {
    // MARK: - Published Properties
    var currentMode: ThemeMode { get set }
    var lightTheme: ThemeConfiguration { get set }
    var darkTheme: ThemeConfiguration { get set }
    var effectiveTheme: ThemeConfiguration { get }
    var availableThemes: [ThemeConfiguration] { get }

    // MARK: - Theme Preview
    var isPreviewing: Bool { get }
    var previewTheme: ThemeConfiguration? { get set }

    // MARK: - Core Methods
    func loadThemes()
    func switchToMode(_ mode: ThemeMode)
    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory)
    func startPreview(theme: ThemeConfiguration)
    func stopPreview()

    // MARK: - Persistence
    func savePreferences()
    func loadPreferences()

    // MARK: - Utilities
    func theme(for id: String) -> ThemeConfiguration?
    func themes(for category: ThemeCategory) -> [ThemeConfiguration]
}
```

## Implementation Requirements

### 1. Class Definition

```swift
class EnhancedThemeManager: EnhancedThemeManagerProtocol {
    // Published Properties
    @Published var currentMode: ThemeMode = .auto
    @Published var lightTheme: ThemeConfiguration
    @Published var darkTheme: ThemeConfiguration
    @Published var previewTheme: ThemeConfiguration?

    // Private Properties
    private var userPreferences: UserThemePreferences
    private let themeCache: ThemeCache
    private let preferencesStorage: PreferencesStorage
    private let systemAppearanceMonitor: SystemAppearanceMonitor

    // Computed Properties
    var effectiveTheme: ThemeConfiguration {
        if isPreviewing, let previewTheme = previewTheme {
            return previewTheme
        }

        switch currentMode {
        case .light:
            return lightTheme
        case .dark:
            return darkTheme
        case .auto:
            return systemAppearanceMonitor.isDarkMode ? darkTheme : lightTheme
        }
    }

    var isPreviewing: Bool {
        return previewTheme != nil
    }

    var availableThemes: [ThemeConfiguration] {
        return themeCache.allThemes()
    }
}
```

### 2. Initializers

```swift
extension EnhancedThemeManager {
    convenience init() {
        self.init(
            preferencesStorage: UserDefaultsPreferencesStorage(),
            themeCache: DefaultThemeCache(),
            systemAppearanceMonitor: DefaultSystemAppearanceMonitor()
        )
    }

    init(
        preferencesStorage: PreferencesStorage,
        themeCache: ThemeCache,
        systemAppearanceMonitor: SystemAppearanceMonitor
    ) {
        self.preferencesStorage = preferencesStorage
        self.themeCache = themeCache
        self.systemAppearanceMonitor = systemAppearanceMonitor

        // 加载内置主题
        self.lightTheme = loadBuiltinTheme(id: "classic_blue")!
        self.darkTheme = loadBuiltinTheme(id: "midnight_blue")!

        // 加载用户偏好设置
        self.userPreferences = preferencesStorage.loadPreferences()
        self.currentMode = userPreferences.mode

        // 恢复用户选择的主题
        if let savedLightTheme = themeCache.theme(for: userPreferences.lightThemeId) {
            self.lightTheme = savedLightTheme
        }
        if let savedDarkTheme = themeCache.theme(for: userPreferences.darkThemeId) {
            self.darkTheme = savedDarkTheme
        }

        // 监听系统外观变化
        setupSystemAppearanceObserver()
    }
}
```

### 3. Core Methods Implementation

```swift
extension EnhancedThemeManager {
    func loadThemes() {
        // 加载内置主题
        loadBuiltinThemes()

        // 加载用户自定义主题
        loadCustomThemes()

        // 更新可用主题列表
        objectWillChange.send()
    }

    func switchToMode(_ mode: ThemeMode) {
        currentMode = mode
        userPreferences.mode = mode

        // 如果正在预览，停止预览
        if isPreviewing {
            stopPreview()
        }

        // 保存设置
        savePreferences()

        // 发送主题变化通知
        NotificationCenter.default.post(name: .themeDidChange, object: effectiveTheme)
    }

    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory) {
        switch category {
        case .light:
            lightTheme = theme
            userPreferences.lightThemeId = theme.id
        case .dark:
            darkTheme = theme
            userPreferences.darkThemeId = theme.id
        }

        // 如果正在预览，停止预览
        if isPreviewing {
            stopPreview()
        }

        // 保存设置
        savePreferences()

        // 发送主题变化通知
        NotificationCenter.default.post(name: .themeDidChange, object: effectiveTheme)
    }

    func startPreview(theme: ThemeConfiguration) {
        previewTheme = theme
        NotificationCenter.default.post(name: .themePreviewStarted, object: theme)
    }

    func stopPreview() {
        previewTheme = nil
        NotificationCenter.default.post(name: .themePreviewStopped, object: nil)
    }
}
```

### 4. Persistence Methods

```swift
extension EnhancedThemeManager {
    func savePreferences() {
        userPreferences.mode = currentMode
        userPreferences.lightThemeId = lightTheme.id
        userPreferences.darkThemeId = darkTheme.id

        preferencesStorage.savePreferences(userPreferences)
    }

    func loadPreferences() {
        userPreferences = preferencesStorage.loadPreferences()
        currentMode = userPreferences.mode

        // 重新加载主题配置
        if let theme = themeCache.theme(for: userPreferences.lightThemeId) {
            lightTheme = theme
        }
        if let theme = themeCache.theme(for: userPreferences.darkThemeId) {
            darkTheme = theme
        }
    }
}
```

### 5. Utility Methods

```swift
extension EnhancedThemeManager {
    func theme(for id: String) -> ThemeConfiguration? {
        return themeCache.theme(for: id)
    }

    func themes(for category: ThemeCategory) -> [ThemeConfiguration] {
        return availableThemes.filter { $0.category == category }
    }

    func resetToDefaults() {
        lightTheme = loadBuiltinTheme(id: "classic_blue")!
        darkTheme = loadBuiltinTheme(id: "midnight_blue")!
        currentMode = .auto
        savePreferences()
    }
}
```

## Supporting Protocols

### 1. Preferences Storage Protocol

```swift
protocol PreferencesStorage {
    func savePreferences(_ preferences: UserThemePreferences)
    func loadPreferences() -> UserThemePreferences
}
```

### 2. Theme Cache Protocol

```swift
protocol ThemeCache {
    func theme(for id: String) -> ThemeConfiguration?
    func cacheTheme(_ theme: ThemeConfiguration)
    func allThemes() -> [ThemeConfiguration]
    func clearCache()
}
```

### 3. System Appearance Monitor Protocol

```swift
protocol SystemAppearanceMonitor: ObservableObject {
    var isDarkMode: Bool { get }
    var systemAppearance: NSAppearance.Name { get }

    func startMonitoring()
    func stopMonitoring()
}
```

## Error Handling

### 1. Theme Loading Errors

```swift
enum ThemeManagerError: Error, LocalizedError {
    case themeNotFound(String)
    case invalidThemeConfiguration(String)
    case preferencesCorrupted
    case systemAppearanceMonitoringFailed

    var errorDescription: String? {
        switch self {
        case .themeNotFound(let id):
            return "未找到主题: \(id)"
        case .invalidThemeConfiguration(let reason):
            return "主题配置无效: \(reason)"
        case .preferencesCorrupted:
            return "用户偏好设置损坏，已重置为默认设置"
        case .systemAppearanceMonitoringFailed:
            return "系统外观监控失败"
        }
    }
}
```

### 2. Error Recovery Strategy

```swift
extension EnhancedThemeManager {
    private func handleThemeLoadingError(_ error: ThemeManagerError) {
        switch error {
        case .preferencesCorrupted:
            // 重置为默认设置
            userPreferences = UserThemePreferences()
            savePreferences()

        case .themeNotFound(let id):
            // 回退到默认主题
            if userPreferences.lightThemeId == id {
                lightTheme = loadBuiltinTheme(id: "classic_blue")!
                userPreferences.lightThemeId = lightTheme.id
            }
            if userPreferences.darkThemeId == id {
                darkTheme = loadBuiltinTheme(id: "midnight_blue")!
                userPreferences.darkThemeId = darkTheme.id
            }
            savePreferences()

        default:
            // 记录错误但继续运行
            NSLog("ThemeManager Error: \(error.localizedDescription)")
        }
    }
}
```

## Performance Requirements

### 1. Response Time

- 主题切换: < 100ms
- 主题预览: < 50ms
- 偏好设置加载: < 20ms
- 偏好设置保存: < 30ms

### 2. Memory Usage

- 主题缓存: < 50MB
- 运行时内存: < 100MB
- 缓存清理策略: LRU，最多缓存20个主题

### 3. Threading Requirements

- UI更新必须在主线程
- 主题加载可在后台线程
- 偏好设置保存异步执行

## Notification System

### 1. Notification Names

```swift
extension Notification.Name {
    static let themeDidChange = Notification.Name("ThemeDidChange")
    static let themePreviewStarted = Notification.Name("ThemePreviewStarted")
    static let themePreviewStopped = Notification.Name("ThemePreviewStopped")
    static let themeModeChanged = Notification.Name("ThemeModeChanged")
}
```

### 2. Notification Payloads

```swift
struct ThemeChangeNotification {
    let newTheme: ThemeConfiguration
    let previousTheme: ThemeConfiguration
    let isPreview: Bool
}

struct ThemeModeChangeNotification {
    let newMode: ThemeMode
    let previousMode: ThemeMode
    let effectiveTheme: ThemeConfiguration
}
```

## Testing Requirements

### 1. Unit Tests Coverage

- 主题切换逻辑: 100%
- 偏好设置持久化: 100%
- 预览功能: 100%
- 错误处理: 100%

### 2. Integration Tests

- 系统外观变化响应
- 主题加载和缓存
- 通知系统
- 内存管理

### 3. Performance Tests

- 主题切换性能基准测试
- 内存使用压力测试
- 并发访问测试

---

**Related Contracts**:
- [preferences-storage-interface.md](./preferences-storage-interface.md)
- [theme-cache-interface.md](./theme-cache-interface.md)
- [system-appearance-monitor-interface.md](./system-appearance-monitor-interface.md)