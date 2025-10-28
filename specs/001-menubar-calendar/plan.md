# Implementation Plan: MacOS菜单栏日历应用

**Branch**: `001-menubar-calendar` | **Date**: 2025-10-27 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-menubar-calendar/spec.md`

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

构建一个原生MacOS菜单栏日历应用，提供持续可见的日期时间显示和可展开的月视图。核心特性包括副日历支持（全球主流历法）、日期状态标记（彩色圆点）、主题定制和完整的用户设置。技术栈采用Swift 5.9 + SwiftUI，遵循macOS原生设计规范，确保性能优化和用户体验。

## Technical Context

**Language/Version**: Swift 5.9+
**Primary Dependencies**: SwiftUI, AppKit (菜单栏集成), EventKit (日历访问)
**Storage**: UserDefaults (设置持久化), 本地JSON数据库 (节假日数据)
**Testing**: XCTest (单元测试), XCUITest (UI测试)
**Target Platform**: macOS 11.0 (Big Sur) 或更高版本
**Project Type**: single (MacOS桌面应用)
**Performance Goals**: UI响应 <300ms, 月视图切换 <200ms, 主题切换 <200ms, 内存占用 <50MB, 空闲CPU <1%
**Constraints**: 离线可用 (副日历算法本地计算), 必须遵循macOS人机界面指南, 支持系统外观模式切换
**Scale/Scope**: 7个核心用户场景, 20个功能需求, 6+种副日历支持, 3个主题

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design and implementation.*

**Constitution Reference**: See `.specify/memory/constitution.md` (Version 1.0.0, Ratified 2025-10-28)

### 核心原则验证 (基于 Constitution v1.0.0)

| Constitution 原则 | 状态 | 验证说明 |
|------------------|------|---------|
| **I. Native-First** | ✅ PASS | Swift 5.9+ + SwiftUI + AppKit, 无第三方依赖, 遵循 macOS HIG |
| **II. Performance-First** | ✅ PASS | 性能目标明确量化: UI<300ms, 月切换<200ms, 主题<200ms, 内存<50MB, CPU<1% |
| **III. Simplicity & YAGNI** | ✅ PASS | 仅实现 spec.md 定义功能, 无范围外特性, 优先 SwiftUI 内置组件 |
| **IV. Modularity & Testability** | ✅ PASS | MVVM架构, 清晰分层(Views/ViewModels/Services/Models), 协议+依赖注入 |
| **V. Data Integrity & Offline-First** | ✅ PASS | 本地算法+JSON数据, UserDefaults持久化, 无网络依赖 |
| **VI. User Experience Excellence** | ✅ PASS | 遵循 macOS 交互模式, 标准快捷键, 优雅降级, 屏幕边缘适配, VoiceOver支持 |
| **VII. Code Quality Standards** | ✅ PASS | Swift API Guidelines, 命名规范, 文档注释, 避免强制解包, Codable协议 |

### 性能标准验证

| 性能指标 | Constitution 要求 | Plan 设计 | 验证方法 | 状态 |
|---------|------------------|----------|---------|------|
| 菜单栏点击响应 | < 300ms | ✅ 优化设计 | Instruments Time Profiler | ✅ 可达 |
| 月视图切换 | < 200ms | ✅ NSCache缓存 | Instruments Time Profiler | ✅ 可达 |
| 主题切换 | < 200ms | ✅ 预加载主题 | 手动测试 + 秒表 | ✅ 可达 |
| 内存占用 | < 50MB | ✅ 轻量设计 | Instruments Allocations | ✅ 可达 |
| 空闲CPU | < 1% | ✅ Timer优化 | Activity Monitor | ✅ 可达 |

### 平台集成验证

| 系统服务 | Constitution 要求 | Plan 实现 | 状态 |
|---------|------------------|----------|------|
| NSStatusBar | NSStatusItem + LSUIElement | ✅ MenuBarController | ✅ PASS |
| EventKit | requestAccess + 优雅降级 | ✅ EventService | ✅ PASS |
| NSAppearance | 观察系统外观变化 | ✅ ThemeManager | ✅ PASS |
| Locale | 自动推荐副日历 | ✅ SecondaryCalendarConverter | ✅ PASS |

### 实施验证 (基于会话历史 2025-10-28)

**实施阶段**: Phases 1-6 已完成, 正在进行 Phase 8-10 优化

| 已实施功能 | Constitution 合规性 | 发现的调整 |
|-----------|------------------|-----------|
| **Phase 1-2: 基础设施** | ✅ PASS | 遵循 MVVM, 所有模型使用 Codable |
| **Phase 3: 菜单栏显示** | ✅ PASS | MenuBarViewModel 使用单例模式 (SettingsManager.shared) 确保状态同步 |
| **Phase 4: 月视图展开** | ✅ PASS | 左键/右键/悬浮交互已修复, 通过编程方式显示右键菜单避免冲突 |
| **Phase 5: 副日历显示** | ✅ PASS | 使用 Foundation.Calendar API, 支持6+种历法 |
| **Phase 6: 日期状态标记** | ✅ PASS | EventKit 优雅降级, HolidayProvider 本地 JSON |
| **设置项保存机制** | ✅ PASS | SettingsManager 单例模式, UserDefaults 持久化, onChange 自动保存 |
| **Glass 主题兼容** | ✅ PASS | NSVisualEffectView wrapper, 遵循 macOS 26 设计规范 |
| **自定义格式输入** | ✅ PASS | 输入态/展示态切换, 格式说明完整, 包含周数支持 |
| **秒显示控制** | ✅ PASS | UserSettings.showSeconds, 自定义格式时禁用其他选项 |

### 发现的优化调整

**已修复的 Constitution 违规**:
1. ✅ **单例模式**: SettingsManager 改为单例避免多实例状态不一致
2. ✅ **菜单栏交互**: 修正左键/右键事件处理, 避免 statusItem.menu 冲突
3. ✅ **性能优化**: 添加 Timer 优化, 避免每秒更新（仅在有秒显示时优化）

**符合 Simplicity & YAGNI**:
- 未实现范围外功能（无日视图、无事件编辑、无云同步）
- 优先使用 SwiftUI 内置组件（Toggle, Picker, Slider, TextField）
- 避免过度设计（单例仅在必要时使用）

### 边缘情况处理验证

| 边缘情况 | Constitution 要求 | 实施状态 |
|---------|------------------|---------|
| 屏幕边缘适配 | MUST 自动调整位置 | ⚠️ 待补充测试任务 (T168) |
| 时区变更 | MUST 自动更新显示 | ⚠️ 待补充测试任务 (T169) |
| EventKit 权限拒绝 | MUST 优雅降级 | ✅ EventService 已实现 |
| 快速点击防抖 | MUST 避免闪烁 | ✅ CalendarViewModel 已实现 |
| 副日历跨天 | MUST 正确显示 | ⚠️ 待补充测试任务 (T073.4) |
| 首次启动推荐 | MUST 自动推荐副日历 | ⚠️ 待补充任务 (T073.1, FR-019) |
| 设置加载失败 | MUST 使用默认配置 | ✅ SettingsManager.default 已实现 |

**结论**: ✅ **高度符合 Constitution 要求**, 发现 3 个边缘情况需补充测试任务（非阻塞）。

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
MiniCal/                          # Xcode项目根目录
├── MiniCal.xcodeproj/            # Xcode项目文件
├── MiniCal/                      # 主应用源代码
│   ├── App/
│   │   ├── MiniCalApp.swift     # 应用入口点
│   │   └── AppDelegate.swift    # macOS应用委托
│   ├── Views/
│   │   ├── MenuBar/
│   │   │   ├── MenuBarView.swift           # 菜单栏UI
│   │   │   └── MenuBarViewModel.swift
│   │   ├── Calendar/
│   │   │   ├── CalendarPopoverView.swift   # 日历浮窗
│   │   │   ├── CalendarMonthView.swift     # 月视图
│   │   │   ├── CalendarDayCell.swift       # 日期单元格
│   │   │   └── CalendarViewModel.swift
│   │   └── Settings/
│   │       ├── SettingsView.swift          # 设置窗口
│   │       ├── SettingsViewModel.swift
│   │       ├── MenuBarSettingsView.swift   # 菜单栏设置
│   │       └── ThemeSettingsView.swift     # 主题设置
│   ├── Models/
│   │   ├── CalendarDate.swift              # 日期模型
│   │   ├── SecondaryCalendar.swift         # 副日历模型
│   │   ├── DateEvent.swift                 # 日期事件
│   │   ├── Theme.swift                     # 主题模型
│   │   └── UserSettings.swift              # 用户设置
│   ├── Services/
│   │   ├── CalendarEngine/
│   │   │   ├── CalendarEngine.swift        # 日历核心引擎
│   │   │   ├── SecondaryCalendarConverter.swift # 副日历转换
│   │   │   └── HolidayProvider.swift       # 节假日数据
│   │   ├── EventService.swift              # EventKit集成
│   │   ├── ThemeManager.swift              # 主题管理
│   │   └── SettingsManager.swift           # 设置管理
│   ├── Resources/
│   │   ├── Assets.xcassets/                # 图标和图片资源
│   │   ├── Themes/                         # 主题配置JSON
│   │   └── Holidays/                       # 节假日数据JSON
│   └── Utilities/
│       ├── Extensions/
│       │   ├── Date+Extensions.swift
│       │   └── Calendar+Extensions.swift
│       └── Constants.swift
├── MiniCalTests/                 # 单元测试
│   ├── Models/
│   ├── Services/
│   └── ViewModels/
└── MiniCalUITests/               # UI测试
    ├── MenuBarTests/
    ├── CalendarTests/
    └── SettingsTests/
```

**Structure Decision**: 采用标准的macOS SwiftUI应用结构,使用MVVM架构模式。
- **Views/**: SwiftUI视图组件,按功能模块分组 (MenuBar, Calendar, Settings)
- **Models/**: 数据模型,遵循Codable协议支持持久化
- **Services/**: 业务逻辑和系统集成服务
- **Resources/**: 静态资源文件(主题配置、节假日数据)
- **Tests/**: 完整的单元测试和UI测试覆盖

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
