# Quick Start Guide: MacOS菜单栏日历应用

**Feature**: 001-menubar-calendar
**Date**: 2025-10-27
**Audience**: 开发团队

## 目标

快速上手项目开发,理解核心架构和关键实现路径。

---

## 开发环境设置

### 必需工具

| 工具 | 版本 | 用途 |
|------|------|------|
| Xcode | 15.0+ | 开发IDE |
| macOS | 11.0+ | 目标平台 |
| Git | 最新 | 版本控制 |

### 项目初始化

```bash
# 1. 克隆仓库
git clone <repository-url>
cd mini-cal

# 2. 切换到功能分支
git checkout 001-menubar-calendar

# 3. 打开Xcode项目 (首次创建时需要执行)
xed MiniCal/MiniCal.xcodeproj
```

---

## 项目结构速览

```text
MiniCal/
├── MiniCal/
│   ├── App/                  # 应用入口
│   ├── Views/                # SwiftUI视图
│   │   ├── MenuBar/          # 菜单栏UI
│   │   ├── Calendar/         # 日历浮窗
│   │   └── Settings/         # 设置界面
│   ├── Models/               # 数据模型
│   ├── Services/             # 业务逻辑层
│   │   ├── CalendarEngine/   # 日历核心引擎
│   │   ├── EventService.swift
│   │   ├── ThemeManager.swift
│   │   └── SettingsManager.swift
│   ├── Resources/            # 静态资源
│   │   ├── Assets.xcassets/
│   │   ├── Themes/           # 主题JSON配置
│   │   └── Holidays/         # 节假日数据JSON
│   └── Utilities/            # 工具类和扩展
├── MiniCalTests/             # 单元测试
└── MiniCalUITests/           # UI测试
```

---

## 核心概念

### 1. MVVM架构

```text
View (SwiftUI)
  ↓ @ObservedObject
ViewModel (@Published)
  ↓ Protocol
Service Layer
```

**示例**:
```swift
// View
struct CalendarView: View {
    @ObservedObject var viewModel: CalendarViewModel

    var body: some View {
        // UI代码
    }
}

// ViewModel
class CalendarViewModel: ObservableObject {
    @Published var monthData: [CalendarDate] = []
    private let engine: CalendarEngineProtocol

    func loadMonth() {
        monthData = engine.getMonthData(...)
    }
}

// Service
class CalendarEngine: CalendarEngineProtocol {
    func getMonthData(...) -> [CalendarDate] {
        // 业务逻辑
    }
}
```

### 2. 菜单栏集成

核心技术: `NSStatusBar` + `NSPopover`

```swift
class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!

    func setup() {
        // 创建状态栏项
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.title = "10月27日 14:30"

        // 创建弹出窗口
        popover = NSPopover()
        popover.contentViewController = NSHostingController(
            rootView: CalendarView()
        )
        popover.behavior = .transient
    }

    @objc func togglePopover() {
        if popover.isShown {
            popover.close()
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }
}
```

### 3. 本地历法转换

使用Foundation的Calendar API:

```swift
func convertToChineseLunar(date: Date) -> String {
    let calendar = Calendar(identifier: .chinese)
    let components = calendar.dateComponents([.year, .month, .day], from: date)

    guard let month = components.month, let day = components.day else {
        return ""
    }

    // 转换为中文显示
    let monthNames = ["正月", "二月", "三月", ...]
    let dayNames = ["初一", "初二", ...]

    return "\(monthNames[month-1])\(dayNames[day-1])"
}
```

---

## 关键实现路径

### Path 1: 菜单栏显示 (P1)

**目标**: 显示可定制的日期时间

**步骤**:
1. 创建 `MiniCalApp.swift` 和 `AppDelegate.swift`
2. 实现 `MenuBarController` 创建 `NSStatusItem`
3. 创建 `MenuBarViewModel` 管理显示文本
4. 实现定时器每分钟更新时间
5. 集成 `SettingsManager` 支持格式自定义

**关键代码**:
```swift
class MenuBarViewModel: ObservableObject {
    @Published var displayText: String = ""
    private var timer: Timer?
    private let settingsManager: SettingsManagerProtocol

    func startUpdating() {
        timer = Timer.scheduledTimer(withTimeInterval: 60, repeats: true) { [weak self] _ in
            self?.updateDisplayText()
        }
        updateDisplayText()
    }

    private func updateDisplayText() {
        let format = settingsManager.settings.menuBarFormat
        displayText = format.format(date: Date(), ...)
    }
}
```

**测试验证**:
- [ ] 应用启动后菜单栏显示日期时间
- [ ] 时间每分钟自动更新
- [ ] 修改设置后显示格式立即变化

---

### Path 2: 月视图展开 (P1)

**目标**: 点击菜单栏展开日历浮窗

**步骤**:
1. 创建 `CalendarPopoverView.swift`
2. 实现 `CalendarMonthView.swift` 使用 `LazyVGrid` 显示日期网格
3. 创建 `CalendarViewModel` 生成月数据
4. 实现 `CalendarEngine` 计算42个单元格数据
5. 绑定点击事件打开/关闭浮窗

**关键代码**:
```swift
struct CalendarMonthView: View {
    let dates: [CalendarDate]

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7)) {
            ForEach(dates) { date in
                CalendarDayCell(date: date)
            }
        }
    }
}

struct CalendarDayCell: View {
    let date: CalendarDate

    var body: some View {
        VStack(spacing: 4) {
            Text("\(date.day)")
                .font(.system(size: 14))
            if let secondary = date.secondaryDate {
                Text(secondary.displayText)
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
            }
            // 圆点标记
            HStack(spacing: 2) {
                ForEach(date.events, id: \.id) { event in
                    Circle()
                        .fill(event.color.swiftUIColor)
                        .frame(width: 4, height: 4)
                }
            }
        }
    }
}
```

**测试验证**:
- [ ] 点击菜单栏图标展开日历
- [ ] 显示当前月份的完整日期网格
- [ ] 今天的日期有特殊高亮
- [ ] 点击浮窗外部关闭

---

### Path 3: 本地历法显示 (P2)

**目标**: 在日期下方显示农历等本地历法

**步骤**:
1. 实现 `SecondaryCalendarConverter`
2. 在 `CalendarEngine` 中批量转换本地历法
3. 更新 `CalendarDayCell` 显示本地历法文本
4. 在设置中添加本地历法选择

**关键代码**:
```swift
class SecondaryCalendarConverter {
    func batchConvert(dates: [Date], to type: CalendarType) -> [Date: SecondaryDateInfo] {
        var result: [Date: SecondaryDateInfo] = [:]

        guard let identifier = type.identifier else {
            // 佛历等自定义实现
            return dates.reduce(into: [:]) { dict, date in
                dict[date] = convertBuddhist(date: date)
            }
        }

        let calendar = Calendar(identifier: identifier)
        for date in dates {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            result[date] = SecondaryDateInfo(
                calendarType: type,
                displayText: formatComponents(components, for: type),
                year: components.year,
                month: components.month,
                day: components.day,
                festival: nil
            )
        }

        return result
    }
}
```

**测试验证**:
- [ ] 选择农历后每个日期显示对应农历日期
- [ ] 切换不同本地历法类型正确显示
- [ ] 关闭本地历法后不显示任何本地历法信息

---

### Path 4: 日期状态标记 (P2)

**目标**: 用彩色圆点标记节假日和事件

**步骤**:
1. 创建 `HolidayProvider` 加载节假日JSON数据
2. 集成 `EventService` 访问系统日历
3. 在 `CalendarEngine.getMonthData` 中合并所有事件
4. 在 `CalendarDayCell` 中渲染圆点

**JSON数据示例** (`Resources/Holidays/CN.json`):
```json
{
  "version": "2025.1",
  "region": "CN",
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
}
```

**测试验证**:
- [ ] 节假日显示红色/橙色圆点
- [ ] 有系统日历事件的日期显示蓝色圆点
- [ ] 同一天多个事件显示多个圆点
- [ ] 点击日期查看事件详情

---

### Path 5: 主题系统 (P3)

**目标**: 支持浅色/深色/跟随系统主题

**步骤**:
1. 创建 `Theme.swift` 和 `ThemeManager`
2. 加载 `Resources/Themes/themes.json`
3. 通过 `@EnvironmentObject` 注入到所有视图
4. 监听 `NSApp.effectiveAppearance` 响应系统变化

**主题JSON示例**:
```json
{
  "themes": [
    {
      "id": "light",
      "name": "浅色主题",
      "colors": {
        "background": "#FFFFFF",
        "text": "#000000",
        "secondaryText": "#8E8E93",
        "accent": "#007AFF",
        "border": "#E5E5EA",
        "todayHighlight": "#FFCC00",
        "weekendText": "#FF3B30"
      }
    }
  ]
}
```

**测试验证**:
- [ ] 切换主题后UI颜色立即更新
- [ ] 选择"跟随系统"后自动响应系统外观变化
- [ ] 主题切换完成时间 <200ms

---

## 常见问题

### Q1: EventKit权限被拒绝怎么办?

**A**: 应用必须优雅降级,仅显示基础日历功能:

```swift
class EventService {
    func fetchEvents(for date: Date) async -> [DateEvent] {
        guard authorizationStatus == .authorized else {
            return [] // 无权限时返回空数组
        }
        // 正常获取事件
    }
}
```

### Q2: 本地历法转换性能问题?

**A**: 使用批量转换和缓存:

```swift
class CalendarEngine {
    private var cache = NSCache<NSString, [CalendarDate]>()

    func getMonthData(...) -> [CalendarDate] {
        let key = "\(year)-\(month)" as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        // 批量转换42个日期
        let dates = generateDates(...)
        let converted = converter.batchConvert(dates: dates.map(\.gregorianDate), to: calendarType)

        cache.setObject(dates, forKey: key)
        return dates
    }
}
```

### Q3: 如何调试菜单栏应用?

**A**: 使用Xcode的Console输出和断点:

```swift
// 在关键位置添加日志
print("[MenuBar] Display text updated: \(displayText)")

// 或使用os_log
import os.log
let logger = Logger(subsystem: "com.minical.app", category: "MenuBar")
logger.info("Popover shown")
```

### Q4: 节假日数据如何更新?

**A**: 应用首次发布包含未来3年数据,通过应用更新增量更新:

```swift
class HolidayProvider {
    func isDataOutdated() -> Bool {
        guard let lastDate = getLatestHolidayDate() else {
            return true
        }
        let oneYearFromNow = Date().addingTimeInterval(365 * 24 * 3600)
        return lastDate < oneYearFromNow
    }
}

// 在应用启动时检查
if holidayProvider.isDataOutdated() {
    showUpdateReminder()
}
```

---

## 下一步行动

1. **创建Xcode项目**: 按照项目结构创建文件和组
2. **实现P1功能**: 菜单栏显示 + 月视图展开
3. **编写单元测试**: 为 `CalendarEngine` 和 `SettingsManager` 编写测试
4. **UI测试**: 验证菜单栏交互和浮窗显示
5. **实现P2功能**: 本地历法和状态标记
6. **性能优化**: 确保所有操作满足性能目标

---

## 参考文档

- [spec.md](./spec.md) - 功能规格说明
- [data-model.md](./data-model.md) - 数据模型定义
- [contracts/service-interfaces.md](./contracts/service-interfaces.md) - 服务接口契约
- [research.md](./research.md) - 技术研究和决策
- [plan.md](./plan.md) - 实施计划

---

## 开发进度追踪

使用 `/speckit.tasks` 命令生成详细的任务清单,包括:
- 功能分解
- 测试用例
- 验收标准
- 依赖关系

**准备就绪**: 所有设计文档已完成,可以开始编码实现! 🚀