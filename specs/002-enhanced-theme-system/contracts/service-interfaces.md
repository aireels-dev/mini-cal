# Enhanced Theme System - 服务接口合约

**版本**: 1.0
**日期**: 2025-10-30
**特性**: 002-Enhanced Theme System

## 概述

本文档定义了增强主题系统的服务接口合约，包括核心服务协议、方法签名、依赖关系和实现要求。所有接口都遵循 Swift 5.9+ 最佳实践，支持依赖注入和单元测试。

## 核心服务协议

### 1. 增强主题管理器协议

```swift
/// 增强主题管理器协议
protocol EnhancedThemeManagerProtocol: ObservableObject {
    // MARK: - Published Properties
    var currentMode: ThemeMode { get set }
    var lightTheme: ThemeConfiguration { get set }
    var darkTheme: ThemeConfiguration { get set }
    var previewTheme: ThemeConfiguration? { get set }
    var availableThemes: [ThemeConfiguration] { get }

    // MARK: - Computed Properties
    var effectiveTheme: ThemeConfiguration { get }
    var isPreviewing: Bool { get }

    // MARK: - Core Methods
    func loadThemes()
    func switchToMode(_ mode: ThemeMode)
    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory)
    func startPreview(theme: ThemeConfiguration)
    func stopPreview()

    // MARK: - Utility Methods
    func theme(for id: String) -> ThemeConfiguration?
    func themes(for category: ThemeCategory) -> [ThemeConfiguration]
    func resetToDefaults()
    func validateTheme(_ theme: ThemeConfiguration) -> [ValidationError]

    // MARK: - Import/Export
    func exportTheme(_ theme: ThemeConfiguration) -> Data?
    func importTheme(from data: Data) -> ThemeConfiguration?

    // MARK: - Statistics
    func getThemeStatistics() -> ThemeStatistics
}
```

### 2. 系统外观监控器协议

```swift
/// 系统外观监控器协议
protocol SystemAppearanceMonitorProtocol: ObservableObject {
    // MARK: - Properties
    var isDarkMode: Bool { get }
    var systemAppearance: NSAppearance.Name { get }
    var effectiveColorScheme: ColorScheme? { get }

    // MARK: - Methods
    func startMonitoring()
    func stopMonitoring()
    func refreshAppearance()

    // MARK: - Utility Methods
    func suggestedThemeMode(for userPreference: ThemeMode) -> ThemeMode
    func appropriateThemeCategory() -> ThemeCategory
    func onAppearanceChange(perform action: @escaping (Bool) -> Void) -> AnyCancellable
}
```

### 3. 用户偏好存储协议

```swift
/// 用户偏好存储协议
protocol UserPreferencesStorageProtocol: ObservableObject {
    // MARK: - Core Methods
    func savePreferences(_ preferences: UserThemePreferences) -> Bool
    func loadPreferences() -> UserThemePreferences

    // MARK: - Validation
    func validatePreferences(_ preferences: UserThemePreferences) -> [ValidationError]

    // MARK: - Migration
    func migratePreferences(from oldVersion: String, to newVersion: String) -> UserThemePreferences
}
```

### 4. 主题缓存协议

```swift
/// 主题缓存协议
protocol ThemeCacheProtocol {
    // MARK: - Cache Operations
    func theme(for id: String) -> ThemeConfiguration?
    func cacheTheme(_ theme: ThemeConfiguration)
    func removeTheme(for id: String)
    func clearCache()

    // MARK: - Batch Operations
    func cacheThemes(_ themes: [ThemeConfiguration])
    func allThemes() -> [ThemeConfiguration]

    // MARK: - Cache Management
    func setCacheLimit(_ limit: Int)
    func getCacheStatistics() -> CacheStatistics
}
```

### 5. 性能监控协议

```swift
/// 性能监控协议
protocol PerformanceMonitorProtocol {
    // MARK: - Measurement
    func measure<T>(_ operation: () throws -> T, named operationName: String) rethrows -> T
    func measureThemeSwitch(from: ThemeConfiguration, to: ThemeConfiguration, operation: () -> Void)

    // MARK: - Statistics
    func getPerformanceStatistics() -> PerformanceStatistics
    func recordMetric(_ name: String, value: Double)
    func resetMetrics()
}
```

## 服务接口实现

### 1. 增强主题管理器实现

```swift
/// 增强主题管理器实现
class EnhancedThemeManager: ObservableObject, EnhancedThemeManagerProtocol {
    static let shared = EnhancedThemeManager()

    // MARK: - Published Properties
    @Published var currentMode: ThemeMode = .auto
    @Published var lightTheme: ThemeConfiguration = .defaultLight
    @Published var darkTheme: ThemeConfiguration = .defaultDark
    @Published var previewTheme: ThemeConfiguration?
    @Published var availableThemes: [ThemeConfiguration] = []

    // MARK: - Dependencies
    private let themeCache: ThemeCacheProtocol
    private let preferencesStorage: UserPreferencesStorageProtocol
    private let systemAppearanceMonitor: SystemAppearanceMonitorProtocol
    private let performanceMonitor: PerformanceMonitorProtocol
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization
    init(
        themeCache: ThemeCacheProtocol = ThemeCache.shared,
        preferencesStorage: UserPreferencesStorageProtocol = UserPreferencesStorage.shared,
        systemAppearanceMonitor: SystemAppearanceMonitorProtocol = SystemAppearanceMonitor.shared,
        performanceMonitor: PerformanceMonitorProtocol = PerformanceMonitor.shared
    ) {
        self.themeCache = themeCache
        self.preferencesStorage = preferencesStorage
        self.systemAppearanceMonitor = systemAppearanceMonitor
        self.performanceMonitor = performanceMonitor

        loadPreferences()
        loadThemes()
        setupAppearanceObserver()
        setupPerformanceMonitoring()
    }

    // MARK: - Computed Properties
    var effectiveTheme: ThemeConfiguration {
        if let previewTheme = previewTheme {
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

    // MARK: - Core Methods Implementation
    func loadThemes() {
        performanceMonitor.measure(named: "load_themes") {
            availableThemes = themeCache.allThemes()

            // 确保默认主题可用
            if themeCache.theme(for: lightTheme.id) == nil {
                lightTheme = .defaultLight
            }
            if themeCache.theme(for: darkTheme.id) == nil {
                darkTheme = .defaultDark
            }

            print("🎨 Loaded \(availableThemes.count) themes")
        }
    }

    func switchToMode(_ mode: ThemeMode) {
        performanceMonitor.measureThemeSwitch(from: effectiveTheme, to: effectiveTheme) {
            let previousMode = currentMode
            currentMode = mode

            // 如果正在预览，停止预览
            if isPreviewing {
                stopPreview()
            }

            savePreferences()

            // 发送主题变化通知
            NotificationCenter.default.post(
                name: .themeDidChange,
                object: effectiveTheme,
                userInfo: [
                    "mode": mode,
                    "previousMode": previousMode
                ]
            )
        }
    }

    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory) {
        performanceMonitor.measureThemeSwitch(from: effectiveTheme, to: theme) {
            let previousTheme = effectiveTheme

            switch category {
            case .light:
                lightTheme = theme
            case .dark:
                darkTheme = theme
            }

            // 如果正在预览，停止预览
            if isPreviewing {
                stopPreview()
            }

            savePreferences()

            // 发送主题变化通知
            NotificationCenter.default.post(
                name: .themeDidChange,
                object: effectiveTheme,
                userInfo: [
                    "theme": theme,
                    "category": category.rawValue,
                    "previousTheme": previousTheme
                ]
            )
        }
    }

    func startPreview(theme: ThemeConfiguration) {
        performanceMonitor.measure(named: "theme_preview") {
            previewTheme = theme

            NotificationCenter.default.post(
                name: .themePreviewStarted,
                object: theme,
                userInfo: ["previewTheme": theme]
            )
        }
    }

    func stopPreview() {
        let previousPreviewTheme = previewTheme
        previewTheme = nil

        NotificationCenter.default.post(
            name: .themePreviewStopped,
            object: nil,
            userInfo: [
                "previousPreviewTheme": previousPreviewTheme as Any,
                "effectiveTheme": effectiveTheme
            ]
        )
    }

    // MARK: - Utility Methods Implementation
    func theme(for id: String) -> ThemeConfiguration? {
        return themeCache.theme(for: id) ?? availableThemes.first { $0.id == id }
    }

    func themes(for category: ThemeCategory) -> [ThemeConfiguration] {
        return availableThemes.filter { $0.category == category }
    }

    func resetToDefaults() {
        performanceMonitor.measure(named: "reset_to_defaults") {
            lightTheme = .defaultLight
            darkTheme = .defaultDark
            currentMode = .auto
            previewTheme = nil

            savePreferences()

            NotificationCenter.default.post(
                name: .themeDidReset,
                object: nil,
                userInfo: ["message": "Theme settings reset to defaults"]
            )
        }
    }

    func validateTheme(_ theme: ThemeConfiguration) -> [ValidationError] {
        return theme.validate()
    }

    func exportTheme(_ theme: ThemeConfiguration) -> Data? {
        return try? JSONEncoder().encode(theme)
    }

    func importTheme(from data: Data) -> ThemeConfiguration? {
        guard let theme = try? JSONDecoder().decode(ThemeConfiguration.self, from: data) else {
            return nil
        }

        // 重新加载可用主题列表
        loadThemes()

        return theme
    }

    func getThemeStatistics() -> ThemeStatistics {
        let lightThemes = themes(for: .light)
        let darkThemes = themes(for: .dark)
        let builtinThemes = availableThemes.filter { $0.isBuiltIn }
        let customThemes = availableThemes.filter { !$0.isBuiltIn }

        return ThemeStatistics(
            totalThemes: availableThemes.count,
            lightThemes: lightThemes.count,
            darkThemes: darkThemes.count,
            builtinThemes: builtinThemes.count,
            customThemes: customThemes.count,
            currentMode: currentMode,
            currentTheme: effectiveTheme.id,
            isPreviewing: isPreviewing
        )
    }

    // MARK: - Private Methods
    private func loadPreferences() {
        let userPreferences = preferencesStorage.loadPreferences()

        currentMode = userPreferences.mode

        // 加载用户选择的主题
        if let lightTheme = theme(for: userPreferences.lightThemeId) {
            self.lightTheme = lightTheme
        } else {
            self.lightTheme = .defaultLight
        }

        if let darkTheme = theme(for: userPreferences.darkThemeId) {
            self.darkTheme = darkTheme
        } else {
            self.darkTheme = .defaultDark
        }

        print("🎨 Loaded preferences: mode=\(currentMode), light=\(self.lightTheme.id), dark=\(self.darkTheme.id)")
    }

    private func savePreferences() {
        var userPreferences = UserThemePreferences()
        userPreferences.mode = currentMode
        userPreferences.lightThemeId = lightTheme.id
        userPreferences.darkThemeId = darkTheme.id
        userPreferences.enableRealTimePreview = true
        userPreferences.enableSmoothTransitions = true
        userPreferences.lastUsedVersion = "1.0"

        let success = preferencesStorage.savePreferences(userPreferences)
        if !success {
            print("⚠️ Failed to save theme preferences")
        }
    }

    private func setupAppearanceObserver() {
        // 监听系统外观变化
        systemAppearanceMonitor.$isDarkMode
            .removeDuplicates()
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.handleSystemAppearanceChange()
                }
            }
            .store(in: &cancellables)
    }

    private func setupPerformanceMonitoring() {
        // 监控主题切换性能
        NotificationCenter.default.publisher(for: .themeDidChange)
            .sink { [weak self] notification in
                guard let self = self else { return }

                if let theme = notification.object as? ThemeConfiguration {
                    let stats = self.performanceMonitor.getPerformanceStatistics()
                    if let operationStats = stats.operationStatistics["theme_switch"] {
                        if operationStats.averageDuration > 0.1 {
                            print("⚠️ Slow theme switch detected: \(operationStats.averageDuration * 1000)ms")
                        }
                    }
                }
            }
            .store(in: &cancellables)
    }

    private func handleSystemAppearanceChange() {
        // 只有在自动模式下才需要响应系统外观变化
        guard currentMode == .auto else { return }

        let newEffectiveTheme = effectiveTheme
        NotificationCenter.default.post(
            name: .effectiveThemeDidChange,
            object: newEffectiveTheme,
            userInfo: [
                "trigger": "system_appearance_change",
                "isDarkMode": systemAppearanceMonitor.isDarkMode
            ]
        )
    }
}
```

### 2. 系统外观监控器实现

```swift
/// 系统外观监控器实现
class SystemAppearanceMonitor: ObservableObject, SystemAppearanceMonitorProtocol {
    static let shared = SystemAppearanceMonitor()

    // MARK: - Published Properties
    @Published var isDarkMode: Bool = false
    @Published var systemAppearance: NSAppearance.Name = .aqua
    @Published var effectiveColorScheme: ColorScheme? = .light

    // MARK: - Private Properties
    private var appearanceObserver: NSObjectProtocol?
    private var cancellables = Set<AnyCancellable>()
    private let debounceInterval: TimeInterval = 0.3
    private var debounceWorkItem: DispatchWorkItem?

    // MARK: - Initialization
    private init() {
        setupInitialAppearance()
        startMonitoring()
    }

    deinit {
        stopMonitoring()
    }

    // MARK: - Methods Implementation
    func startMonitoring() {
        guard appearanceObserver == nil else { return }

        // 监听系统外观变化通知
        appearanceObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeEffectiveAppearance,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleAppearanceChange()
        }

        print("🎨 System appearance monitoring started")
    }

    func stopMonitoring() {
        if let observer = appearanceObserver {
            NotificationCenter.default.removeObserver(observer)
            appearanceObserver = nil
        }

        debounceWorkItem?.cancel()
        cancellables.removeAll()

        print("🎨 System appearance monitoring stopped")
    }

    func refreshAppearance() {
        updateAppearanceState()
    }

    // MARK: - Utility Methods Implementation
    func suggestedThemeMode(for userPreference: ThemeMode) -> ThemeMode {
        switch userPreference {
        case .light, .dark:
            return userPreference
        case .auto:
            return isDarkMode ? .dark : .light
        }
    }

    func appropriateThemeCategory() -> ThemeCategory {
        return isDarkMode ? .dark : .light
    }

    func onAppearanceChange(perform action: @escaping (Bool) -> Void) -> AnyCancellable {
        return $isDarkMode
            .removeDuplicates()
            .sink { isDark in
                action(isDark)
            }
    }

    // MARK: - Private Methods
    private func setupInitialAppearance() {
        updateAppearanceState()
    }

    private func handleAppearanceChange() {
        // 使用防抖动来避免频繁更新
        debounceWorkItem?.cancel()
        debounceWorkItem = DispatchWorkItem { [weak self] in
            self?.updateAppearanceState()
        }

        if let workItem = debounceWorkItem {
            DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
        }
    }

    private func updateAppearanceState() {
        let newAppearance = NSApp.effectiveAppearance.name
        let newIsDarkMode = isDarkAppearance(newAppearance)
        let newColorScheme = newIsDarkMode ? ColorScheme.dark : ColorScheme.light

        // 检查是否需要更新
        guard systemAppearance != newAppearance ||
              isDarkMode != newIsDarkMode ||
              effectiveColorScheme != newColorScheme else {
            return
        }

        let oldAppearance = systemAppearance
        let oldIsDarkMode = isDarkMode

        // 更新状态
        systemAppearance = newAppearance
        isDarkMode = newIsDarkMode
        effectiveColorScheme = newColorScheme

        // 发送通知
        NotificationCenter.default.post(
            name: .systemAppearanceDidChange,
            object: self,
            userInfo: [
                "oldAppearance": oldAppearance,
                "newAppearance": newAppearance,
                "oldIsDarkMode": oldIsDarkMode,
                "newIsDarkMode": newIsDarkMode
            ]
        )

        print("🎨 System appearance changed: \(oldAppearance) → \(newAppearance) (Dark mode: \(newIsDarkMode))")
    }

    private func isDarkAppearance(_ appearance: NSAppearance.Name) -> Bool {
        switch appearance {
        case .darkAqua, .vibrantDark:
            return true
        case .aqua, .vibrantLight:
            return false
        default:
            // 检查最佳匹配外观
            return NSApp.effectiveAppearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        }
    }
}
```

### 3. 用户偏好存储实现

```swift
/// 用户偏好存储实现
class UserPreferencesStorage: ObservableObject, UserPreferencesStorageProtocol {
    static let shared = UserPreferencesStorage()

    // MARK: - Properties
    private let userDefaultsKey = "com.minical.theme.preferences"
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    // MARK: - Initialization
    private init() {}

    // MARK: - Methods Implementation
    func savePreferences(_ preferences: UserThemePreferences) -> Bool {
        do {
            let data = try encoder.encode(preferences)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            return true
        } catch {
            print("Failed to save theme preferences: \(error)")
            return false
        }
    }

    func loadPreferences() -> UserThemePreferences {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            return UserThemePreferences()
        }

        do {
            return try decoder.decode(UserThemePreferences.self, from: data)
        } catch {
            print("Failed to load theme preferences: \(error)")
            // 尝试从损坏的数据中恢复
            return recoverFromCorruptedData()
        }
    }

    func validatePreferences(_ preferences: UserThemePreferences) -> [ValidationError] {
        var errors: [ValidationError] = []

        // 检查主题ID是否有效
        if preferences.lightThemeId.isEmpty {
            errors.append(ValidationError(
                field: "lightThemeId",
                message: "白天主题ID不能为空"
            ))
        }

        if preferences.darkThemeId.isEmpty {
            errors.append(ValidationError(
                field: "darkThemeId",
                message: "黑夜主题ID不能为空"
            ))
        }

        return errors
    }

    func migratePreferences(from oldVersion: String, to newVersion: String) -> UserThemePreferences {
        var preferences = loadPreferences()

        // 根据版本进行迁移
        switch (oldVersion, newVersion) {
        case ("1.0", "1.1"):
            // 添加新的设置字段
            if preferences.customSettings.isEmpty {
                preferences.customSettings = [:]
            }

        case ("1.1", "2.0"):
            // 重构主题ID格式
            preferences.lightThemeId = migrateThemeId(preferences.lightThemeId)
            preferences.darkThemeId = migrateThemeId(preferences.darkThemeId)

        default:
            break
        }

        preferences.lastUsedVersion = newVersion
        _ = savePreferences(preferences)
        return preferences
    }

    // MARK: - Private Methods
    private func recoverFromCorruptedData() -> UserThemePreferences {
        var preferences = UserThemePreferences()

        // 尝试恢复部分设置
        if let data = UserDefaults.standard.data(forKey: userDefaultsKey) {
            if let partialPreferences = try? decoder.decode(
                PartialUserThemePreferences.self,
                from: data
            ) {
                preferences.mode = partialPreferences.mode ?? .auto
                if let lightId = partialPreferences.lightThemeId, !lightId.isEmpty {
                    preferences.lightThemeId = lightId
                }
                if let darkId = partialPreferences.darkThemeId, !darkId.isEmpty {
                    preferences.darkThemeId = darkId
                }
            }
        }

        return preferences
    }

    private func migrateThemeId(_ oldId: String) -> String {
        let migrationMap = [
            "blue": "classic_blue",
            "green": "fresh_green",
            "dark_blue": "midnight_blue",
            "orange": "sunset_orange",
            "red": "ruby_red",
            "gray": "graphite_gray"
        ]
        return migrationMap[oldId] ?? oldId
    }
}

/// 部分用户偏好设置（用于数据恢复）
private struct PartialUserThemePreferences: Codable {
    var mode: ThemeMode?
    var lightThemeId: String?
    var darkThemeId: String?
    var enableRealTimePreview: Bool?
    var enableSmoothTransitions: Bool?
}
```

### 4. 主题缓存实现

```swift
/// 主题缓存实现
class ThemeCache: ThemeCacheProtocol {
    static let shared = ThemeCache()

    // MARK: - Properties
    private var cache: [String: ThemeConfiguration] = [:]
    private let cacheQueue = DispatchQueue(label: "theme.cache", qos: .userInitiated)
    private var cacheLimit: Int = 50

    // MARK: - Initialization
    private init() {
        loadBuiltInThemes()
    }

    // MARK: - Methods Implementation
    func theme(for id: String) -> ThemeConfiguration? {
        return cacheQueue.sync {
            return cache[id]
        }
    }

    func cacheTheme(_ theme: ThemeConfiguration) {
        cacheQueue.async {
            self.cache[theme.id] = theme
        }
    }

    func removeTheme(for id: String) {
        cacheQueue.async {
            self.cache.removeValue(forKey: id)
        }
    }

    func clearCache() {
        cacheQueue.async {
            self.cache.removeAll()
        }
    }

    func cacheThemes(_ themes: [ThemeConfiguration]) {
        cacheQueue.async {
            for theme in themes {
                self.cache[theme.id] = theme
            }
        }
    }

    func allThemes() -> [ThemeConfiguration] {
        return cacheQueue.sync {
            return Array(cache.values)
        }
    }

    func setCacheLimit(_ limit: Int) {
        cacheQueue.async {
            self.cacheLimit = limit
            self.enforceCacheLimit()
        }
    }

    func getCacheStatistics() -> CacheStatistics {
        return cacheQueue.sync {
            return CacheStatistics(
                totalThemes: cache.count,
                builtinThemes: cache.values.filter { $0.isBuiltIn }.count,
                customThemes: cache.values.filter { !$0.isBuiltIn }.count,
                cacheLimit: cacheLimit,
                memoryUsage: calculateMemoryUsage()
            )
        }
    }

    // MARK: - Private Methods
    private func loadBuiltInThemes() {
        let builtInThemes = ThemeConfiguration.builtInThemes
        cacheThemes(builtInThemes)
    }

    private func enforceCacheLimit() {
        guard cache.count > cacheLimit else { return }

        // 按访问时间排序，移除最少使用的主题
        let sortedThemes = cache.values.sorted { theme1, theme2 in
            // 这里可以根据需要实现更复杂的缓存策略
            return theme1.id < theme2.id
        }

        let themesToRemove = sortedThemes.prefix(cache.count - cacheLimit)
        for theme in themesToRemove {
            if !theme.isBuiltIn {
                cache.removeValue(forKey: theme.id)
            }
        }
    }

    private func calculateMemoryUsage() -> Int64 {
        // 简化的内存使用计算
        return Int64(cache.count * 1024) // 假设每个主题占用1KB
    }
}

/// 缓存统计信息
struct CacheStatistics {
    let totalThemes: Int
    let builtinThemes: Int
    let customThemes: Int
    let cacheLimit: Int
    let memoryUsage: Int64
}
```

### 5. 性能监控器实现

```swift
/// 性能监控器实现
class PerformanceMonitor: PerformanceMonitorProtocol {
    static let shared = PerformanceMonitor()

    // MARK: - Properties
    private var operationMetrics: [String: [OperationMetric]] = [:]
    private let metricsQueue = DispatchQueue(label: "performance.metrics", qos: .utility)

    // MARK: - Initialization
    private init() {}

    // MARK: - Methods Implementation
    func measure<T>(_ operation: () throws -> T, named operationName: String) rethrows -> T {
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = try operation()
        let duration = CFAbsoluteTimeGetCurrent() - startTime

        recordOperationMetric(name: operationName, duration: duration)

        return result
    }

    func measureThemeSwitch(from: ThemeConfiguration, to: ThemeConfiguration, operation: () -> Void) {
        let metric = measure(
            named: "theme_switch",
            operation: {
                operation()
                return from.id + " → " + to.id
            }
        )
    }

    func getPerformanceStatistics() -> PerformanceStatistics {
        return metricsQueue.sync {
            var operationStatistics: [String: OperationStatistics] = [:]

            for (operationName, metrics) in operationMetrics {
                let durations = metrics.map { $0.duration }
                let totalDuration = durations.reduce(0, +)
                let averageDuration = totalDuration / Double(durations.count)
                let minDuration = durations.min() ?? 0
                let maxDuration = durations.max() ?? 0

                operationStatistics[operationName] = OperationStatistics(
                    operationCount: metrics.count,
                    totalDuration: totalDuration,
                    averageDuration: averageDuration,
                    minDuration: minDuration,
                    maxDuration: maxDuration
                )
            }

            return PerformanceStatistics(
                operationStatistics: operationStatistics,
                timestamp: Date()
            )
        }
    }

    func recordMetric(_ name: String, value: Double) {
        metricsQueue.async {
            // 这里可以实现自定义指标记录
            print("Performance Metric: \(name) = \(value)")
        }
    }

    func resetMetrics() {
        metricsQueue.async {
            self.operationMetrics.removeAll()
        }
    }

    // MARK: - Private Methods
    private func recordOperationMetric(name: String, duration: TimeInterval) {
        metricsQueue.async {
            let metric = OperationMetric(timestamp: Date(), duration: duration)

            if self.operationMetrics[name] == nil {
                self.operationMetrics[name] = []
            }

            self.operationMetrics[name]?.append(metric)

            // 限制保存的指标数量
            if let metrics = self.operationMetrics[name], metrics.count > 1000 {
                self.operationMetrics[name] = Array(metrics.suffix(500))
            }
        }
    }
}

/// 操作指标
private struct OperationMetric {
    let timestamp: Date
    let duration: TimeInterval
}

/// 操作统计信息
struct OperationStatistics {
    let operationCount: Int
    let totalDuration: TimeInterval
    let averageDuration: TimeInterval
    let minDuration: TimeInterval
    let maxDuration: TimeInterval
}

/// 性能统计信息
struct PerformanceStatistics {
    let operationStatistics: [String: OperationStatistics]
    let timestamp: Date
}
```

## 通知合约

### 1. 通知名称定义

```swift
extension Notification.Name {
    // 主题变化通知
    static let themeDidChange = Notification.Name("ThemeDidChange")
    static let themePreviewStarted = Notification.Name("ThemePreviewStarted")
    static let themePreviewStopped = Notification.Name("ThemePreviewStopped")
    static let effectiveThemeDidChange = Notification.Name("EffectiveThemeDidChange")
    static let themeDidReset = Notification.Name("ThemeDidReset")

    // 系统外观变化通知
    static let systemAppearanceDidChange = Notification.Name("SystemAppearanceDidChange")
    static let systemAppearanceWillChange = Notification.Name("SystemAppearanceWillChange")

    // 性能监控通知
    static let performanceWarning = Notification.Name("PerformanceWarning")
    static let cacheCleared = Notification.Name("CacheCleared")
}
```

### 2. 通知用户信息键

```swift
struct NotificationUserInfoKeys {
    // 主题相关
    static let theme = "theme"
    static let themeId = "themeId"
    static let category = "category"
    static let previousTheme = "previousTheme"
    static let previewTheme = "previewTheme"
    static let effectiveTheme = "effectiveTheme"

    // 模式相关
    static let mode = "mode"
    static let previousMode = "previousMode"
    static let trigger = "trigger"

    // 外观相关
    static let oldAppearance = "oldAppearance"
    static let newAppearance = "newAppearance"
    static let oldIsDarkMode = "oldIsDarkMode"
    static let newIsDarkMode = "newIsDarkMode"
    static let isDarkMode = "isDarkMode"

    // 性能相关
    static let operationName = "operationName"
    static let duration = "duration"
    static let threshold = "threshold"
}
```

## 依赖注入容器

### 1. 服务容器协议

```swift
/// 服务容器协议
protocol ServiceContainer {
    func register<T>(_ type: T.Type, factory: @escaping () -> T)
    func register<T>(_ type: T.Type, instance: T)
    func resolve<T>(_ type: T.Type) -> T?
    func resolve<T>() -> T?
}
```

### 2. 服务容器实现

```swift
/// 服务容器实现
class DefaultServiceContainer: ServiceContainer {
    static let shared = DefaultServiceContainer()

    // MARK: - Properties
    private var services: [String: Any] = [:]
    private var factories: [String: () -> Any] = [:]

    // MARK: - Initialization
    private init() {
        registerDefaultServices()
    }

    // MARK: - Methods Implementation
    func register<T>(_ type: T.Type, factory: @escaping () -> T) {
        let key = String(describing: type)
        factories[key] = factory
    }

    func register<T>(_ type: T.Type, instance: T) {
        let key = String(describing: type)
        services[key] = instance
    }

    func resolve<T>(_ type: T.Type) -> T? {
        let key = String(describing: type)

        // 首先查找已注册的实例
        if let instance = services[key] as? T {
            return instance
        }

        // 然后查找工厂方法
        if let factory = factories[key] {
            let instance = factory() as! T
            services[key] = instance
            return instance
        }

        return nil
    }

    func resolve<T>() -> T? {
        return resolve(T.self)
    }

    // MARK: - Private Methods
    private func registerDefaultServices() {
        // 注册默认服务实现
        register(ThemeCacheProtocol.self, factory: { ThemeCache.shared })
        register(UserPreferencesStorageProtocol.self, factory: { UserPreferencesStorage.shared })
        register(SystemAppearanceMonitorProtocol.self, factory: { SystemAppearanceMonitor.shared })
        register(PerformanceMonitorProtocol.self, factory: { PerformanceMonitor.shared })
        register(EnhancedThemeManagerProtocol.self, factory: { EnhancedThemeManager.shared })
    }
}
```

## 测试支持

### 1. 模拟对象

```swift
/// 模拟主题管理器
class MockEnhancedThemeManager: EnhancedThemeManagerProtocol {
    @Published var currentMode: ThemeMode = .auto
    @Published var lightTheme: ThemeConfiguration = .defaultLight
    @Published var darkTheme: ThemeConfiguration = .defaultDark
    @Published var previewTheme: ThemeConfiguration?
    @Published var availableThemes: [ThemeConfiguration] = []

    var effectiveTheme: ThemeConfiguration { .defaultLight }
    var isPreviewing: Bool { previewTheme != nil }

    // 记录方法调用
    var invokedMethods: [String] = []
    var switchedToMode: ThemeMode?
    var setThemeForCategory: ThemeCategory?
    var startedPreviewTheme: ThemeConfiguration?
    var stoppedPreviewCalled = false

    func loadThemes() {
        invokedMethods.append(#function)
    }

    func switchToMode(_ mode: ThemeMode) {
        invokedMethods.append(#function)
        switchedToMode = mode
        currentMode = mode
    }

    func setTheme(_ theme: ThemeConfiguration, for category: ThemeCategory) {
        invokedMethods.append(#function)
        setThemeForCategory = category

        switch category {
        case .light:
            lightTheme = theme
        case .dark:
            darkTheme = theme
        }
    }

    func startPreview(theme: ThemeConfiguration) {
        invokedMethods.append(#function)
        startedPreviewTheme = theme
        previewTheme = theme
    }

    func stopPreview() {
        invokedMethods.append(#function)
        stoppedPreviewCalled = true
        previewTheme = nil
    }

    func theme(for id: String) -> ThemeConfiguration? {
        invokedMethods.append(#function)
        return availableThemes.first { $0.id == id }
    }

    func themes(for category: ThemeCategory) -> [ThemeConfiguration] {
        invokedMethods.append(#function)
        return availableThemes.filter { $0.category == category }
    }

    func resetToDefaults() {
        invokedMethods.append(#function)
        currentMode = .auto
        lightTheme = .defaultLight
        darkTheme = .defaultDark
        previewTheme = nil
    }

    func validateTheme(_ theme: ThemeConfiguration) -> [ValidationError] {
        invokedMethods.append(#function)
        return []
    }

    func exportTheme(_ theme: ThemeConfiguration) -> Data? {
        invokedMethods.append(#function)
        return try? JSONEncoder().encode(theme)
    }

    func importTheme(from data: Data) -> ThemeConfiguration? {
        invokedMethods.append(#function)
        return try? JSONDecoder().decode(ThemeConfiguration.self, from: data)
    }

    func getThemeStatistics() -> ThemeStatistics {
        invokedMethods.append(#function)
        return ThemeStatistics(
            totalThemes: availableThemes.count,
            lightThemes: themes(for: .light).count,
            darkThemes: themes(for: .dark).count,
            builtinThemes: availableThemes.filter { $0.isBuiltIn }.count,
            customThemes: availableThemes.filter { !$0.isBuiltIn }.count,
            currentMode: currentMode,
            currentTheme: effectiveTheme.id,
            isPreviewing: isPreviewing
        )
    }
}
```

## 总结

本服务接口合约文档定义了增强主题系统的完整服务架构，包括：

1. **核心服务协议**: 定义了主要组件的接口合约
2. **具体实现**: 提供了默认的服务实现
3. **依赖注入**: 支持松耦合的组件集成
4. **通知系统**: 定义了组件间通信的标准化接口
5. **测试支持**: 提供了模拟对象用于单元测试

所有接口都遵循 Swift 最佳实践，支持依赖注入、协议导向编程和响应式架构，为主题系统的实现提供了清晰的合约定义。