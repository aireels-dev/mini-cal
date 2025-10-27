# Data Model: MacOS菜单栏日历应用

**Feature**: 001-menubar-calendar
**Date**: 2025-10-27
**Phase**: 1 - Design & Contracts

## 概述

本文档定义应用的核心数据模型,所有模型遵循Swift的`Codable`协议以支持序列化和持久化。

---

## 核心实体

### 1. CalendarDate

**描述**: 表示日历中的单个日期,包含公历日期和副日历信息

**字段**:

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `gregorianDate` | `Date` | ✅ | 公历日期 (Foundation.Date) |
| `year` | `Int` | ✅ | 年份 |
| `month` | `Int` | ✅ | 月份 (1-12) |
| `day` | `Int` | ✅ | 日期 (1-31) |
| `weekday` | `Int` | ✅ | 星期 (1=周日, 7=周六) |
| `secondaryDate` | `SecondaryDateInfo?` | ❌ | 副日历信息 (可选) |
| `isToday` | `Bool` | ✅ | 是否为今天 |
| `isCurrentMonth` | `Bool` | ✅ | 是否属于当前显示月份 |
| `events` | `[DateEvent]` | ✅ | 当天的事件列表 |

**关系**:
- 包含 0-1 个 `SecondaryDateInfo`
- 包含 0-n 个 `DateEvent`

**验证规则**:
- `month` 范围: 1-12
- `day` 范围: 1-31 (根据月份动态验证)
- `weekday` 范围: 1-7

**Swift实现**:
```swift
struct CalendarDate: Identifiable, Codable {
    let id: UUID
    let gregorianDate: Date
    let year: Int
    let month: Int
    let day: Int
    let weekday: Int
    var secondaryDate: SecondaryDateInfo?
    var isToday: Bool
    var isCurrentMonth: Bool
    var events: [DateEvent]

    init(date: Date, isCurrentMonth: Bool = true) {
        self.id = UUID()
        self.gregorianDate = date
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .weekday], from: date)
        self.year = components.year!
        self.month = components.month!
        self.day = components.day!
        self.weekday = components.weekday!
        self.isToday = calendar.isDateInToday(date)
        self.isCurrentMonth = isCurrentMonth
        self.events = []
    }
}
```

---

### 2. SecondaryDateInfo

**描述**: 副日历日期信息

**字段**:

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `calendarType` | `CalendarType` | ✅ | 历法类型 |
| `displayText` | `String` | ✅ | 显示文本 (如"初一", "Muharram 15") |
| `year` | `Int?` | ❌ | 副日历年份 (可选,部分历法不显示年) |
| `month` | `Int?` | ❌ | 副日历月份 |
| `day` | `Int?` | ❌ | 副日历日 |
| `festival` | `String?` | ❌ | 节日名称 (如"春节", "Eid al-Fitr") |

**Swift实现**:
```swift
struct SecondaryDateInfo: Codable, Equatable {
    let calendarType: CalendarType
    let displayText: String
    let year: Int?
    let month: Int?
    let day: Int?
    let festival: String?
}
```

---

### 3. CalendarType

**描述**: 历法类型枚举

**值**:

| 枚举值 | Foundation标识符 | 显示名称 | 说明 |
|--------|----------------|---------|------|
| `.gregorian` | `.gregorian` | 公历 | Gregorian calendar |
| `.chinese` | `.chinese` | 中国农历 | Chinese lunar calendar |
| `.islamic` | `.islamic` | 伊斯兰历 | Islamic (Hijri) calendar |
| `.hebrew` | `.hebrew` | 希伯来历 | Hebrew calendar |
| `.persian` | `.persian` | 波斯历 | Persian calendar |
| `.japanese` | `.japanese` | 日本和历 | Japanese calendar |
| `.buddhist` | - | 佛历 | Buddhist calendar (自定义实现) |

**Swift实现**:
```swift
enum CalendarType: String, Codable, CaseIterable {
    case gregorian
    case chinese
    case islamic
    case hebrew
    case persian
    case japanese
    case buddhist

    var identifier: Calendar.Identifier? {
        switch self {
        case .gregorian: return .gregorian
        case .chinese: return .chinese
        case .islamic: return .islamic
        case .hebrew: return .hebrew
        case .persian: return .persian
        case .japanese: return .japanese
        case .buddhist: return nil // 自定义实现
        }
    }

    var displayName: String {
        switch self {
        case .gregorian: return "公历"
        case .chinese: return "农历"
        case .islamic: return "伊斯兰历"
        case .hebrew: return "希伯来历"
        case .persian: return "波斯历"
        case .japanese: return "和历"
        case .buddhist: return "佛历"
        }
    }
}
```

---

### 4. DateEvent

**描述**: 日期事件 (节假日、会议、节日等)

**字段**:

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `id` | `UUID` | ✅ | 唯一标识符 |
| `title` | `String` | ✅ | 事件标题 |
| `date` | `Date` | ✅ | 事件日期 |
| `type` | `EventType` | ✅ | 事件类型 |
| `color` | `EventColor` | ✅ | 圆点颜色 |
| `description` | `String?` | ❌ | 详细描述 |
| `source` | `EventSource` | ✅ | 事件来源 |

**关系**:
- 属于一个 `CalendarDate`

**Swift实现**:
```swift
struct DateEvent: Identifiable, Codable, Equatable {
    let id: UUID
    let title: String
    let date: Date
    let type: EventType
    let color: EventColor
    let description: String?
    let source: EventSource

    init(title: String, date: Date, type: EventType, source: EventSource, description: String? = nil) {
        self.id = UUID()
        self.title = title
        self.date = date
        self.type = type
        self.color = type.defaultColor
        self.description = description
        self.source = source
    }
}
```

---

### 5. EventType

**描述**: 事件类型枚举

**值**:

| 枚举值 | 显示名称 | 默认颜色 | 说明 |
|--------|---------|---------|------|
| `.publicHoliday` | 公共假期 | 红色 | 法定节假日 |
| `.festival` | 节日 | 橙色 | 传统节日 (非假期) |
| `.meeting` | 会议 | 蓝色 | EventKit中的日历事件 |
| `.birthday` | 生日 | 紫色 | 生日提醒 |
| `.custom` | 自定义 | 绿色 | 用户自定义事件 |

**Swift实现**:
```swift
enum EventType: String, Codable {
    case publicHoliday
    case festival
    case meeting
    case birthday
    case custom

    var displayName: String {
        switch self {
        case .publicHoliday: return "公共假期"
        case .festival: return "节日"
        case .meeting: return "会议"
        case .birthday: return "生日"
        case .custom: return "自定义"
        }
    }

    var defaultColor: EventColor {
        switch self {
        case .publicHoliday: return .red
        case .festival: return .orange
        case .meeting: return .blue
        case .birthday: return .purple
        case .custom: return .green
        }
    }
}
```

---

### 6. EventColor

**描述**: 事件颜色枚举 (用于圆点标记)

**值**: `.red`, `.orange`, `.blue`, `.purple`, `.green`, `.gray`

**Swift实现**:
```swift
enum EventColor: String, Codable {
    case red, orange, blue, purple, green, gray

    var swiftUIColor: Color {
        switch self {
        case .red: return .red
        case .orange: return .orange
        case .blue: return .blue
        case .purple: return .purple
        case .green: return .green
        case .gray: return .gray
        }
    }
}
```

---

### 7. EventSource

**描述**: 事件来源枚举

**值**:

| 枚举值 | 说明 |
|--------|------|
| `.builtin` | 应用内置 (节假日数据库) |
| `.eventKit` | 系统日历 (EventKit) |
| `.user` | 用户创建 (未来扩展) |

**Swift实现**:
```swift
enum EventSource: String, Codable {
    case builtin
    case eventKit
    case user
}
```

---

### 8. Theme

**描述**: 主题配置

**字段**:

| 字段名 | 类型 | 必填 | 说明 |
|--------|------|------|------|
| `id` | `String` | ✅ | 主题唯一标识 ("light", "dark", "system") |
| `name` | `String` | ✅ | 主题显示名称 |
| `colors` | `ThemeColors` | ✅ | 颜色配置 |
| `isSystemTheme` | `Bool` | ✅ | 是否跟随系统外观 |

**Swift实现**:
```swift
struct Theme: Identifiable, Codable {
    let id: String
    let name: String
    let colors: ThemeColors
    let isSystemTheme: Bool

    static let light = Theme(
        id: "light",
        name: "浅色",
        colors: ThemeColors.light,
        isSystemTheme: false
    )

    static let dark = Theme(
        id: "dark",
        name: "深色",
        colors: ThemeColors.dark,
        isSystemTheme: false
    )

    static let system = Theme(
        id: "system",
        name: "跟随系统",
        colors: ThemeColors.light, // 初始值,动态调整
        isSystemTheme: true
    )
}
```

---

### 9. ThemeColors

**描述**: 主题颜色配置

**字段**:

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `background` | `String` | 背景色 (Hex) |
| `text` | `String` | 文本色 (Hex) |
| `secondaryText` | `String` | 次要文本色 (Hex) |
| `accent` | `String` | 强调色 (Hex) |
| `border` | `String` | 边框色 (Hex) |
| `todayHighlight` | `String` | 今天高亮色 (Hex) |
| `weekendText` | `String` | 周末文本色 (Hex) |

**Swift实现**:
```swift
struct ThemeColors: Codable {
    let background: String
    let text: String
    let secondaryText: String
    let accent: String
    let border: String
    let todayHighlight: String
    let weekendText: String

    static let light = ThemeColors(
        background: "#FFFFFF",
        text: "#000000",
        secondaryText: "#8E8E93",
        accent: "#007AFF",
        border: "#E5E5EA",
        todayHighlight: "#FFCC00",
        weekendText: "#FF3B30"
    )

    static let dark = ThemeColors(
        background: "#1C1C1E",
        text: "#FFFFFF",
        secondaryText: "#8E8E93",
        accent: "#0A84FF",
        border: "#38383A",
        todayHighlight: "#FFD60A",
        weekendText: "#FF453A"
    )

    // 扩展方法: Hex转SwiftUI Color
    func color(from hex: String) -> Color {
        // 实现Hex颜色转换
    }
}
```

---

### 10. UserSettings

**描述**: 用户设置配置

**字段**:

| 字段名 | 类型 | 必填 | 默认值 | 说明 |
|--------|------|------|-------|------|
| `menuBarFormat` | `MenuBarFormat` | ✅ | `.dateTime` | 菜单栏显示格式 |
| `show24Hour` | `Bool` | ✅ | `false` | 是否使用24小时制 |
| `showWeekday` | `Bool` | ✅ | `false` | 是否显示星期 |
| `secondaryCalendarType` | `CalendarType?` | ❌ | `nil` | 副日历类型 (nil=不显示) |
| `themeId` | `String` | ✅ | `"system"` | 当前主题ID |
| `hoverToShowEnabled` | `Bool` | ✅ | `true` | 鼠标悬停是否展开日历 |
| `hoverDelay` | `Double` | ✅ | `0.5` | 悬停延迟 (秒) |
| `lastUpdated` | `Date` | ✅ | `Date()` | 最后更新时间 |

**Swift实现**:
```swift
struct UserSettings: Codable {
    var menuBarFormat: MenuBarFormat
    var show24Hour: Bool
    var showWeekday: Bool
    var secondaryCalendarType: CalendarType?
    var themeId: String
    var hoverToShowEnabled: Bool
    var hoverDelay: Double
    var lastUpdated: Date

    static let `default` = UserSettings(
        menuBarFormat: .dateTime,
        show24Hour: false,
        showWeekday: false,
        secondaryCalendarType: nil,
        themeId: "system",
        hoverToShowEnabled: true,
        hoverDelay: 0.5,
        lastUpdated: Date()
    )
}
```

---

### 11. MenuBarFormat

**描述**: 菜单栏显示格式枚举

**值**:

| 枚举值 | 显示名称 | 示例 |
|--------|---------|------|
| `.dateOnly` | 仅日期 | "10月27日" |
| `.timeOnly` | 仅时间 | "14:30" |
| `.dateTime` | 日期+时间 | "10月27日 14:30" |
| `.custom` | 自定义 | 根据用户格式字符串 |

**Swift实现**:
```swift
enum MenuBarFormat: String, Codable, CaseIterable {
    case dateOnly
    case timeOnly
    case dateTime
    case custom

    var displayName: String {
        switch self {
        case .dateOnly: return "仅日期"
        case .timeOnly: return "仅时间"
        case .dateTime: return "日期+时间"
        case .custom: return "自定义"
        }
    }

    func format(date: Date, show24Hour: Bool, showWeekday: Bool) -> String {
        // 实现格式化逻辑
    }
}
```

---

## 数据关系图

```text
UserSettings ──────────────────┐
                               │
Theme ─────────────────────────┤
  └─ ThemeColors               │
                               │
CalendarDate ─────────┬────────┤
  ├─ SecondaryDateInfo │        │
  │   └─ CalendarType  │        │
  └─ DateEvent[]       │        │
      ├─ EventType     │        │
      ├─ EventColor    │        │
      └─ EventSource   │        │
                       │        │
MenuBarFormat ─────────┘        │
                                │
[All managed by ViewModels] ────┘
```

---

## 状态转换

### CalendarDate状态

```text
[Created] → [Load Events] → [Display]
                ↓
        [Events Updated] → [Re-render]
```

### UserSettings状态

```text
[Default] → [User Modifies] → [Validate] → [Save to UserDefaults]
                                   ↓
                            [Invalid] → [Show Error]
```

### Theme状态

```text
[Loaded] → [User Selects] → [Applied]
              ↓
       [System Changed] (if isSystemTheme) → [Auto Update]
```

---

## 持久化策略

| 数据类型 | 存储方式 | 时机 |
|---------|---------|------|
| `UserSettings` | UserDefaults | 设置修改时立即保存 |
| `Theme` | JSON文件 (Resources/Themes/) | 应用启动时加载 |
| `HolidayData` | JSON文件 (Resources/Holidays/) | 应用启动时加载,按需查询 |
| `CalendarDate` | 内存缓存 | 运行时计算,不持久化 |
| `DateEvent` (EventKit) | EventKit数据库 | 实时查询,不持久化 |

---

## 验证规则汇总

### CalendarDate
- ✅ `month`: 1-12
- ✅ `day`: 根据月份验证 (1-28/29/30/31)
- ✅ `weekday`: 1-7

### UserSettings
- ✅ `hoverDelay`: 0.1-5.0 秒
- ✅ `themeId`: 必须存在于可用主题列表中
- ✅ `secondaryCalendarType`: 必须为 `CalendarType` 枚举值或 `nil`

### Theme
- ✅ `id`: 非空字符串,唯一
- ✅ `colors`: 所有颜色字段必须为有效Hex格式 (#RRGGBB)

---

## 下一步

数据模型设计完成,准备生成:
1. API合约 (内部服务接口定义)
2. 快速入门文档