# Enhanced Theme System - 数据模型

**版本**: 1.0
**日期**: 2025-10-30
**特性**: 002-Enhanced Theme System

## 概述

本文档定义了增强主题系统的核心数据模型，包括主题配置、用户偏好设置和系统状态管理。数据模型遵循 Swift 5.9+ 最佳实践，支持 Codable 协议用于持久化存储，以及 ObservableObject 协议用于 SwiftUI 响应式更新。

## 核心数据模型

### 1. 主题模式枚举

```swift
/// 主题模式枚举
enum ThemeMode: String, CaseIterable, Codable {
    case light = "light"     // 强制浅色模式
    case dark = "dark"       // 强制深色模式
    case auto = "auto"       // 跟随系统外观

    /// 显示名称
    var displayName: String {
        switch self {
        case .light: return "浅色"
        case .dark: return "深色"
        case .auto: return "自动"
        }
    }

    /// 本地化显示名称
    var localizedDisplayName: String {
        NSLocalizedString("theme.mode.\(rawValue)", comment: "")
    }

    /// 系统图标名称
    var systemImageName: String {
        switch self {
        case .light: return "sun.max"
        case .dark: return "moon"
        case .auto: return "circle.lefthalf.filled"
        }
    }
}
```

### 2. 主题分类枚举

```swift
/// 主题分类
enum ThemeCategory: String, CaseIterable, Codable {
    case light = "light"     // 浅色主题
    case dark = "dark"       // 深色主题

    /// 显示名称
    var displayName: String {
        switch self {
        case .light: return "浅色主题"
        case .dark: return "深色主题"
        }
    }

    /// 默认主题ID列表
    static var defaultThemes: [String] {
        switch self {
        case .light:
            return ["classic_blue", "fresh_green", "sunset_orange", "graphite_gray"]
        case .dark:
            return ["midnight_blue", "forest_green", "ruby_red", "obsidian_black"]
        }
    }
}
```

### 3. 颜色配置结构

```swift
/// 主题颜色配置
struct ColorSet: Codable, Hashable {
    let main: String           // 主要颜色
    let light: String?         // 浅色模式变体
    let dark: String?          // 深色模式变体

    /// 创建标准颜色配置
    init(main: String, light: String? = nil, dark: String? = nil) {
        self.main = main
        self.light = light
        self.dark = dark
    }

    /// 验证颜色格式
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        if !ColorSet.isValidHex(main) {
            errors.append(ValidationError(field: "main", message: "主要颜色格式无效"))
        }

        if let light = light, !ColorSet.isValidHex(light) {
            errors.append(ValidationError(field: "light", message: "浅色变体格式无效"))
        }

        if let dark = dark, !ColorSet.isValidHex(dark) {
            errors.append(ValidationError(field: "dark", message: "深色变体格式无效"))
        }

        return errors
    }

    /// 检查HEX颜色格式是否有效
    private static func isValidHex(_ hex: String) -> Bool {
        let regex = "^#([A-Fa-f0-9]{6}|[A-Fa-f0-9]{3})$"
        return NSPredicate(format: "SELF MATCHES %@", regex).evaluate(with: hex)
    }
}
```

### 4. 主题配置结构

```swift
/// 主题配置
struct ThemeConfiguration: Codable, Identifiable, Hashable {
    let id: String                     // 唯一标识符
    let name: String                   // 主题名称
    let displayName: String?           // 显示名称（可选，默认使用name）
    let category: ThemeCategory        // 主题分类
    let author: String?                // 作者（可选）
    let version: String                // 版本号
    let description: String?           // 描述（可选）
    let colors: ThemeColors            // 颜色配置
    let metadata: ThemeMetadata?       // 元数据（可选）
    let isBuiltIn: Bool                // 是否为内置主题
    let isEnabled: Bool                // 是否启用
    let previewColors: [String]        // 预览颜色数组

    /// 主题颜色配置
    struct ThemeColors: Codable, Hashable {
        let primary: ColorSet          // 主要颜色
        let secondary: ColorSet        // 次要颜色
        let background: ColorSet       // 背景颜色
        let surface: ColorSet          // 表面颜色
        let text: ColorSet             // 文本颜色
        let textSecondary: ColorSet    // 次要文本颜色
        let accent: ColorSet           // 强调色
        let border: ColorSet           // 边框颜色
        let shadow: ColorSet           // 阴影颜色
        let error: ColorSet            // 错误颜色
        let warning: ColorSet          // 警告颜色
        let success: ColorSet          // 成功颜色
    }

    /// 主题元数据
    struct ThemeMetadata: Codable, Hashable {
        let createdAt: Date            // 创建时间
        let updatedAt: Date            // 更新时间
        let downloadCount: Int         // 下载次数
        let rating: Double             // 评分（0-5）
        let tags: [String]             // 标签
        let compatibility: String      // 兼容性版本
        let minimumMacOSVersion: String // 最低macOS版本
        let fileURL: String?           // 文件URL（可选）
    }

    /// 计算属性：显示名称
    var computedDisplayName: String {
        return displayName ?? name
    }

    /// 验证主题配置
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        // 验证ID
        if id.isEmpty {
            errors.append(ValidationError(field: "id", message: "主题ID不能为空"))
        }

        // 验证名称
        if name.isEmpty {
            errors.append(ValidationError(field: "name", message: "主题名称不能为空"))
        }

        // 验证版本
        if version.isEmpty {
            errors.append(ValidationError(field: "version", message: "版本号不能为空"))
        }

        // 验证颜色配置
        errors.append(contentsOf: colors.primary.validate())
        errors.append(contentsOf: colors.secondary.validate())
        errors.append(contentsOf: colors.background.validate())
        errors.append(contentsOf: colors.surface.validate())
        errors.append(contentsOf: colors.text.validate())
        errors.append(contentsOf: colors.textSecondary.validate())
        errors.append(contentsOf: colors.accent.validate())
        errors.append(contentsOf: colors.border.validate())
        errors.append(contentsOf: colors.shadow.validate())
        errors.append(contentsOf: colors.error.validate())
        errors.append(contentsOf: colors.warning.validate())
        errors.append(contentsOf: colors.success.validate())

        return errors
    }

    /// 获取主题预览数据
    func previewData() -> ThemePreviewData {
        return ThemePreviewData(
            id: id,
            name: computedDisplayName,
            category: category,
            previewColors: previewColors,
            isEnabled: isEnabled,
            isBuiltIn: isBuiltIn
        )
    }
}

/// 主题预览数据
struct ThemePreviewData: Codable, Identifiable, Hashable {
    let id: String
    let name: String
    let category: ThemeCategory
    let previewColors: [String]
    let isEnabled: Bool
    let isBuiltIn: Bool
}
```

### 5. 用户主题偏好设置

```swift
/// 用户主题偏好设置
struct UserThemePreferences: Codable {
    var mode: ThemeMode = .auto                                // 主题模式
    var lightThemeId: String = "classic_blue"                  // 浅色主题ID
    var darkThemeId: String = "midnight_blue"                  // 深色主题ID
    var enableRealTimePreview: Bool = true                     // 启用实时预览
    var enableSmoothTransitions: Bool = true                   // 启用平滑过渡
    var transitionDuration: Double = 0.3                       // 过渡动画时长
    var enableAutoSwitch: Bool = true                          // 启用自动切换
    var customSettings: [String: String] = [:]                 // 自定义设置
    var lastUsedVersion: String = "1.0"                        // 最后使用版本
    var installationDate: Date = Date()                        // 安装日期
    var usageStatistics: UsageStatistics = UsageStatistics()   // 使用统计

    /// 使用统计
    struct UsageStatistics: Codable {
        var totalThemeSwitches: Int = 0           // 总主题切换次数
        var lightModeUsage: TimeInterval = 0      // 浅色模式使用时长
        var darkModeUsage: TimeInterval = 0       // 深色模式使用时长
        var lastModeChange: Date?                 // 最后模式切换时间
        var favoriteThemes: [String] = []         // 收藏主题
        var previewSessions: Int = 0              // 预览会话数
        var customThemesCreated: Int = 0          // 创建的自定义主题数

        /// 记录主题切换
        mutating func recordThemeSwitch(from: ThemeMode?, to: ThemeMode) {
            totalThemeSwitches += 1
            lastModeChange = Date()
        }

        /// 记录模式使用时长
        mutating func recordModeUsage(_ mode: ThemeMode, duration: TimeInterval) {
            switch mode {
            case .light, .auto:
                lightModeUsage += duration
            case .dark:
                darkModeUsage += duration
            }
        }

        /// 添加收藏主题
        mutating func addToFavorites(_ themeId: String) {
            if !favoriteThemes.contains(themeId) {
                favoriteThemes.append(themeId)
            }
        }

        /// 移除收藏主题
        mutating func removeFromFavorites(_ themeId: String) {
            favoriteThemes.removeAll { $0 == themeId }
        }
    }

    /// 验证偏好设置
    func validate() -> [ValidationError] {
        var errors: [ValidationError] = []

        if lightThemeId.isEmpty {
            errors.append(ValidationError(field: "lightThemeId", message: "浅色主题ID不能为空"))
        }

        if darkThemeId.isEmpty {
            errors.append(ValidationError(field: "darkThemeId", message: "深色主题ID不能为空"))
        }

        if transitionDuration < 0.0 || transitionDuration > 2.0 {
            errors.append(ValidationError(field: "transitionDuration", message: "过渡时长必须在0-2秒之间"))
        }

        return errors
    }

    /// 重置为默认设置
    mutating func resetToDefaults() {
        mode = .auto
        lightThemeId = "classic_blue"
        darkThemeId = "midnight_blue"
        enableRealTimePreview = true
        enableSmoothTransitions = true
        transitionDuration = 0.3
        enableAutoSwitch = true
        customSettings = [:]
        lastUsedVersion = "1.0"
        usageStatistics = UsageStatistics()
    }
}
```

### 6. 主题缓存条目

```swift
/// 主题缓存条目
struct ThemeCacheEntry: Codable {
    let themeId: String                    // 主题ID
    let cacheKey: String                   // 缓存键
    let data: Data                         // 缓存数据
    let createdAt: Date                    // 创建时间
    let lastAccessed: Date                 // 最后访问时间
    let accessCount: Int                   // 访问次数
    let size: Int                          // 数据大小（字节）

    /// 是否过期
    var isExpired: Bool {
        let expirationInterval: TimeInterval = 7 * 24 * 60 * 60 // 7天
        return Date().timeIntervalSince(lastAccessed) > expirationInterval
    }

    /// 更新访问信息
    mutating func updateAccessInfo() {
        lastAccessed = Date()
        accessCount += 1
    }
}
```

### 7. 主题性能指标

```swift
/// 主题性能指标
struct ThemePerformanceMetrics: Codable {
    let themeId: String                    // 主题ID
    let loadTime: TimeInterval             // 加载时间
    let switchTime: TimeInterval           // 切换时间
    let memoryUsage: Int64                 // 内存使用量（字节）
    let cpuUsage: Double                   // CPU使用率（百分比）
    let timestamp: Date                    // 记录时间
    let deviceInfo: DeviceInfo             // 设备信息

    /// 设备信息
    struct DeviceInfo: Codable {
        let macOSVersion: String           // macOS版本
        let deviceModel: String            // 设备型号
        let processorCount: Int            // 处理器数量
        let memorySize: Int64              // 内存大小
        let isRetinaDisplay: Bool          // 是否为Retina显示器
    }

    /// 是否性能良好
    var isPerformanceGood: Bool {
        return loadTime < 0.2 && switchTime < 0.1 && memoryUsage < 50 * 1024 * 1024 // 50MB
    }
}
```

### 8. 主题更新信息

```swift
/// 主题更新信息
struct ThemeUpdateInfo: Codable {
    let themeId: String                    // 主题ID
    let currentVersion: String             // 当前版本
    let availableVersion: String?          // 可用版本
    let updateDescription: String?         // 更新描述
    let isRequired: Bool                   // 是否必需更新
    let releaseDate: Date?                 // 发布日期
    let downloadURL: String?               // 下载URL
    let size: Int64?                       // 更新包大小

    /// 是否有可用更新
    var hasUpdate: Bool {
        guard let availableVersion = availableVersion else { return false }
        return currentVersion != availableVersion
    }

    /// 更新严重程度
    var updateSeverity: UpdateSeverity {
        guard hasUpdate else { return .none }

        if isRequired {
            return .critical
        } else if let releaseDate = releaseDate {
            let daysSinceRelease = Date().timeIntervalSince(releaseDate) / (24 * 60 * 60)
            if daysSinceRelease > 30 {
                return .recommended
            } else {
                return .optional
            }
        } else {
            return .optional
        }
    }

    /// 更新严重程度枚举
    enum UpdateSeverity: String, Codable {
        case none = "none"              // 无更新
        case optional = "optional"      // 可选更新
        case recommended = "recommended" // 推荐更新
        case critical = "critical"      // 关键更新
    }
}
```

### 9. 主题导入/导出配置

```swift
/// 主题导入/导出配置
struct ThemeExportConfiguration: Codable {
    let themeIds: [String]               // 要导出的主题ID列表
    let includeMetadata: Bool             // 是否包含元数据
    let includeUsageStats: Bool           // 是否包含使用统计
    let compressionEnabled: Bool          // 是否启用压缩
    let encryptionEnabled: Bool           // 是否启用加密
    let exportFormat: ExportFormat        // 导出格式
    let version: String                   // 导出格式版本

    /// 导出格式
    enum ExportFormat: String, CaseIterable, Codable {
        case json = "json"               // JSON格式
        case plist = "plist"             // Property List格式
        case minicalTheme = "mct"        // MiniCal主题格式
    }
}

/// 主题导入配置
struct ThemeImportConfiguration: Codable {
    let allowOverride: Bool               // 允许覆盖现有主题
    let validateBeforeImport: Bool        // 导入前验证
    let backupExisting: Bool              // 备份现有主题
    let importMode: ImportMode            // 导入模式
    let targetCategory: ThemeCategory?    // 目标分类（可选）

    /// 导入模式
    enum ImportMode: String, CaseIterable, Codable {
        case addNew = "add_new"           // 仅添加新主题
        case updateExisting = "update_existing" // 仅更新现有主题
        case both = "both"                // 同时添加和更新
    }
}
```

### 10. 验证错误模型

```swift
/// 验证错误
struct ValidationError: Codable, Hashable, Error {
    let field: String                     // 字段名
    let message: String                   // 错误消息
    let code: String?                     // 错误代码（可选）
    let severity: Severity                // 严重程度

    /// 错误严重程度
    enum Severity: String, CaseIterable, Codable {
        case info = "info"                // 信息
        case warning = "warning"          // 警告
        case error = "error"              // 错误
        case critical = "critical"        // 严重错误
    }

    /// 本地化错误消息
    var localizedMessage: String {
        NSLocalizedString(message, comment: "")
    }
}

/// 主题验证结果
struct ThemeValidationResult: Codable {
    let isValid: Bool                     // 是否有效
    let errors: [ValidationError]         // 错误列表
    let warnings: [ValidationError]       // 警告列表
    let info: [ValidationError]           // 信息列表

    /// 所有问题
    var allIssues: [ValidationError] {
        return errors + warnings + info
    }

    /// 是否有错误
    var hasErrors: Bool {
        return !errors.isEmpty
    }

    /// 是否有警告
    var hasWarnings: Bool {
        return !warnings.isEmpty
    }
}
```

## 默认数据配置

### 1. 内置主题定义

```swift
extension ThemeConfiguration {
    /// 默认浅色主题
    static let defaultLight = ThemeConfiguration(
        id: "classic_blue",
        name: "Classic Blue",
        displayName: "经典蓝",
        category: .light,
        author: "MiniCal Team",
        version: "1.0.0",
        description: "经典的蓝色主题，适合日常使用",
        colors: ThemeColors(
            primary: ColorSet(main: "#4285F4"),
            secondary: ColorSet(main: "#87CEEB"),
            background: ColorSet(main: "#FFFFFF"),
            surface: ColorSet(main: "#F8F9FA"),
            text: ColorSet(main: "#202124"),
            textSecondary: ColorSet(main: "#5F6368"),
            accent: ColorSet(main: "#34A853"),
            border: ColorSet(main: "#DADCE0"),
            shadow: ColorSet(main: "#000000"),
            error: ColorSet(main: "#EA4335"),
            warning: ColorSet(main: "#FBBC04"),
            success: ColorSet(main: "#34A853")
        ),
        metadata: ThemeMetadata(
            createdAt: Date(),
            updatedAt: Date(),
            downloadCount: 0,
            rating: 4.5,
            tags: ["classic", "blue", "light"],
            compatibility: "1.0",
            minimumMacOSVersion: "10.15",
            fileURL: nil
        ),
        isBuiltIn: true,
        isEnabled: true,
        previewColors: ["#4285F4", "#87CEEB", "#FFFFFF", "#F8F9FA", "#202124"]
    )

    /// 默认深色主题
    static let defaultDark = ThemeConfiguration(
        id: "midnight_blue",
        name: "Midnight Blue",
        displayName: "深夜蓝",
        category: .dark,
        author: "MiniCal Team",
        version: "1.0.0",
        description: "深邃的午夜蓝色主题，保护眼睛",
        colors: ThemeColors(
            primary: ColorSet(main: "#8AB4F8"),
            secondary: ColorSet(main: "#5F6368"),
            background: ColorSet(main: "#202124"),
            surface: ColorSet(main: "#292A2D"),
            text: ColorSet(main: "#E8EAED"),
            textSecondary: ColorSet(main: "#9AA0A6"),
            accent: ColorSet(main: "#FDD663"),
            border: ColorSet(main: "#5F6368"),
            shadow: ColorSet(main: "#000000"),
            error: ColorSet(main: "#F28B82"),
            warning: ColorSet(main: "#FDD663"),
            success: ColorSet(main: "#81C995")
        ),
        metadata: ThemeMetadata(
            createdAt: Date(),
            updatedAt: Date(),
            downloadCount: 0,
            rating: 4.7,
            tags: ["dark", "blue", "night"],
            compatibility: "1.0",
            minimumMacOSVersion: "10.15",
            fileURL: nil
        ),
        isBuiltIn: true,
        isEnabled: true,
        previewColors: ["#8AB4F8", "#5F6368", "#202124", "#292A2D", "#E8EAED"]
    )

    /// 获取所有内置主题
    static var builtInThemes: [ThemeConfiguration] {
        return [
            defaultLight,
            defaultDark,
            // 其他内置主题...
        ]
    }
}
```

### 2. 示例数据生成

```swift
extension ThemeConfiguration {
    /// 生成示例主题
    static func sampleTheme(category: ThemeCategory) -> ThemeConfiguration {
        return ThemeConfiguration(
            id: "sample_\(category.rawValue)_\(UUID().uuidString)",
            name: "Sample Theme",
            category: category,
            author: "Sample Author",
            version: "1.0.0",
            description: "This is a sample theme for testing purposes",
            colors: ThemeColors(
                primary: ColorSet(main: "#007AFF"),
                secondary: ColorSet(main: "#5856D6"),
                background: ColorSet(main: category == .light ? "#FFFFFF" : "#000000"),
                surface: ColorSet(main: category == .light ? "#F2F2F7" : "#1C1C1E"),
                text: ColorSet(main: category == .light ? "#000000" : "#FFFFFF"),
                textSecondary: ColorSet(main: category == .light ? "#3C3C43" : "#EBEBF5"),
                accent: ColorSet(main: "#FF9500"),
                border: ColorSet(main: category == .light ? "#C6C6C8" : "#38383A"),
                shadow: ColorSet(main: "#000000"),
                error: ColorSet(main: "#FF3B30"),
                warning: ColorSet(main: "#FF9500"),
                success: ColorSet(main: "#34C759")
            ),
            metadata: ThemeMetadata(
                createdAt: Date(),
                updatedAt: Date(),
                downloadCount: 100,
                rating: 4.0,
                tags: ["sample", "test"],
                compatibility: "1.0",
                minimumMacOSVersion: "10.15",
                fileURL: nil
            ),
            isBuiltIn: false,
            isEnabled: true,
            previewColors: ["#007AFF", "#5856D6", "#FFFFFF", "#F2F2F7", "#000000"]
        )
    }
}
```

## 数据持久化

### 1. 存储键定义

```swift
struct ThemeStorageKeys {
    static let userPreferences = "com.minical.theme.preferences"
    static let cachedThemes = "com.minical.theme.cached_themes"
    static let themeCache = "com.minical.theme.cache"
    static let performanceMetrics = "com.minical.theme.performance_metrics"
    static let updateInfo = "com.minical.theme.update_info"
    static let customThemes = "com.minical.theme.custom_themes"
    static let version = "com.minical.theme.version"
}
```

### 2. 迁移支持

```swift
/// 主题数据迁移管理器
struct ThemeDataMigration {
    /// 当前数据版本
    static let currentVersion = "1.0"

    /// 执行迁移
    static func performMigration() {
        let storedVersion = UserDefaults.standard.string(forKey: ThemeStorageKeys.version) ?? "0.0"

        if storedVersion != currentVersion {
            migrate(from: storedVersion, to: currentVersion)
            UserDefaults.standard.set(currentVersion, forKey: ThemeStorageKeys.version)
        }
    }

    /// 从旧版本迁移到新版本
    private static func migrate(from oldVersion: String, to newVersion: String) {
        print("Migrating theme data from version \(oldVersion) to \(newVersion)")

        // 根据版本执行不同的迁移逻辑
        switch (oldVersion, newVersion) {
        case ("0.0", "1.0"):
            // 初始安装，无需迁移
            break
        default:
            // 未知版本迁移
            resetToDefaults()
        }
    }

    /// 重置为默认设置
    private static func resetToDefaults() {
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.userPreferences)
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.cachedThemes)
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.themeCache)
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.performanceMetrics)
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.updateInfo)
        UserDefaults.standard.removeObject(forKey: ThemeStorageKeys.customThemes)
    }
}
```

## 总结

本数据模型文档定义了增强主题系统的完整数据结构，包括：

1. **核心枚举类型**: ThemeMode、ThemeCategory
2. **主要配置结构**: ThemeConfiguration、ColorSet、UserThemePreferences
3. **辅助数据结构**: 主题缓存、性能指标、更新信息
4. **验证和错误处理**: ValidationError、ThemeValidationResult
5. **持久化支持**: 存储键、数据迁移

所有数据模型都遵循 Swift 最佳实践，支持 Codable 协议用于序列化，ObservableObject 协议用于 SwiftUI 响应式更新，以及 Hashable 协议用于集合操作。这为主题系统的实现提供了坚实的数据基础。