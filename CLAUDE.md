# MiniCal - macOS 菜单栏日历应用

## 项目概述

MiniCal 是一个原生 macOS 菜单栏日历应用，支持多日历系统（农历、伊斯兰历、希伯来历等）、多语言本地化（13种语言）、主题定制、事件管理和外部日历订阅。

**核心特性：**
- 🌍 多日历系统支持（公历、农历、伊斯兰历、希伯来历、日本历、波斯历等）
- 🌐 13 语言本地化（ar, en, fa, he, ja, ko, th, tr, ur, vi, zh-Hans, zh-Hant + Base）
- 🎨 主题系统（JSON 配置，支持预览和切换）
- 📅 事件管理（系统日历同步、外部订阅、本地管理）
- 🌅 天文信息（日出日落、月相、节气、祈祷时间）
- ⚡ 性能优先（NSCache + 增量同步 + 离线优先）

**技术栈：**
- **语言**: Swift 5.9+
- **UI 框架**: SwiftUI + AppKit (NSStatusBar, NSPopover)
- **系统集成**: EventKit (日历访问), CoreLocation (定位服务)
- **架构模式**: MVVM (Model-View-ViewModel)
- **数据持久化**: UserDefaults + NSCache + Local Storage
- **依赖管理**: Swift Package Manager

**外部依赖：**
- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) @ 2.4.0 - 全局快捷键
- [Solar](https://github.com/ceeK/Solar) @ 3.0.1 - 日出日落计算
- [Adhan](https://github.com/batoulapps/adhan-swift) @ 1.4.0 - 伊斯兰祈祷时间
- [LunarSwift](https://github.com/6tail/lunar-swift) @ 1.1.8 - 农历计算

---

## 项目结构

```
MiniCal/
├── App/
│   ├── MiniCalApp.swift              # 应用入口
│   └── MenuBarController.swift       # 菜单栏核心控制器（协调 ViewModel 和 UI）
│
├── Models/                           # 数据模型（20 个文件）
│   ├── CalendarEvent.swift           # 事件数据模型（包含 EventStatus, EventVisibility）
│   ├── CalendarDate.swift            # 日期数据模型（包含副历信息、节日、事件）
│   ├── CalendarSubscription.swift    # 订阅数据模型（系统/外部/本地）
│   ├── UserSettings.swift            # 用户设置（持久化到 UserDefaults）
│   ├── Theme.swift                   # 主题数据模型
│   ├── CalendarType.swift            # 日历类型枚举
│   ├── SupportedLocale.swift         # 支持的语言
│   └── ...                           # 其他 13 个辅助模型
│
├── ViewModels/                       # 视图模型（5 个 MVVM ViewModels）
│   ├── CalendarViewModel.swift       # 日历主视图模型（月份导航、日期数据）
│   ├── MenuBarViewModel.swift        # 菜单栏视图模型（标题格式化、点击悬浮）
│   ├── EventListViewModel.swift      # 事件列表视图模型
│   ├── EventSubscriptionViewModel.swift  # 订阅管理
│   └── SubscriptionManagerViewModel.swift
│
├── Views/                            # SwiftUI 视图（17 个文件）
│   ├── MenuBarView.swift             # 菜单栏弹窗主视图
│   ├── CalendarView.swift            # 日历网格视图
│   ├── CalendarGridView.swift        # 日历网格布局
│   ├── SettingsView.swift            # 设置界面（权限、主题、订阅、快捷键）
│   ├── Components/                   # 可复用组件
│   │   ├── DayEventListView.swift    # 当日事件列表
│   │   ├── DayEventHeader.swift      # 事件列表头部（包含定位权限按钮）
│   │   └── ...                       # 其他 6 个组件
│   └── ...                           # 其他 9 个视图
│
├── Services/                         # 服务层（33 个文件）
│   ├── CalendarService.swift         # 日历数据生成服务（核心）
│   ├── EventService.swift            # 事件聚合服务（协调三种事件源）
│   ├── CalendarEventService.swift    # 事件管理服务
│   ├── SettingsManager.swift         # 设置管理器（UserDefaults 封装）
│   ├── ThemeManager.swift            # 主题管理器（JSON 加载、切换）
│   ├── PermissionManager.swift       # 权限管理（日历、定位）
│   ├── LocationService.swift         # 定位服务（日出日落、祈祷时间）
│   │
│   ├── CalendarEngine/               # 日历转换引擎
│   │   ├── SecondaryCalendarConverter.swift  # 副历转换器
│   │   └── CalendarMonthNames.swift          # 月份名称本地化
│   │
│   ├── CalendarSubscriptionService.swift   # 外部订阅服务
│   ├── CalendarSyncService.swift           # 同步协调服务
│   ├── IncrementalSyncService.swift        # 增量同步
│   ├── ICalParser.swift                    # iCal 格式解析
│   ├── LocalStorageManager.swift           # 本地存储管理
│   ├── EventCacheManager.swift             # 事件缓存（NSCache）
│   │
│   ├── MoonPhaseService.swift        # 月相计算
│   ├── SunTimeService.swift          # 日出日落计算（依赖 Solar）
│   ├── PrayerTimeService.swift       # 伊斯兰祈祷时间（依赖 Adhan）
│   ├── ShabbatService.swift          # 希伯来安息日时间
│   ├── SolarTermService.swift        # 二十四节气
│   ├── LunarHolidayService.swift     # 农历节日
│   │
│   ├── Localization/                 # 本地化服务
│   │   ├── LocalizationManager.swift    # 本地化管理器
│   │   ├── CalendarLocalizer.swift      # 日历名称本地化
│   │   └── FestivalLocalizer.swift      # 节日名称本地化
│   │
│   └── ...                           # 其他 8 个辅助服务
│
├── Utilities/                        # 工具类（9 个文件）
│   ├── Logger.swift                  # 日志工具（os.log 封装，分类管理）
│   ├── Constants.swift               # 全局常量
│   ├── MiniCalError.swift            # 错误类型定义
│   ├── Extensions/                   # Swift 扩展
│   │   ├── Calendar+Extensions.swift    # Calendar 扩展
│   │   ├── Date+Extensions.swift        # Date 扩展
│   │   ├── String+Localization.swift    # 字符串本地化扩展
│   │   └── View+RTL.swift               # RTL 布局支持
│   └── ...
│
├── Resources/
│   ├── CalendarData/                 # 节日数据（Buddhist, Chinese, Hebrew, Islamic, Japanese, Persian）
│   ├── Holidays/                     # 节假日数据（CN.json）
│   ├── Localizations/                # 本地化字符串
│   │   ├── Localizable.xcstrings     # 主字符串文件（13 语言）
│   │   ├── CalendarNames.xcstrings   # 日历名称
│   │   └── Festivals.xcstrings       # 节日名称
│   └── Themes/
│       └── themes.json               # 主题配置文件
│
├── Assets.xcassets/                  # 图标和图片资源
├── Info.plist                        # 主配置文件
│
├── Base.lproj/Info.plist             # 本地化权限描述（基础版本）
├── en.lproj/Info.plist               # 英语
├── zh-Hans.lproj/Info.plist          # 简体中文
├── zh-Hant.lproj/Info.plist          # 繁体中文
├── ar.lproj/Info.plist               # 阿拉伯语
├── fa.lproj/Info.plist               # 波斯语
├── he.lproj/Info.plist               # 希伯来语
├── ja.lproj/Info.plist               # 日语
├── ko.lproj/Info.plist               # 韩语
├── th.lproj/Info.plist               # 泰语
├── tr.lproj/Info.plist               # 土耳其语
├── ur.lproj/Info.plist               # 乌尔都语
└── vi.lproj/Info.plist               # 越南语
```

**统计信息：**
- Swift 文件: 96 个
- 模型: 20 个
- 视图: 17 个
- 视图模型: 5 个
- 服务: 33 个
- 工具类: 9 个

---

## 架构设计

### MVVM 模式

项目严格遵循 MVVM 架构：

```
┌─────────────────┐
│  MenuBarView    │  ← SwiftUI 视图（展示层）
│  CalendarView   │
│  SettingsView   │
└────────┬────────┘
         │ @ObservedObject / @Published
         ↓
┌─────────────────┐
│ CalendarViewModel    │  ← 视图模型（业务逻辑）
│ MenuBarViewModel     │
│ EventListViewModel   │
└────────┬─────────────┘
         │ 调用服务
         ↓
┌─────────────────┐
│ CalendarService      │  ← 服务层（数据处理）
│ EventService         │
│ ThemeManager         │
│ SettingsManager      │
└────────┬─────────────┘
         │ 操作模型
         ↓
┌─────────────────┐
│ CalendarEvent        │  ← 数据模型
│ CalendarDate         │
│ UserSettings         │
└──────────────────────┘
```

**核心协调器：**
- **MenuBarController** (`App/MenuBarController.swift`)
  - NSObject 子类，管理 NSStatusItem 和 NSPopover
  - 持有 `MenuBarViewModel` 和 `CalendarViewModel`
  - 负责 AppKit ↔ SwiftUI 桥接
  - 处理鼠标悬浮、点击、右键菜单
  - 协调自动同步、主题预览、设置窗口

### 数据流

#### 1. 日历数据生成流程

```
用户操作（切换月份）
  ↓
CalendarViewModel.navigateToMonth()
  ↓
CalendarService.generateMonth(for: date, secondaryCalendar: type)
  ↓
1. 生成公历日期 (Calendar.gregorian)
2. SecondaryCalendarConverter.convert() → 副历日期
3. HolidayProvider.holidays(for:) → 节日数据
4. EventService.events(for:) → 事件数据
  ↓
返回 [CalendarDate] 给 ViewModel
  ↓
@Published var calendarDates 触发 UI 更新
```

#### 2. 事件数据聚合流程

```
EventService.events(for: dateRange)
  ↓
并发获取三种事件源：
├─ SystemCalendarService.fetchEvents() → 系统日历事件（EventKit）
├─ ExternalCalendarService.fetchEvents() → 外部订阅事件（iCal）
└─ LocalEventGroupService.fetchEvents() → 本地管理事件（UserDefaults）
  ↓
EventCacheManager.cache() → 缓存到 NSCache
  ↓
返回合并后的 [CalendarEvent]
```

#### 3. 设置同步流程

```
用户修改设置（SettingsView）
  ↓
SettingsManager.updateSettings()
  ↓
UserDefaults.standard.set() → 持久化
  ↓
@Published var currentSettings 发布通知
  ↓
CalendarViewModel/MenuBarViewModel 观察变更
  ↓
重新加载数据 / 更新 UI
```

### 关键设计决策

#### 1. 本地化架构

**Info.plist 本地化方式：**
- 使用 **Xcode "Localize..." 方法**（完整 Info.plist 文件，而非 InfoPlist.strings）
- 每个语言独立的 `*.lproj/Info.plist` 文件
- project.pbxproj 配置：`membershipExceptions = ("/Localized: Info.plist")`
- 包含 4 个权限描述键：
  - `NSCalendarsUsageDescription`
  - `NSCalendarsFullAccessUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - `NSLocationUsageDescription`

**字符串本地化：**
- 使用 `.xcstrings` 格式（Xcode 15+ String Catalogs）
- 3 个字符串文件：
  - `Localizable.xcstrings` - 主字符串（UI 文本）
  - `CalendarNames.xcstrings` - 日历名称
  - `Festivals.xcstrings` - 节日名称
- 通过 `String.localized()` 扩展方法访问：`"key".localized()`

**RTL（从右到左）语言支持：**
- 阿拉伯语（ar）、希伯来语（he）、波斯语（fa）、乌尔都语（ur）
- `View+RTL.swift` 提供 RTL 布局扩展
- SwiftUI 自动镜像布局（`.environment(\.layoutDirection, .rightToLeft)`）

#### 2. 日志系统

**Logger.swift** 封装 `os.log`，分类管理：

```swift
// 使用方法：
Logger.debug("Debug message", category: Logger.app)
Logger.info("Info message", category: Logger.calendar)
Logger.warning("Warning", category: Logger.network)
Logger.error("Error occurred", category: Logger.service)

// 日志分类：
Logger.app       // 应用级别
Logger.calendar  // 日历相关
Logger.event     // 事件相关
Logger.network   // 网络请求
Logger.service   // 服务层
Logger.ui        // UI 交互
```

#### 3. 主题系统

**ThemeManager** 加载 `Resources/Themes/themes.json`：

```swift
// 加载主题
ThemeManager.shared.loadThemes()

// 应用主题
ThemeManager.shared.applyTheme(themeId: "dark")

// 预览主题（不保存）
ThemeManager.shared.previewTheme(themeId: "christmas")

// 监听主题变更
ThemeManager.shared.$currentTheme
    .sink { theme in
        // 更新 UI
    }
```

**主题配置结构：**
```json
{
  "themes": [
    {
      "id": "default",
      "name": "默认",
      "colors": {
        "background": "#FFFFFF",
        "text": "#000000",
        ...
      }
    }
  ]
}
```

#### 4. 权限处理

**PermissionManager** 管理两种权限：

```swift
// 日历权限
PermissionManager.shared.requestCalendarPermission { granted in
    if granted {
        // 访问日历
    } else {
        // 引导用户到系统设置
    }
}

// 定位权限
LocationService.shared.requestAuthorizationOrOpenSettings()
// - .notDetermined → 请求权限
// - .denied/.restricted → 打开系统设置（x-apple.systempreferences:）
// - .authorized → 开始定位
```

**系统设置跳转：**
```swift
// 隐私与安全性 → 定位服务
let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_LocationServices")
NSWorkspace.shared.open(url!)
```

#### 5. 性能优化策略

**缓存策略：**
- `EventCacheManager` 使用 `NSCache`（自动内存管理）
- 缓存键：`"events_\(startDate)_\(endDate)"`
- 缓存失效：设置变更、日历启用状态变更

**增量同步：**
- `IncrementalSyncService` 仅同步变更数据
- 基于 `lastModified` 时间戳判断
- 减少网络请求和 EventKit 查询

**离线优先：**
- `LocalStorageManager` 持久化订阅数据
- 优先读取本地缓存，后台异步更新
- 网络失败时展示缓存数据

---

## 开发指南

### 构建和运行

#### 使用 Xcode（推荐）

```bash
# 1. 打开项目
open /Users/lixingmao/Documents/Developer/WebSpace/mini-cal/MiniCal.xcodeproj

# 2. Xcode 中选择 MiniCal scheme
# 3. 点击 Run (⌘R) 或 Product → Run

# 清理构建缓存
# Product → Clean Build Folder (⇧⌘K)

# 重新构建
# Product → Build (⌘B)
```

#### 使用 xcodebuild（命令行）

```bash
cd /Users/lixingmao/Documents/Developer/WebSpace/mini-cal

# 构建 Debug 版本
xcodebuild -project MiniCal.xcodeproj \
  -scheme MiniCal \
  -configuration Debug \
  build

# 构建 Release 版本
xcodebuild -project MiniCal.xcodeproj \
  -scheme MiniCal \
  -configuration Release \
  build

# 查看可用 schemes
xcodebuild -list -project MiniCal.xcodeproj

# 运行（需要 Xcode）
xcodebuild -project MiniCal.xcodeproj \
  -scheme MiniCal \
  -configuration Debug \
  run
```

**构建产物位置：**
```
~/Library/Developer/Xcode/DerivedData/MiniCal-*/Build/Products/Debug/MiniCal.app
```

**验证本地化文件：**
```bash
cd ~/Library/Developer/Xcode/DerivedData/MiniCal-*/Build/Products/Debug/MiniCal.app/Contents/Resources

# 应该看到 13 个 .lproj 文件夹
ls -la *.lproj/

# 验证 Info.plist 存在
ls -la *.lproj/Info.plist
```

### 依赖管理

项目使用 **Swift Package Manager** 管理依赖：

```swift
// Package.swift 中定义的依赖（在 Xcode 中自动管理）
dependencies: [
    .package(url: "https://github.com/sindresorhus/KeyboardShortcuts", from: "2.4.0"),
    .package(url: "https://github.com/ceeK/Solar", from: "3.0.1"),
    .package(url: "https://github.com/batoulapps/adhan-swift", from: "1.4.0"),
    .package(url: "https://github.com/6tail/lunar-swift", from: "1.1.8"),
]
```

**更新依赖：**
```
Xcode → File → Packages → Update to Latest Package Versions
```

**解决依赖问题：**
```
Xcode → File → Packages → Reset Package Caches
```

### 调试技巧

#### 1. 查看日志

**Console.app（推荐）:**
```bash
# 打开 Console.app
open -a Console

# 过滤日志（按进程）
进程：MiniCal

# 过滤日志（按子系统）
子系统：com.minical.app
类别：app / calendar / event / network / service / ui
```

**终端查看实时日志：**
```bash
log stream --predicate 'subsystem == "com.minical.app"' --level debug
```

#### 2. 断点调试

- 在 Xcode 中设置断点（点击行号左侧）
- 常用断点位置：
  - `MenuBarController.swift:60` - 菜单栏点击
  - `CalendarViewModel.swift:120` - 月份切换
  - `EventService.swift:50` - 事件获取
  - `LocationService.swift:75` - 权限请求

#### 3. SwiftUI 预览

大部分视图支持 Xcode 预览：

```swift
#Preview {
    CalendarView()
        .environmentObject(CalendarViewModel())
        .environmentObject(MenuBarViewModel())
}
```

**注意：** 预览可能需要模拟数据，部分依赖 EventKit 的视图无法预览。

### 测试多语言

#### 1. 测试本地化字符串

```bash
# 在 Xcode 中切换语言
Product → Scheme → Edit Scheme → Run → Options → App Language
```

选择目标语言（ar, en, fa, he, ja, ko, th, tr, ur, vi, zh-Hans, zh-Hant）后运行。

#### 2. 测试权限对话框本地化

```bash
# 1. 系统设置 → 语言与地区 → 添加目标语言
# 2. 设为首选语言并重启应用
# 3. 删除应用权限（隐私与安全性 → 移除 MiniCal）
# 4. 重新运行应用，查看权限对话框语言
```

#### 3. 验证 RTL 布局

```bash
# 测试阿拉伯语 / 希伯来语 / 波斯语 / 乌尔都语
# 布局应自动从右到左镜像
```

---

## 常见任务

### 添加新的本地化语言

#### 1. 在 Xcode 中添加语言

```
1. 选择项目根节点 MiniCal（蓝色图标）
2. PROJECT → MiniCal → Info 标签
3. Localizations 部分 → 点击 + 按钮
4. 选择新语言（例如：French - fr）
5. 勾选 Info.plist
6. 点击 Finish
```

#### 2. 创建本地化 Info.plist

Xcode 会自动创建 `fr.lproj/Info.plist`，手动翻译 4 个权限描述：

```xml
<key>NSCalendarsUsageDescription</key>
<string>MiniCal a besoin d'accéder à votre calendrier pour afficher les réunions et événements.</string>

<key>NSCalendarsFullAccessUsageDescription</key>
<string>MiniCal nécessite un accès complet à votre calendrier pour synchroniser et gérer les événements, s'abonner aux calendriers externes.</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>MiniCal a besoin de votre emplacement pour calculer les heures de lever et coucher du soleil, les heures de prière islamiques et le Shabbat hébraïque.</string>

<key>NSLocationUsageDescription</key>
<string>MiniCal utilise votre emplacement pour fournir des informations astronomiques précises (heures de lever et coucher du soleil, phases lunaires) et horaires religieux (heures de prière, Shabbat).</string>
```

#### 3. 更新 .xcstrings 文件

在 Xcode 中打开 `Localizable.xcstrings`：

```
1. 点击 + 按钮添加新语言（French）
2. 翻译所有字符串条目
3. 重复对 CalendarNames.xcstrings 和 Festivals.xcstrings
```

#### 4. 验证

```bash
# 清理并重新构建
Product → Clean Build Folder (⇧⌘K)
Product → Build (⌘B)

# 验证构建产物
cd ~/Library/Developer/Xcode/DerivedData/MiniCal-*/Build/Products/Debug/MiniCal.app/Contents/Resources
ls -la fr.lproj/Info.plist  # 应该存在
```

### 添加新主题

#### 1. 编辑 themes.json

```json
{
  "themes": [
    {
      "id": "my-custom-theme",
      "name": "我的主题",
      "colors": {
        "background": "#1E1E1E",
        "text": "#D4D4D4",
        "primary": "#007ACC",
        "secondary": "#3E3E42",
        "accent": "#F48771",
        "border": "#3E3E42",
        "selectedBackground": "#37373D",
        "selectedText": "#FFFFFF",
        "todayBackground": "#007ACC",
        "todayText": "#FFFFFF",
        "weekendText": "#CE9178",
        "disabledText": "#6A6A6A",
        "eventIndicator": "#4EC9B0"
      }
    }
  ]
}
```

#### 2. 重启应用

```bash
# 主题在应用启动时加载
# 无需重新编译，直接重启应用即可
```

#### 3. 在设置中应用

```
设置 → 主题 → 选择 "我的主题"
```

### 添加新的日历类型

#### 1. 扩展 CalendarType 枚举

`Models/CalendarType.swift`:

```swift
enum CalendarType: String, CaseIterable, Codable, Identifiable {
    case chinese = "chinese"
    case islamic = "islamic"
    case hebrew = "hebrew"
    case japanese = "japanese"
    case persian = "persian"
    case buddhist = "buddhist"
    case myNewCalendar = "my_new_calendar"  // ← 添加

    var id: String { rawValue }
    var localizedName: String {
        switch self {
        case .myNewCalendar: return "calendar.my_new_calendar".localized()
        // ...
        }
    }
}
```

#### 2. 实现转换逻辑

`Services/CalendarEngine/SecondaryCalendarConverter.swift`:

```swift
func convert(gregorianDate: Date, to calendar: CalendarType) async -> SecondaryDateInfo? {
    switch calendar {
    case .myNewCalendar:
        return convertToMyNewCalendar(gregorianDate)
    // ...
    }
}

private func convertToMyNewCalendar(_ date: Date) -> SecondaryDateInfo {
    // 实现转换逻辑
    // 返回 SecondaryDateInfo(year: ..., month: ..., day: ...)
}
```

#### 3. 添加本地化字符串

`Resources/Localizations/CalendarNames.xcstrings`:

```json
{
  "calendar.my_new_calendar": {
    "localizations": {
      "en": { "stringUnit": { "value": "My New Calendar" } },
      "zh-Hans": { "stringUnit": { "value": "我的新日历" } }
    }
  }
}
```

### 处理权限拒绝

**日历权限被拒绝：**

SettingsView.swift:523 已实现引导到系统设置：

```swift
Button("permission.calendar_denied_action".localized()) {
    if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
        NSWorkspace.shared.open(url)
    }
}
```

**定位权限被拒绝：**

DayEventHeader.swift:127-143 已实现：

```swift
Button(action: {
    locationService.requestAuthorizationOrOpenSettings()
}) {
    HStack(spacing: 3) {
        Image(systemName: "location.slash")
        Text("location.enable_for_sunset")
    }
}
.focusable(false)  // 移除焦点环
```

`LocationService.requestAuthorizationOrOpenSettings()` 会根据状态：
- `.notDetermined` → 请求权限
- `.denied/.restricted` → 打开系统设置

---

## 编码规范

### SOLID 原则

**Single Responsibility（单一职责）：**
- ✅ CalendarService 仅生成日历数据
- ✅ EventService 仅聚合事件数据
- ✅ ThemeManager 仅管理主题

**Open/Closed（开闭原则）：**
- ✅ 使用协议扩展新功能（`CalendarEventServiceProtocol`）
- ✅ 主题通过 JSON 配置，无需修改代码

**Liskov Substitution（里氏替换）：**
- ✅ 所有 CalendarEventService 实现可互换
- ✅ SystemCalendarService / ExternalCalendarService / LocalEventGroupService 遵循同一协议

**Interface Segregation（接口隔离）：**
- ✅ 小而专注的协议（`ColorManagementServiceProtocol`）
- ✅ 避免臃肿接口

**Dependency Inversion（依赖反转）：**
- ✅ ViewModel 依赖 Service 协议，而非具体实现
- ✅ 依赖注入（构造函数注入）

### 代码风格

**命名规范：**
- 类型：PascalCase（`CalendarViewModel`, `EventService`）
- 变量/函数：camelCase（`currentMonth`, `loadCurrentMonth()`）
- 常量：大写或 PascalCase（`Constants.maxCacheSize`）

**注释要求：**
- 复杂逻辑必须添加注释（中文或英文）
- 公开 API 使用文档注释（`///`）
- 使用 `// MARK: -` 分隔代码段

```swift
// MARK: - Setup

/// 生成指定月份的日历数据
/// - Parameters:
///   - date: 目标月份的任意日期
///   - secondaryCalendar: 可选的副历类型
/// - Returns: 日历日期数组
func generateMonth(for date: Date, secondaryCalendar: CalendarType? = nil) async -> [CalendarDate] {
    // 实现...
}
```

**SwiftUI 风格：**
- 优先使用 `@State`, `@Binding`, `@ObservedObject`, `@EnvironmentObject`
- 拆分大视图为小组件（DRY 原则）
- 使用 `ViewBuilder` 简化条件渲染

```swift
@ViewBuilder
private var sunTimesView: some View {
    if !locationService.locationAuthorized {
        Button(action: { /* ... */ }) {
            // 未授权视图
        }
        .focusable(false)
    } else if let sunTimes = /* ... */ {
        // 已授权视图
    }
}
```

### 错误处理

**使用 MiniCalError：**

```swift
enum MiniCalError: LocalizedError {
    case networkError(Error)
    case parseError(String)
    case permissionDenied

    var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .parseError(let message):
            return "Parse error: \(message)"
        case .permissionDenied:
            return "Permission denied"
        }
    }
}
```

**错误日志：**

```swift
do {
    let events = try await fetchEvents()
} catch {
    Logger.error("Failed to fetch events: \(error)", category: Logger.network)
    throw MiniCalError.networkError(error)
}
```

---

## 故障排查

### 问题：Xcode 无法识别本地化文件

**症状：** Info.plist 在 Project Navigator 中不显示为可展开组

**解决：**
1. 确认项目使用 "Localize..." 方法（完整 Info.plist）
2. 检查 project.pbxproj 是否有 `membershipExceptions = ("/Localized: Info.plist")`
3. 清理并重新构建：
   ```
   Product → Clean Build Folder (⇧⌘K)
   Product → Build (⌘B)
   ```

### 问题：权限对话框未显示本地化

**症状：** 系统语言切换后，权限对话框仍显示中文

**解决：**
1. 确认 `*.lproj/Info.plist` 文件存在且包含翻译
2. 删除应用权限：
   ```
   系统设置 → 隐私与安全性 → 日历/定位服务 → 移除 MiniCal
   ```
3. 重新运行应用触发权限请求

### 问题：主题未生效

**症状：** 应用主题后界面未变化

**解决：**
1. 检查 `Resources/Themes/themes.json` 格式正确
2. 确认主题 ID 无重复
3. 重启应用（主题在启动时加载）
4. 查看日志：
   ```bash
   log stream --predicate 'subsystem == "com.minical.app" && category == "app"' | grep -i theme
   ```

### 问题：事件未显示

**症状：** 日历中看不到系统日历事件

**解决：**
1. 检查日历权限：
   ```
   系统设置 → 隐私与安全性 → 日历 → MiniCal 已授权
   ```
2. 在设置中启用目标日历：
   ```
   MiniCal 设置 → 日历订阅 → 勾选对应日历
   ```
3. 手动同步：
   ```
   设置 → 日历订阅 → 点击刷新按钮
   ```
4. 查看日志：
   ```bash
   log stream --predicate 'subsystem == "com.minical.app" && category == "event"'
   ```

### 问题：定位服务无响应

**症状：** 点击"启用定位"按钮后无反应

**解决：**
1. 检查定位服务是否全局启用：
   ```
   系统设置 → 隐私与安全性 → 定位服务 → 开启
   ```
2. 查看日志确认权限状态：
   ```bash
   log stream --predicate 'subsystem == "com.minical.app"' | grep -i location
   ```
3. 如已拒绝，按钮应打开系统设置（检查 URL scheme）

---

## 性能优化检查清单

- [ ] **NSCache 使用正确**：EventCacheManager 缓存大量事件数据
- [ ] **避免重复计算**：CalendarService 缓存月份数据
- [ ] **异步操作**：所有网络请求和 EventKit 查询使用 `async/await`
- [ ] **批量操作**：一次性获取月度事件，而非逐日查询
- [ ] **增量同步**：仅同步变更的订阅数据
- [ ] **延迟加载**：事件列表按需加载详情
- [ ] **内存警告处理**：清理缓存（EventCacheManager.clearCache()）

---

## 发布清单

### 发布前检查

- [ ] 所有警告已解决（Build Settings → Warnings → Treat Warnings as Errors）
- [ ] 13 种语言本地化完整（Info.plist + .xcstrings）
- [ ] 版本号已更新（Info.plist → CFBundleShortVersionString）
- [ ] Build 号递增（CFBundleVersion）
- [ ] 应用图标齐全（Assets.xcassets → AppIcon）
- [ ] 签名配置正确（Signing & Capabilities → Team）
- [ ] 隐私描述完整（Info.plist 权限描述）
- [ ] Release 构建测试通过

### 构建 Release 版本

```bash
# 1. 清理
xcodebuild clean -project MiniCal.xcodeproj -scheme MiniCal -configuration Release

# 2. 归档（Archive）
xcodebuild archive \
  -project MiniCal.xcodeproj \
  -scheme MiniCal \
  -configuration Release \
  -archivePath ~/Desktop/MiniCal.xcarchive

# 3. 导出 .app
xcodebuild -exportArchive \
  -archivePath ~/Desktop/MiniCal.xcarchive \
  -exportPath ~/Desktop/MiniCal-Release \
  -exportOptionsPlist ExportOptions.plist
```

**ExportOptions.plist 示例：**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>mac-application</string>
    <key>teamID</key>
    <string>YOUR_TEAM_ID</string>
</dict>
</plist>
```

### 公证和分发

```bash
# 1. 公证（Notarize）
xcrun notarytool submit MiniCal.app --apple-id YOUR_APPLE_ID --team-id YOUR_TEAM_ID --wait

# 2. 装订公证票据
xcrun stapler staple MiniCal.app

# 3. 创建 DMG
hdiutil create -volname "MiniCal" -srcfolder MiniCal.app -ov -format UDZO MiniCal.dmg
```

---

## 资源和参考

### 官方文档

- [EventKit Framework](https://developer.apple.com/documentation/eventkit) - 日历和提醒事项访问
- [CoreLocation](https://developer.apple.com/documentation/corelocation) - 定位服务
- [SwiftUI](https://developer.apple.com/documentation/swiftui) - 声明式 UI 框架
- [AppKit](https://developer.apple.com/documentation/appkit) - macOS 原生 UI 组件

### 外部库文档

- [KeyboardShortcuts](https://github.com/sindresorhus/KeyboardShortcuts) - 全局快捷键实现
- [Solar](https://github.com/ceeK/Solar) - 日出日落计算算法
- [Adhan](https://github.com/batoulapps/adhan-swift) - 伊斯兰祈祷时间计算
- [LunarSwift](https://github.com/6tail/lunar-swift) - 农历和节气计算

### 项目特定文档

- `README.md` - 项目简介和功能特性
- `/tmp/localization_completion_summary.md` - 本地化工作总结（临时文件）

---

## 附录

### 系统权限说明

**日历权限（NSCalendarsUsageDescription）：**
- 用途：读取系统日历事件，展示在 MiniCal 界面
- 触发时机：首次启动或点击"授权日历访问"
- 拒绝后果：无法展示系统日历事件（外部订阅和本地管理不受影响）

**日历完全访问（NSCalendarsFullAccessUsageDescription）：**
- 用途：macOS 14+ 需要完全访问权限以修改事件
- 触发时机：创建或编辑事件时
- 拒绝后果：只读模式，无法创建/编辑事件

**定位权限（NSLocationWhenInUseUsageDescription）：**
- 用途：计算日出日落、祈祷时间、安息日时间
- 触发时机：点击"启用定位"按钮
- 拒绝后果：无法显示天文信息和宗教时间

### 快捷键

**全局快捷键（可自定义）：**
- 默认：`⌥⌘C` - 显示/隐藏 MiniCal 弹窗
- 设置：MiniCal 设置 → 快捷键

**菜单栏交互：**
- 左键点击：显示/隐藏弹窗
- 右键点击：显示上下文菜单
- 鼠标悬浮 500ms：自动显示弹窗（可设置禁用）

**日历导航：**
- `←` / `→`：上/下月
- `↑` / `↓`：上/下年
- `T` / `Esc`：回到今天

### 故障恢复

**重置所有设置：**
```bash
defaults delete com.yourteam.MiniCal
```

**清除缓存：**
```bash
rm -rf ~/Library/Caches/com.yourteam.MiniCal
```

**重置权限（需要手动）：**
```
系统设置 → 隐私与安全性 → 移除 MiniCal → 重新启动应用
```

---

**最后更新：** 2025-12-03
**文档版本：** 1.0.0
**项目版本：** 1.0 (Build 1)
