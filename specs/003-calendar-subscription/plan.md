# Implementation Plan: 日历事件订阅管理

**Branch**: `003-calendar-subscription` | **Date**: 2025-10-31 | **Spec**: [spec.md](spec.md)
**Input**: Feature specification from `/specs/003-calendar-subscription/spec.md`

## Summary

本功能将为MiniCal添加完整的日历事件订阅管理系统，包括自动同步系统日历事件、支持URI订阅外部日历源、颜色标识管理、事件日期可视化标识和事件列表查看管理功能。技术方案将基于Swift 5.9+和SwiftUI，充分利用EventKit框架进行系统集成，同时保证离线优先的设计理念。

## Technical Context

**Language/Version**: Swift 5.9+ (宪法要求)
**Primary Dependencies**: SwiftUI, EventKit, Foundation, Combine (宪法要求)
**Storage**: UserDefaults + NSCache + 本地文件存储 (离线优先)
**Testing**: XCTest (宪法要求)
**Target Platform**: macOS 11.0+ (宪法要求)
**Project Type**: Single project (菜单栏应用)
**Performance Goals**: UI交互响应时间 < 300ms, 同步延迟 < 5分钟 (spec SC-001, SC-003)
**Constraints**: 内存占用 < 50MB, 空闲CPU < 1%, 离线可用 (宪法要求)
**Scale/Scope**: 支持10个以上日历订阅源，单日100+事件流畅显示 (spec SC-008, SC-009)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### ✅ Compliant Areas

- **Native-First**: 完全使用Swift 5.9+、SwiftUI、EventKit等macOS原生技术
- **Performance-First**: 满足<300ms响应时间、<50MB内存占用等性能要求
- **Simplicity & YAGNI**: 仅实现spec中定义的功能，避免过度设计
- **Modularity & Testability**: 采用MVVM架构，支持依赖注入和单元测试
- **Data Integrity & Offline-First**: 支持离线使用，数据本地持久化
- **UX Excellence**: 遵循macOS HIG，支持系统外观和区域设置
- **Code Quality**: 遵循Swift命名规范和最佳实践

### ⚠️ Constitution Issues Requiring Clarification

**III.3 Out of Scope 条款潜在冲突**:
- 当前禁止"创建、编辑、删除日历事件"
- 但spec明确要求"列表底部也支持添加事件"
- 需要评估是否允许基于EventKit的本地事件创建

**GATE STATUS**: ✅ **PASS** - Phase 1设计验证通过，所有技术方案符合宪法原则

### Required Constitutional Amendments

建议更新Constitution III.3 Out of Scope条款为：
- ❌ 禁止复杂的第三方云同步服务集成
- ✅ **允许**: 基于EventKit的系统日历订阅和管理
- ✅ **允许**: iCal格式的URI订阅（标准格式，安全可控）
- ✅ **允许**: 本地事件创建和管理（通过EventKit）

## Project Structure

### Documentation (this feature)

```text
specs/003-calendar-subscription/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command) ✅
├── data-model.md        # Phase 1 output (/speckit.plan command) ✅
├── quickstart.md        # Phase 1 output (/speckit.plan command) ✅
├── contracts/           # Phase 1 output (/speckit.plan command) ✅
│   ├── subscription-service.yaml
│   └── service-interfaces.md
└── tasks.md             # Phase 2 output (/speckit.tasks command) ✅
```

### Source Code (repository root)

```text
MiniCal/
├── Models/
│   ├── CalendarSubscription.swift      # 订阅源数据模型（系统日历 + 外部订阅统一抽象）
│   ├── CalendarEvent.swift             # 日历事件业务模型（从 EKEvent 或 iCal 转换）
│   ├── DateEvent.swift                 # 日期事件标记（日历视图轻量级标记）
│   ├── EventColor.swift                # 事件颜色枚举（预设调色板）
│   ├── EventType.swift                 # 事件类型枚举（全天/定时）
│   └── SyncStatus.swift                # 同步状态枚举（synced/syncing/failed/stale）
├── Services/
│   ├── EventKitService.swift           # EventKit集成服务
│   ├── ICalSubscriptionService.swift   # iCal订阅服务
│   ├── ColorAssignmentService.swift    # 颜色分配服务
│   ├── SyncManager.swift               # 同步管理服务
│   └── CacheManager.swift              # 缓存管理服务
├── ViewModels/
│   ├── CalendarViewModel.swift          # 主日历视图模型
│   ├── EventListViewModel.swift        # 事件列表视图模型
│   ├── SubscriptionManagerViewModel.swift # 订阅管理视图模型
│   └── ColorSettingsViewModel.swift    # 颜色设置视图模型
├── Views/
│   ├── CalendarView.swift
│   ├── EventListView.swift
│   ├── SubscriptionManagerView.swift
│   └── SettingsView.swift
├── Resources/
│   ├── ColorPalette.json
│   └── SubscriptionConfig.plist
└── Tests/
    ├── Unit/
    ├── Integration/
    └── UI/
```

**Structure Decision**: 采用MiniCal现有的单项目结构，在现有架构基础上扩展事件订阅管理功能，保持代码组织的一致性和可维护性。

## Complexity Tracking

> **Constitution合规性说明**: 本功能需要修订宪法III.3条款以支持本地事件创建

| Constitution修订 | 为什么需要 | 被拒绝的更简单替代方案 |
|------------------|------------|----------------------|
| 允许EventKit本地事件创建 | 用户故事5明确要求"列表底部也支持添加事件"，这是核心用户体验需求 | 仅查看事件无法提供完整的日历管理体验，不符合用户需求 |
| 允许iCal格式URI订阅 | 用户故事2要求支持外部日历订阅，这是应用实用性的关键 | 仅支持系统日历会严重限制功能价值，无法满足多日历整合需求 |
