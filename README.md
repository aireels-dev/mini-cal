# MiniCal - macOS 菜单栏日历应用

一个现代化、简洁优雅的 macOS 菜单栏日历应用，支持多日历系统、节日提醒和主题定制。

## 项目状态

**当前版本**: v1.0
**完成度**: 100% (所有核心功能已实现)
**构建状态**: ✅ BUILD SUCCEEDED
**最后更新**: 2025-10-28

## 功能特性

### 核心功能

- **📅 菜单栏日期时间显示**
  - 实时更新的日期时间
  - 多种预设格式（紧凑/标准/完整）
  - 自定义格式支持
  - 24小时制切换
  - 显示/隐藏星期和秒数

- **🗓️ 月视图日历**
  - 完整的月份日历网格
  - 今天日期高亮
  - 流畅的月份切换
  - 快速跳转到今天
  - 鼠标悬浮显示（可选）

- **🌏 多日历系统支持**
  - 农历（中国）- 支持节气和传统节日
  - 佛历
  - 伊斯兰历
  - 希伯来历
  - 日本历

- **🎉 节假日和事件**
  - 内置中国节假日数据
  - 系统日历事件集成
  - 彩色圆点标记
  - 事件详情查看

- **🎨 主题系统**
  - 跟随系统（自动切换）
  - 浅色主题
  - 深色主题
  - 玻璃主题（毛玻璃效果）

### 技术特性

- **性能优化**
  - UI 响应时间 < 300ms
  - 月视图切换 < 200ms
  - 主题切换 < 200ms
  - 内存占用 < 50MB
  - 空闲 CPU < 1%

- **代码质量**
  - 0 编译警告
  - 内存泄漏全部修复
  - 统一日志系统（os.log）
  - SwiftUI 最佳实践
  - MVVM 架构

## 技术栈

- **语言**: Swift 5.9+
- **UI框架**: SwiftUI + AppKit
- **系统集成**: NSStatusBar, NSPopover, EventKit
- **日历引擎**: Foundation.Calendar
- **主题系统**: JSON配置 + 动态加载
- **日志**: os.log

## 项目结构

```
MiniCal/
├── MiniCal/
│   ├── App/                      # 应用入口和控制器
│   │   ├── MiniCalApp.swift
│   │   ├── AppDelegate.swift
│   │   └── MenuBarController.swift
│   ├── Views/                    # SwiftUI视图
│   │   ├── MenuBarView.swift
│   │   ├── CalendarView.swift
│   │   ├── CalendarHeaderView.swift
│   │   ├── CalendarGridView.swift
│   │   ├── CalendarDayCell.swift
│   │   ├── EventDetailView.swift
│   │   ├── SettingsView.swift
│   │   └── VisualEffectView.swift
│   ├── ViewModels/               # MVVM视图模型
│   │   ├── MenuBarViewModel.swift
│   │   └── CalendarViewModel.swift
│   ├── Models/                   # 数据模型
│   │   ├── MenuBarFormat.swift
│   │   ├── UserSettings.swift
│   │   ├── CalendarDate.swift
│   │   ├── DateEvent.swift
│   │   ├── Theme.swift
│   │   └── ...
│   ├── Services/                 # 业务逻辑层
│   │   ├── CalendarService.swift
│   │   ├── EventService.swift
│   │   ├── SettingsManager.swift
│   │   ├── ThemeManager.swift
│   │   ├── CalendarEngine/
│   │   │   ├── SecondaryCalendarConverter.swift
│   │   │   └── HolidayProvider.swift
│   │   └── ...
│   ├── Resources/                # 静态资源
│   │   ├── Assets.xcassets/
│   │   ├── Themes/
│   │   │   └── themes.json
│   │   └── Holidays/
│   │       └── CN.json
│   ├── Utilities/                # 工具类和扩展
│   │   ├── Logger.swift
│   │   ├── AppVersion.swift
│   │   ├── Constants.swift
│   │   └── Extensions/
│   └── Info.plist
└── specs/                        # 功能规格文档
    └── 001-menubar-calendar/
        ├── spec.md
        ├── plan.md
        ├── tasks.md
        ├── quickstart.md
        └── ...
```

## 快速开始

### 系统要求

- macOS 11.0 或更高版本
- Xcode 15.0+ （用于编译）

### 编译和运行

```bash
# 克隆仓库
git clone <repository-url>
cd mini-cal

# 切换到功能分支
git checkout 001-menubar-calendar

# 打开 Xcode 项目
open MiniCal/MiniCal.xcodeproj

# 在 Xcode 中按 Cmd+R 运行
```

### 授权日历访问（可选）

首次打开日历时，应用会请求访问系统日历的权限。如果需要查看日历事件，请授权访问。

如果不需要日历事件功能，可以拒绝授权，应用会优雅降级，仅显示基础日历信息。

## 使用说明

详细使用说明请参考 [用户指南](USER_GUIDE.md)

### 基本操作

- **左键点击菜单栏图标**：展开/收起日历
- **右键点击菜单栏图标**：打开菜单
- **鼠标悬浮**：可在设置中启用自动展开
- **月份切换**：使用日历头部的左右箭头
- **回到今天**：点击"今天"按钮
- **查看事件**：点击带圆点的日期

### 快捷键

- `⌘ ,` - 打开设置窗口
- `⌘ Q` - 退出应用
- `ESC` - 关闭日历浮窗

## 开发文档

- [功能规格](specs/001-menubar-calendar/spec.md) - 完整的功能需求说明
- [实施计划](specs/001-menubar-calendar/plan.md) - 架构设计和实施计划
- [任务清单](specs/001-menubar-calendar/tasks.md) - 详细的任务分解
- [快速开始](specs/001-menubar-calendar/quickstart.md) - 开发者快速上手指南
- [用户指南](USER_GUIDE.md) - 用户使用说明

## 性能指标

| 指标 | 目标 | 实际 |
|------|------|------|
| UI 响应时间 | < 300ms | ✅ 达标 |
| 月视图切换 | < 200ms | ✅ 达标 |
| 主题切换 | < 200ms | ✅ 达标 |
| 内存占用 | < 50MB | ✅ 达标 |
| 空闲 CPU | < 1% | ✅ 达标 |
| 启动时间 | < 1s | ✅ 达标 |

## 代码质量

- ✅ 0 编译警告
- ✅ 内存泄漏全部修复
- ✅ 遵循 SwiftUI 最佳实践
- ✅ 符合 macOS Human Interface Guidelines
- ✅ 统一的日志系统
- ✅ 完善的错误处理

## 架构原则

项目严格遵循 [Constitution](.specify/memory/constitution.md) 定义的7大核心原则：

1. **Native-First** - 纯 Swift/SwiftUI 实现
2. **Performance-First** - 性能优先，关键指标全面监控
3. **Simplicity-First (KISS)** - 避免过度设计
4. **Data Integrity** - 数据完整性保证
5. **Platform Integration** - 深度系统集成
6. **Code Quality** - 高代码质量标准
7. **Maintainability** - 可维护性优先

## 更新日志

### v1.0 (2025-10-28)

**核心功能**
- ✅ 菜单栏日期时间显示（多格式支持）
- ✅ 月视图日历浮窗
- ✅ 5种本地历法系统支持
- ✅ 节假日和系统事件集成
- ✅ 主题系统（4种主题）
- ✅ 完整设置界面

**质量改进**
- ✅ 统一日志系统（Logger）
- ✅ 性能监控和优化
- ✅ 内存泄漏修复
- ✅ 边缘情况处理（时区变更、快速切换防抖）
- ✅ 0 编译警告

**发布准备**
- ✅ 应用图标设计说明
- ✅ 启动优化
- ✅ 版本检查功能
- ✅ 关于窗口
- ✅ 用户指南文档

## 许可证

© 2025 MiniCal

## 致谢

- 使用 Foundation.Calendar API 进行日历计算
- EventKit 框架用于系统日历集成
- os.log 用于结构化日志
- SwiftUI 用于现代化 UI

---

**准备就绪，可以开始使用！** 🚀
