# Research Document: MacOS菜单栏日历应用

**Feature**: 001-menubar-calendar
**Date**: 2025-10-27
**Phase**: 0 - Outline & Research

## 研究目标

本文档记录关键技术决策、最佳实践调研和替代方案评估,为实施阶段提供技术指导。

## 核心技术决策

### 1. 菜单栏集成方案

**Decision**: 使用 `NSStatusBar` + `NSPopover` 实现菜单栏图标和浮窗

**Rationale**:
- `NSStatusBar` 是macOS菜单栏应用的标准API,稳定可靠
- `NSPopover` 提供原生的浮窗体验,自动处理定位和焦点管理
- SwiftUI可以通过 `NSHostingController` 桥接到 `NSPopover`
- 完全符合macOS人机界面指南

**Alternatives Considered**:
- **NSMenu**: 仅适合简单菜单,不支持复杂UI布局
- **NSWindow**: 需要手动处理定位、阴影、焦点,实现复杂度高
- 第三方框架: 增加依赖,不如原生API可靠

**Implementation Notes**:
```swift
// 核心实现模式
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem
    private var popover: NSPopover

    func showPopover() {
        if let button = statusItem.button {
            popover.show(relativeTo: button.bounds,
                        of: button,
                        preferredEdge: .minY)
        }
    }
}
```

**Best Practices**:
- 使用 `statusItem.button` 设置菜单栏图标和文本
- 监听 `NSPopover` 的 `didClose` 通知管理状态
- 鼠标悬停通过 `NSTrackingArea` 实现

---

### 2. 副日历实现方案

**Decision**: 使用 `Foundation.Calendar` + 自定义转换算法

**Rationale**:
- `Foundation.Calendar` 提供基础的日历系统支持 (Gregorian, Chinese, Hebrew, Islamic等)
- Apple官方API,性能优化良好,支持本地化
- 对于复杂历法(如中国农历节气),可基于Foundation扩展自定义算法
- 完全离线可用,无需网络请求

**Alternatives Considered**:
- **第三方库** (如 SwiftHoliday, Lunar-Swift):
  - 优点: 功能完整,节省开发时间
  - 缺点: 增加依赖,维护风险,可能不支持所有目标历法
  - **决策**: 不采用,优先使用系统API保证稳定性

- **WebAPI调用**:
  - 优点: 数据准确,易于更新
  - 缺点: 违反离线可用要求,网络延迟影响体验
  - **决策**: 不采用

**Supported Calendars**:
| 历法 | Foundation支持 | 实现方式 |
|------|---------------|---------|
| 中国农历 | ✅ `Calendar.Identifier.chinese` | 直接使用Foundation API |
| 伊斯兰历 | ✅ `Calendar.Identifier.islamic` | 直接使用Foundation API |
| 希伯来历 | ✅ `Calendar.Identifier.hebrew` | 直接使用Foundation API |
| 波斯历 | ✅ `Calendar.Identifier.persian` | 直接使用Foundation API |
| 日本和历 | ✅ `Calendar.Identifier.japanese` | 直接使用Foundation API |
| 佛历 | ❌ | 基于Gregorian自定义转换 (年份+543) |

**Implementation Pattern**:
```swift
class SecondaryCalendarConverter {
    func convert(gregorianDate: Date, to calendarType: CalendarType) -> String {
        let calendar = Calendar(identifier: calendarType.identifier)
        let components = calendar.dateComponents([.year, .month, .day], from: gregorianDate)
        return formatComponents(components, for: calendarType)
    }
}
```

---

### 3. 节假日数据管理

**Decision**: 本地JSON数据库 + 定期数据更新

**Rationale**:
- 节假日数据相对静态,适合本地存储
- JSON格式易于维护和版本控制
- 应用首次发布包含未来3年数据,足够日常使用
- 支持应用更新时增量更新数据

**Data Structure**:
```json
{
  "version": "2025.1",
  "regions": {
    "CN": {
      "name": "中国",
      "holidays": [
        {
          "date": "2025-01-01",
          "name": "元旦",
          "type": "public_holiday"
        },
        {
          "date": "2025-02-10",
          "name": "春节",
          "type": "traditional_festival"
        }
      ]
    },
    "US": { ... }
  }
}
```

**Data Sources**:
- 中国: 国务院办公厅官方公告
- 其他国家: Wikipedia, Time and Date API (仅用于数据准备)

**Update Strategy**:
- 应用启动时检查数据版本
- 如果数据过期 (>1年),显示提示建议更新应用
- 不强制要求更新,过期数据仍可使用

---

### 4. 主题系统设计

**Decision**: JSON配置 + SwiftUI Environment

**Rationale**:
- JSON配置文件易于扩展,支持未来添加更多主题
- SwiftUI的 `@Environment` 提供优雅的主题注入机制
- 支持响应macOS系统外观变化 (`NSApp.effectiveAppearance`)

**Theme Structure**:
```json
{
  "themes": [
    {
      "id": "light",
      "name": "浅色主题",
      "colors": {
        "background": "#FFFFFF",
        "text": "#000000",
        "accent": "#007AFF",
        "todayHighlight": "#FFCC00",
        "holidayDot": "#FF3B30",
        "eventDot": "#007AFF"
      }
    },
    {
      "id": "dark",
      "name": "深色主题",
      "colors": { ... }
    }
  ]
}
```

**Implementation**:
```swift
// 主题管理器
class ThemeManager: ObservableObject {
    @Published var currentTheme: Theme

    func applyTheme(_ theme: Theme) {
        // 更新全局主题
        currentTheme = theme
    }

    func observeSystemAppearance() {
        // 监听系统外观变化
        NSApp.observe(\.effectiveAppearance) { [weak self] app, _ in
            self?.updateThemeIfNeeded()
        }
    }
}

// SwiftUI视图中使用
struct CalendarView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        VStack {
            // 使用主题颜色
        }
        .background(themeManager.currentTheme.backgroundColor)
    }
}
```

---

### 5. EventKit集成

**Decision**: 异步请求权限 + 优雅降级

**Rationale**:
- EventKit需要用户授权访问日历数据
- 用户可能拒绝授权,应用必须在无权限情况下正常工作
- 异步请求避免阻塞UI

**Permission Flow**:
1. 应用首次启动,不主动请求权限
2. 当用户首次展开日历浮窗时,检查权限状态
3. 如果未授权,显示信息提示权限用途
4. 用户点击"允许访问"按钮后,调用 `EKEventStore.requestAccess`
5. 如果拒绝,隐藏会议相关功能,仅显示基础日历

**Implementation**:
```swift
class EventService {
    private let eventStore = EKEventStore()

    func requestAuthorization() async -> Bool {
        do {
            return try await eventStore.requestAccess(to: .event)
        } catch {
            return false
        }
    }

    func fetchEvents(for date: Date) -> [DateEvent] {
        guard hasAuthorization else { return [] }

        let predicate = eventStore.predicateForEvents(
            withStart: date.startOfDay,
            end: date.endOfDay,
            calendars: nil
        )
        return eventStore.events(matching: predicate)
            .map { DateEvent(from: $0) }
    }
}
```

---

### 6. 性能优化策略

**Decision**: 懒加载 + 缓存 + 防抖

**Rationale**:
- 月视图数据量小 (最多42个单元格),但需要避免不必要的计算
- 副日历转换和节假日查询可以缓存
- 用户快速切换月份时需要防抖

**Optimization Techniques**:

1. **数据缓存**:
```swift
class CalendarEngine {
    private var cache = NSCache<NSString, MonthData>()

    func getMonthData(year: Int, month: Int) -> MonthData {
        let key = "\(year)-\(month)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let data = calculateMonthData(year: year, month: month)
        cache.setObject(data, forKey: key)
        return data
    }
}
```

2. **防抖处理**:
```swift
class CalendarViewModel: ObservableObject {
    private var debounceTask: Task<Void, Never>?

    func navigateToMonth(_ offset: Int) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(nanoseconds: 100_000_000) // 100ms
            await loadMonth(offset)
        }
    }
}
```

3. **SwiftUI优化**:
- 使用 `LazyVGrid` 而非 `Grid` (虽然数据量小,但仍是最佳实践)
- 为 `CalendarDayCell` 实现 `Equatable` 避免不必要重绘
- 使用 `.id()` modifier确保视图更新正确性

---

### 7. 设置持久化

**Decision**: `UserDefaults` + Codable

**Rationale**:
- 设置数据量小,适合使用 `UserDefaults`
- `Codable` 协议提供类型安全的序列化
- 系统自动处理同步和持久化

**Implementation**:
```swift
struct UserSettings: Codable {
    var menuBarFormat: MenuBarFormat
    var secondaryCalendarType: CalendarType?
    var themeId: String
    var hoverToShowEnabled: Bool

    static let `default` = UserSettings(
        menuBarFormat: .dateTime,
        secondaryCalendarType: .chinese,
        themeId: "system",
        hoverToShowEnabled: true
    )
}

class SettingsManager {
    private let defaults = UserDefaults.standard
    private let key = "MiniCal.Settings"

    func load() -> UserSettings {
        guard let data = defaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(UserSettings.self, from: data)
        else {
            return .default
        }
        return settings
    }

    func save(_ settings: UserSettings) {
        if let data = try? JSONEncoder().encode(settings) {
            defaults.set(data, forKey: key)
        }
    }
}
```

---

## 架构模式

### MVVM实现

```text
View (SwiftUI)
  ↓ user action
ViewModel (@ObservableObject)
  ↓ business logic
Service Layer
  ↓ data access
Model / UserDefaults / EventKit
```

**Benefits**:
- UI与业务逻辑分离,便于测试
- `@Published` 属性自动驱动UI更新
- ViewModel可独立单元测试

**Key Principles**:
- View只负责UI渲染和用户交互
- ViewModel包含显示逻辑和状态管理
- Service层处理数据获取和业务逻辑
- Model为纯数据结构,遵循Codable

---

## 依赖版本矩阵

| 依赖 | 版本要求 | 说明 |
|------|---------|------|
| macOS | 11.0+ | 支持Big Sur及以上版本 |
| Swift | 5.9+ | 使用最新语言特性 |
| Xcode | 15.0+ | 开发环境 |
| SwiftUI | 2.0+ | macOS 11.0对应版本 |

**Third-Party Dependencies**: 无

---

## 风险缓解

| 风险 | 缓解措施 | 验证方式 |
|------|---------|---------|
| **副日历精度** | 使用Foundation官方API,参考Apple文档验证 | 单元测试覆盖已知日期转换 |
| **EventKit权限** | 优雅降级,权限拒绝时隐藏相关功能 | UI测试验证无权限场景 |
| **性能瓶颈** | 缓存机制,防抖处理,SwiftUI优化 | 性能测试验证响应时间<300ms |
| **主题切换** | 监听系统外观变化,即时响应 | 集成测试验证切换流畅性 |
| **节假日数据过期** | 包含未来3年数据,应用更新时增量更新 | 数据版本检查 |

---

## 下一步行动

Phase 0研究完成,准备进入Phase 1:
1. ✅ 技术栈确定: Swift + SwiftUI + AppKit
2. ✅ 架构模式确定: MVVM
3. ✅ 核心技术方案明确: NSStatusBar, Foundation.Calendar, JSON配置
4. ✅ 无阻塞性技术风险

**Ready for Phase 1**: 生成数据模型、API合约和快速入门文档。