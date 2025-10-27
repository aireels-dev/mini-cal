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

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### 架构原则验证

| 原则 | 状态 | 说明 |
|------|------|------|
| **模块化设计** | ✅ PASS | 应用分为明确的模块: MenuBarView, CalendarView, SettingsView, CalendarEngine, ThemeManager |
| **关注点分离** | ✅ PASS | UI层(SwiftUI)、业务逻辑层(Services)、数据层(Models)清晰分离 |
| **可测试性** | ✅ PASS | 采用MVVM架构,ViewModel可独立测试,业务逻辑与UI解耦 |
| **平台原生性** | ✅ PASS | 使用SwiftUI + AppKit,完全遵循macOS原生API和设计规范 |
| **性能优先** | ✅ PASS | 明确性能目标(<300ms响应,<50MB内存),使用本地计算避免网络延迟 |

### 复杂度评估

| 指标 | 评估 | 合理性 |
|------|------|--------|
| **依赖数量** | 低 | 仅依赖系统框架(SwiftUI, AppKit, EventKit),无第三方依赖 |
| **模块数量** | 适中 | 约8-10个核心模块,每个职责单一 |
| **API复杂度** | 低 | 主要是UI交互和本地数据操作,无复杂网络通信 |
| **数据流** | 简单 | 单向数据流(SwiftUI Binding),状态管理清晰 |

### 风险识别

| 风险 | 影响 | 缓解措施 |
|------|------|----------|
| **副日历算法复杂性** | 中 | 使用成熟算法库或Foundation框架的Calendar API |
| **EventKit权限处理** | 低 | 优雅降级:权限拒绝时仅显示基础日历功能 |
| **性能优化** | 低 | SwiftUI原生优化足够,月视图数据量小(最多42个单元格) |

**结论**: ✅ 通过 - 架构设计合理,无明显复杂度风险,可以进入Phase 0研究阶段。

---

### Phase 1完成后重新评估

**评估日期**: 2025-10-27
**评估阶段**: Phase 1 (Design & Contracts) 完成

| 检查项 | 状态 | 说明 |
|--------|------|------|
| **数据模型设计** | ✅ PASS | 11个核心实体,职责清晰,遵循Codable协议 |
| **服务接口定义** | ✅ PASS | 6个核心服务协议,支持依赖注入和单元测试 |
| **架构一致性** | ✅ PASS | MVVM模式贯穿全栈,符合SwiftUI最佳实践 |
| **性能目标可达** | ✅ PASS | 缓存策略+防抖+批量处理,预期满足<300ms要求 |
| **测试策略** | ✅ PASS | 每个服务提供Protocol和Mock实现,支持单元测试 |
| **复杂度控制** | ✅ PASS | 无第三方依赖,模块数量适中(8-10个) |

**结论**: ✅ 设计阶段验证通过,准备进入Phase 2 (任务分解)。无架构违规,无需填充"Complexity Tracking"表格。

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
