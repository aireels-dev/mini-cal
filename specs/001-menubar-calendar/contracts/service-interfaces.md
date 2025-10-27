# Service Interfaces (API Contracts)

**Feature**: 001-menubar-calendar
**Date**: 2025-10-27
**Phase**: 1 - Design & Contracts

## 概述

本文档定义应用内部服务层的接口契约。由于这是单体macOS应用,不涉及REST/GraphQL等网络API,所有接口均为Swift协议(Protocol)定义。

---

## 服务架构

```text
┌─────────────────────────────────────┐
│         View Layer (SwiftUI)        │
└──────────────┬──────────────────────┘
               │ @ObservableObject
               ↓
┌──────────────────────────────────────┐
│      ViewModel Layer (MVVM)          │
│  ├─ MenuBarViewModel                 │
│  ├─ CalendarViewModel                │
│  └─ SettingsViewModel                │
└──────────────┬───────────────────────┘
               │ Protocol Interfaces
               ↓
┌──────────────────────────────────────┐
│         Service Layer                │
│  ├─ CalendarEngine                   │
│  ├─ EventService                     │
│  ├─ ThemeManager                     │
│  └─ SettingsManager                  │
└──────────────┬───────────────────────┘
               │
               ↓
┌──────────────────────────────────────┐
│    Data Layer / System APIs          │
│  ├─ UserDefaults                     │
│  ├─ EventKit                         │
│  └─ Foundation.Calendar              │
└──────────────────────────────────────┘
```

---

## 1. CalendarEngineProtocol

**职责**: 核心日历计算引擎,负责月视图数据生成、副日历转换、节假日查询

### 接口定义

```swift
protocol CalendarEngineProtocol {
    /// 获取指定月份的日历数据
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份 (1-12)
    ///   - secondaryCalendar: 副日历类型 (可选)
    /// - Returns: 月视图所需的所有日期数据 (通常42个单元格)
    func getMonthData(
        year: Int,
        month: Int,
        secondaryCalendar: CalendarType?
    ) -> [CalendarDate]

    /// 获取今天的日期
    /// - Returns: 当前日期的CalendarDate对象
    func getToday() -> CalendarDate

    /// 转换公历日期到副日历
    /// - Parameters:
    ///   - date: 公历日期
    ///   - calendarType: 目标历法类型
    /// - Returns: 副日历信息
    func convertToSecondaryCalendar(
        date: Date,
        calendarType: CalendarType
    ) -> SecondaryDateInfo

    /// 获取指定日期的节假日信息
    /// - Parameter date: 公历日期
    /// - Returns: 节假日事件列表
    func getHolidays(for date: Date) -> [DateEvent]

    /// 获取指定月份的所有节假日
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    /// - Returns: 该月所有节假日事件
    func getMonthHolidays(year: Int, month: Int) -> [DateEvent]
}
```

### 使用示例

```swift
class CalendarViewModel: ObservableObject {
    private let calendarEngine: CalendarEngineProtocol

    @Published var monthData: [CalendarDate] = []

    func loadMonth(year: Int, month: Int) {
        monthData = calendarEngine.getMonthData(
            year: year,
            month: month,
            secondaryCalendar: settings.secondaryCalendarType
        )
    }
}
```

### 实现约束

- **缓存策略**: 实现类应缓存已计算的月份数据,避免重复计算
- **线程安全**: 所有方法必须线程安全,支持并发调用
- **性能要求**: `getMonthData` 必须在 <100ms 内完成 (主线程)

---

## 2. EventServiceProtocol

**职责**: EventKit集成,管理系统日历事件访问

### 接口定义

```swift
protocol EventServiceProtocol {
    /// 请求日历访问权限
    /// - Returns: 是否授权成功
    func requestAuthorization() async -> Bool

    /// 检查当前授权状态
    var authorizationStatus: EKAuthorizationStatus { get }

    /// 获取指定日期的日历事件
    /// - Parameter date: 日期
    /// - Returns: 该日的事件列表
    func fetchEvents(for date: Date) async -> [DateEvent]

    /// 批量获取日期范围的事件
    /// - Parameters:
    ///   - startDate: 开始日期
    ///   - endDate: 结束日期
    /// - Returns: 日期到事件列表的映射
    func fetchEvents(from startDate: Date, to endDate: Date) async -> [Date: [DateEvent]]

    /// 监听日历数据变化
    /// - Parameter handler: 数据变化时的回调
    func observeEventStoreChanges(handler: @escaping () -> Void)
}
```

### 使用示例

```swift
class CalendarViewModel: ObservableObject {
    private let eventService: EventServiceProtocol

    func loadEventsForMonth(year: Int, month: Int) async {
        guard eventService.authorizationStatus == .authorized else {
            return
        }

        let startDate = Date.from(year: year, month: month, day: 1)
        let endDate = startDate.endOfMonth
        let eventsMap = await eventService.fetchEvents(from: startDate, to: endDate)

        // 更新月视图数据
        for date in monthData {
            if let events = eventsMap[date.gregorianDate] {
                date.events.append(contentsOf: events)
            }
        }
    }
}
```

### 实现约束

- **权限处理**: 必须优雅处理权限拒绝情况,不应崩溃或阻塞UI
- **异步执行**: 所有数据获取方法必须为异步 (async/await)
- **内存管理**: 监听器必须使用弱引用避免循环引用

---

## 3. ThemeManagerProtocol

**职责**: 主题管理,支持加载、切换和响应系统外观变化

### 接口定义

```swift
protocol ThemeManagerProtocol: ObservableObject {
    /// 当前激活的主题
    var currentTheme: Theme { get }

    /// 所有可用主题列表
    var availableThemes: [Theme] { get }

    /// 加载主题配置
    /// - Throws: 文件读取或解析错误
    func loadThemes() throws

    /// 应用指定主题
    /// - Parameter theme: 要应用的主题
    func applyTheme(_ theme: Theme)

    /// 根据ID获取主题
    /// - Parameter id: 主题ID
    /// - Returns: 主题对象,不存在则返回nil
    func theme(withId id: String) -> Theme?

    /// 开始监听系统外观变化
    /// - Note: 仅当使用"跟随系统"主题时生效
    func startObservingSystemAppearance()

    /// 停止监听系统外观变化
    func stopObservingSystemAppearance()
}
```

### 使用示例

```swift
class SettingsViewModel: ObservableObject {
    @ObservedObject private var themeManager: ThemeManager

    func selectTheme(id: String) {
        guard let theme = themeManager.theme(withId: id) else {
            return
        }
        themeManager.applyTheme(theme)

        if theme.isSystemTheme {
            themeManager.startObservingSystemAppearance()
        } else {
            themeManager.stopObservingSystemAppearance()
        }
    }
}
```

### 实现约束

- **主题切换性能**: `applyTheme` 必须在 <200ms 完成
- **系统监听**: 外观变化应通过 `@Published` 自动触发UI更新
- **资源管理**: 主题JSON文件加载失败时提供默认主题

---

## 4. SettingsManagerProtocol

**职责**: 用户设置的持久化和管理

### 接口定义

```swift
protocol SettingsManagerProtocol: ObservableObject {
    /// 当前用户设置
    var settings: UserSettings { get set }

    /// 加载设置
    /// - Returns: 加载的设置,失败则返回默认值
    func load() -> UserSettings

    /// 保存设置
    /// - Parameter settings: 要保存的设置
    /// - Throws: 持久化错误
    func save(_ settings: UserSettings) throws

    /// 重置为默认设置
    func resetToDefault()

    /// 导出设置 (未来扩展)
    /// - Returns: 设置JSON字符串
    func exportSettings() -> String

    /// 导入设置 (未来扩展)
    /// - Parameter json: 设置JSON字符串
    /// - Throws: 解析或验证错误
    func importSettings(from json: String) throws
}
```

### 使用示例

```swift
class SettingsViewModel: ObservableObject {
    private let settingsManager: SettingsManagerProtocol

    func updateMenuBarFormat(_ format: MenuBarFormat) {
        var newSettings = settingsManager.settings
        newSettings.menuBarFormat = format
        newSettings.lastUpdated = Date()

        do {
            try settingsManager.save(newSettings)
            settingsManager.settings = newSettings
        } catch {
            // 显示错误提示
        }
    }
}
```

### 实现约束

- **自动保存**: 设置修改后应立即持久化,避免数据丢失
- **验证**: `save` 方法必须验证设置合法性
- **默认值**: `load` 失败时必须返回 `UserSettings.default`

---

## 5. HolidayProviderProtocol

**职责**: 节假日数据提供,支持多地区节假日查询

### 接口定义

```swift
protocol HolidayProviderProtocol {
    /// 加载节假日数据
    /// - Throws: 文件读取或解析错误
    func loadHolidayData() throws

    /// 获取指定日期的节假日
    /// - Parameters:
    ///   - date: 日期
    ///   - region: 地区代码 (如"CN", "US")
    /// - Returns: 节假日事件列表
    func getHolidays(for date: Date, region: String) -> [DateEvent]

    /// 获取月份的所有节假日
    /// - Parameters:
    ///   - year: 年份
    ///   - month: 月份
    ///   - region: 地区代码
    /// - Returns: 该月所有节假日
    func getMonthHolidays(year: Int, month: Int, region: String) -> [DateEvent]

    /// 检查数据版本是否过期
    /// - Returns: 是否需要更新
    func isDataOutdated() -> Bool

    /// 获取数据版本信息
    var dataVersion: String { get }
}
```

### 数据格式 (JSON Schema)

```json
{
  "type": "object",
  "properties": {
    "version": { "type": "string" },
    "lastUpdated": { "type": "string", "format": "date" },
    "regions": {
      "type": "object",
      "patternProperties": {
        "^[A-Z]{2}$": {
          "type": "object",
          "properties": {
            "name": { "type": "string" },
            "holidays": {
              "type": "array",
              "items": {
                "type": "object",
                "properties": {
                  "date": { "type": "string", "format": "date" },
                  "name": { "type": "string" },
                  "type": { "enum": ["public_holiday", "traditional_festival", "observance"] }
                },
                "required": ["date", "name", "type"]
              }
            }
          },
          "required": ["name", "holidays"]
        }
      }
    }
  },
  "required": ["version", "regions"]
}
```

### 使用示例

```swift
class CalendarEngine: CalendarEngineProtocol {
    private let holidayProvider: HolidayProviderProtocol

    func getMonthData(year: Int, month: Int, secondaryCalendar: CalendarType?) -> [CalendarDate] {
        let dates = generateMonthDates(year: year, month: month)
        let region = getCurrentRegion() // 从系统获取

        // 批量加载月份节假日
        let holidays = holidayProvider.getMonthHolidays(year: year, month: month, region: region)

        // 将节假日分配到对应日期
        for date in dates {
            date.events.append(contentsOf: holidays.filter { $0.date == date.gregorianDate })
        }

        return dates
    }
}
```

### 实现约束

- **性能**: `getMonthHolidays` 必须在 <50ms 完成 (查询+过滤)
- **缓存**: 已加载的节假日数据应缓存在内存,避免重复文件IO
- **地区检测**: 自动根据系统地区设置选择默认地区

---

## 6. SecondaryCalendarConverterProtocol

**职责**: 副日历转换算法实现

### 接口定义

```swift
protocol SecondaryCalendarConverterProtocol {
    /// 转换公历日期到副日历
    /// - Parameters:
    ///   - gregorianDate: 公历日期
    ///   - calendarType: 目标历法类型
    /// - Returns: 副日历信息
    func convert(gregorianDate: Date, to calendarType: CalendarType) -> SecondaryDateInfo

    /// 批量转换 (性能优化)
    /// - Parameters:
    ///   - dates: 公历日期数组
    ///   - calendarType: 目标历法类型
    /// - Returns: 日期到副日历信息的映射
    func batchConvert(dates: [Date], to calendarType: CalendarType) -> [Date: SecondaryDateInfo]

    /// 获取副日历节日名称
    /// - Parameters:
    ///   - secondaryDate: 副日历日期信息
    ///   - calendarType: 历法类型
    /// - Returns: 节日名称 (如果该日是节日)
    func getFestivalName(for secondaryDate: SecondaryDateInfo, calendarType: CalendarType) -> String?
}
```

### 使用示例

```swift
class CalendarEngine: CalendarEngineProtocol {
    private let converter: SecondaryCalendarConverterProtocol

    func getMonthData(year: Int, month: Int, secondaryCalendar: CalendarType?) -> [CalendarDate] {
        let dates = generateMonthDates(year: year, month: month)

        guard let secondaryType = secondaryCalendar else {
            return dates
        }

        // 批量转换提升性能
        let gregorianDates = dates.map { $0.gregorianDate }
        let converted = converter.batchConvert(dates: gregorianDates, to: secondaryType)

        for date in dates {
            date.secondaryDate = converted[date.gregorianDate]
        }

        return dates
    }
}
```

### 实现约束

- **精度**: 转换精度必须与Foundation.Calendar一致
- **性能**: 单次转换 <5ms, 批量转换42个日期 <30ms
- **节日判断**: 农历节日(如春节、端午)必须准确识别

---

## 错误处理

### 定义统一错误类型

```swift
enum MiniCalError: LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case authorizationDenied
    case dataCorrupted
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
        case .invalidJSON(let reason):
            return "JSON解析失败: \(reason)"
        case .authorizationDenied:
            return "日历访问权限被拒绝"
        case .dataCorrupted:
            return "数据损坏,请重新安装应用"
        case .networkUnavailable:
            return "网络不可用"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}
```

---

## 依赖注入模式

推荐使用构造函数注入,便于测试:

```swift
class CalendarViewModel: ObservableObject {
    private let calendarEngine: CalendarEngineProtocol
    private let eventService: EventServiceProtocol
    private let themeManager: ThemeManagerProtocol

    init(
        calendarEngine: CalendarEngineProtocol,
        eventService: EventServiceProtocol,
        themeManager: ThemeManagerProtocol
    ) {
        self.calendarEngine = calendarEngine
        self.eventService = eventService
        self.themeManager = themeManager
    }
}

// 在App入口创建依赖
@main
struct MiniCalApp: App {
    private let calendarEngine = CalendarEngine()
    private let eventService = EventService()
    private let themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(
                    CalendarViewModel(
                        calendarEngine: calendarEngine,
                        eventService: eventService,
                        themeManager: themeManager
                    )
                )
        }
    }
}
```

---

## 测试契约

每个服务必须提供Mock实现用于单元测试:

```swift
// 示例: CalendarEngine的Mock
class MockCalendarEngine: CalendarEngineProtocol {
    var mockMonthData: [CalendarDate] = []

    func getMonthData(year: Int, month: Int, secondaryCalendar: CalendarType?) -> [CalendarDate] {
        return mockMonthData
    }

    // 其他方法的Mock实现...
}
```

---

## 下一步

服务接口定义完成,准备生成快速入门文档。