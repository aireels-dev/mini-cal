# MiniCal Constitution

## Core Principles

### I. Native-First (NON-NEGOTIABLE)

**所有功能必须使用 macOS 原生技术栈实现**

- **MUST** 使用 Swift 5.9+ 作为唯一开发语言
- **MUST** 使用 SwiftUI 作为主要 UI 框架，AppKit 仅用于菜单栏集成
- **MUST** 遵循 macOS Human Interface Guidelines (HIG)
- **MUST** 支持 macOS 11.0 (Big Sur) 或更高版本
- **MUST NOT** 引入第三方 UI 框架或非必要依赖
- **MUST** 使用 Foundation 提供的 Calendar API 进行日期计算
- **MUST** 通过 EventKit 访问系统日历（优雅降级，权限拒绝不影响基础功能）

**Rationale**: 确保应用性能最优、系统集成度最高、维护成本最低。

### II. Performance-First

**性能指标为不可协商的质量门槛**

- **MUST** UI 交互响应时间 < 300ms (SC-002)
- **MUST** 月视图切换响应时间 < 200ms (SC-007)
- **MUST** 主题切换完成时间 < 200ms (SC-005)
- **MUST** 应用内存占用 < 50MB (SC-008)
- **MUST** 空闲状态 CPU 占用率 < 1% (SC-008)
- **MUST** 使用缓存优化重复计算（NSCache for month data）
- **MUST** 批量处理本地历法转换（batchConvert）
- **MUST** 实现防抖逻辑避免快速操作导致的性能问题

**Verification**: 使用 Instruments (Time Profiler, Allocations, Leaks) 验证性能指标。

### III. Simplicity & YAGNI

**只实现 spec.md 中明确定义的功能**

- **MUST** 遵循 KISS 原则：优先选择最简单的解决方案
- **MUST** 遵循 YAGNI 原则：不实现未来"可能需要"的功能
- **MUST** 遵循 DRY 原则：消除重复代码，提取可复用组件
- **MUST NOT** 添加 spec.md 范围外的功能（除非经过正式规范修订）
- **MUST NOT** 过度设计架构或引入不必要的抽象层
- **SHOULD** 优先使用 SwiftUI 内置组件，避免自定义实现

**Out of Scope (明确禁止)**:
- 日视图、周视图、年视图
- 创建、编辑、删除日历事件
- 提醒和通知功能
- 第三方日历服务集成（Google Calendar、Outlook 等）
- 云同步和跨设备设置同步
- 自定义主题创建（仅预设主题）

### IV. Modularity & Testability

**代码必须可测试、可维护、可扩展**

- **MUST** 采用 MVVM 架构模式
- **MUST** 实现清晰的关注点分离：
  - **Views/**: SwiftUI 视图组件（UI 层）
  - **ViewModels/**: 业务逻辑和状态管理（展示层）
  - **Services/**: 系统集成和数据操作（服务层）
  - **Models/**: 数据模型（数据层）
- **MUST** 使用协议（Protocol）定义服务接口，支持依赖注入
- **MUST** 所有服务提供 Mock 实现用于单元测试
- **MUST** ViewModel 必须可独立测试，不依赖真实 UI
- **SHOULD** 每个模块职责单一，避免"上帝类"

**Testing Strategy**:
- 单元测试覆盖所有 ViewModel 和 Service 逻辑
- UI 测试覆盖关键用户路径（7个用户故事）
- 本项目不要求 TDD（测试在实现后增量添加）

### V. Data Integrity & Offline-First

**应用必须离线可用，数据可靠持久化**

- **MUST** 所有功能在无网络环境下正常工作
- **MUST** 本地历法计算使用本地算法（Foundation.Calendar + 自定义算法）
- **MUST** 节假日数据通过本地 JSON 文件提供
- **MUST** 用户设置通过 UserDefaults 持久化
- **MUST** 实现设置加载失败的降级策略（使用默认配置）
- **MUST** 保证设置更改立即生效，无需重启应用（SC-009）
- **MUST NOT** 依赖网络请求获取日历数据或配置

**Data Files**:
- `MiniCal/Resources/Holidays/*.json`: 节假日数据（CN, US 等）
- `MiniCal/Resources/Themes/themes.json`: 主题配置
- UserDefaults: 用户设置（MenuBarFormat, ThemeId, SecondaryCalendar 等）

### VI. User Experience Excellence

**用户体验优先，交互直观流畅**

- **MUST** 遵循 macOS 交互模式（菜单栏应用标准行为）
- **MUST** 支持标准快捷键（⌘+, 打开设置，ESC 关闭弹窗）
- **MUST** 实现优雅降级：EventKit 权限拒绝不影响基础日历功能
- **MUST** 根据系统语言/地区自动推荐合适的本地历法（FR-019）
- **MUST** 支持系统外观模式（浅色/深色/跟随系统）
- **MUST** 日历浮窗在屏幕边缘自动调整位置，确保完整显示
- **MUST** 首次启动无需配置即可使用（SC-001）
- **SHOULD** 设置操作在 3 次点击内完成（SC-003）
- **SHOULD** 90% 用户无需帮助文档即可使用（SC-004）

**Accessibility**:
- **MUST** 支持 VoiceOver 屏幕阅读器
- **SHOULD** 支持动态字体大小（尊重系统设置）

### VII. Code Quality Standards

**代码必须符合 Swift 和 SwiftUI 最佳实践**

- **MUST** 遵循 Swift API Design Guidelines
- **MUST** 使用 UpperCamelCase 命名类型和协议
- **MUST** 使用 lowerCamelCase 命名属性、方法、变量
- **MUST** 为公共 API 提供文档注释
- **MUST** 使用 `// MARK:` 组织代码块
- **MUST** 避免强制解包（`!`），优先使用可选链和 guard
- **MUST** 使用 `private` 和 `fileprivate` 限制访问范围
- **MUST** 实现 `Codable` 协议支持模型序列化
- **MUST NOT** 在生产代码中使用 `print()` 调试语句
- **SHOULD** 使用 `os.log` 进行结构化日志记录

**Commit Standards**:
- 遵循 Conventional Commits 格式
- 每个 task 或逻辑组完成后提交
- Commit message 使用中文描述

---

## Performance Standards

### Response Time Requirements

| 操作 | 目标时间 | 验证方法 | 对应需求 |
|------|---------|---------|---------|
| 菜单栏图标点击到日历显示 | < 300ms | Instruments Time Profiler | SC-002 |
| 月视图切换（上一月/下一月） | < 200ms | Instruments Time Profiler | SC-007 |
| 主题切换完成 | < 200ms | 手动测试 + 秒表 | SC-005 |
| 设置窗口打开 | < 300ms | 手动测试 | SC-003 |

### Resource Constraints

| 资源 | 限制 | 验证方法 | 对应需求 |
|------|------|---------|---------|
| 内存占用 | < 50MB | Instruments Allocations | SC-008 |
| 空闲 CPU | < 1% | Activity Monitor | SC-008 |
| 应用包大小 | < 20MB | Archive 后检查 | 合理性 |

---

## Platform Compliance

### macOS System Integration

**MUST** 正确集成以下系统服务：

1. **菜单栏 (NSStatusBar)**
   - 使用 `NSStatusItem` 创建菜单栏图标
   - 设置 `LSUIElement = YES` 使应用不在 Dock 显示
   - 支持左键点击和右键上下文菜单

2. **日历权限 (EventKit)**
   - 使用 `EKEventStore.requestAccess()` 请求权限
   - 权限拒绝时优雅降级（仅显示节假日，不显示用户事件）
   - 监听 `EKEventStore` 变更通知实时更新

3. **外观模式 (NSAppearance)**
   - 观察 `NSApp.effectiveAppearance` 变化
   - "跟随系统"主题实时响应系统切换

4. **区域设置 (Locale)**
   - 使用 `Locale.current.identifier` 和 `Locale.current.calendar` 识别地区
   - 自动推荐对应的本地历法（如 zh-CN → 农历，ar-SA → 伊斯兰历）

### Security & Privacy

- **MUST** 在 Info.plist 中声明 `NSCalendarsUsageDescription` 解释日历权限用途
- **MUST NOT** 收集或上传用户数据
- **MUST NOT** 访问用户日历数据用于非显示目的
- **MUST** 所有数据保存在用户本地设备

---

## Development Workflow

### Spec-First Principle (NON-NEGOTIABLE)
- Every code change must trace to a spec requirement
- Bug fixes exposing spec gaps require spec updates
- PR reviews must verify spec alignment
- Use `/speckit.analyze` before merging

### Violation Handling
- PRs without spec references are rejected
- Post-merge spec drift triggers immediate remediation

### Phase Execution Order

**MUST** 按照以下顺序执行 phases：

1. **Phase 1: Setup** (T001-T006) - 项目初始化
2. **Phase 2: Foundational** (T007-T024) - **BLOCKING** 所有后续工作
3. **Phase 3: US1 - 菜单栏显示** (T025-T036) - MVP 第一步
4. **Phase 4: US2 - 月视图展开** (T037-T059) - MVP 第二步
5. **Phase 7: US5 - 设置页面** (T102-T116) - 启用自定义
6. **Phase 5: US3 - 本地历法显示** (T060-T073.2)
7. **Phase 6: US4 - 状态标记** (T074-T101)
8. **Phase 8: US6 - 菜单栏自定义** (T117-T129)
9. **Phase 9: US7 - 主题定制** (T130-T151)
10. **Phase 10: Polish** (T152-T169)

### Checkpoint Validation

**MUST** 在每个 checkpoint 停止并验证功能：

- **Checkpoint 1 (after Phase 2)**: Foundation ready - 编译成功，所有模型可用
- **Checkpoint 2 (after Phase 3)**: 菜单栏显示日期时间，自动更新
- **Checkpoint 3 (after Phase 4)**: 点击/悬浮展开日历，月视图导航正常
- **Checkpoint 4 (after Phase 5)**: 本地历法正确显示（6+ 历法）
- **Checkpoint 5 (after Phase 6)**: 节假日和事件圆点显示，详情弹窗可用
- **Checkpoint 6 (after Phase 7)**: 设置窗口可访问（右键菜单 + ⌘+,）
- **Checkpoint 7 (after Phase 8)**: 菜单栏格式自定义生效
- **Checkpoint 8 (after Phase 9)**: 三个主题正常切换
- **Checkpoint 9 (after Phase 10)**: 所有性能指标达标，边缘情况测试通过

### Bug Fix Priority

| 优先级 | 类型 | 响应时间 |
|-------|------|---------|
| P0 - Critical | 应用崩溃、数据丢失 | 立即修复 |
| P1 - High | 核心功能不可用 | 当日修复 |
| P2 - Medium | 功能异常、性能不达标 | 1-2 天修复 |
| P3 - Low | UI 瑕疵、边缘情况 | 规划修复 |

---

## Quality Gates

### Pre-Release Checklist

**MUST** 在发布前完成所有检查项：

- [ ] 所有 7 个用户故事的验收场景通过测试
- [ ] 性能指标达标（Instruments 验证）
- [ ] 内存泄漏检测通过（Instruments Leaks）
- [ ] macOS HIG 设计审查通过
- [ ] EventKit 权限优雅降级测试通过
- [ ] 边缘情况测试通过（时区变更、屏幕边缘、快速操作）
- [ ] 支持的 macOS 版本测试通过（11.0, 12.0, 13.0, 14.0+）
- [ ] Accessibility 测试（VoiceOver）
- [ ] 代码审查完成（无 debug print, 命名规范, 注释完整）
- [ ] quickstart.md 所有验证场景通过

### Regression Testing

**MUST** 在每个 phase 完成后执行回归测试：

- 验证之前 phase 的功能未被破坏
- 运行所有已完成 user story 的测试用例
- 检查性能是否退化

---

## Governance

### Constitution Authority

- 本宪章优先级 **高于** 所有其他开发实践和临时决策
- 任何与宪章冲突的代码实现必须先修订宪章
- 宪章修订需要：
  1. 明确记录修订原因
  2. 评估对现有代码的影响
  3. 更新相关文档（spec.md, plan.md, tasks.md）
  4. 制定迁移计划（如有破坏性变更）

### Compliance Verification

- 每个 pull request/code review 必须验证 constitution 合规性
- 使用本宪章作为架构决策和代码审查的唯一依据
- 任何复杂度增加必须有充分理由（在 plan.md Complexity Tracking 中记录）

### Amendment Process

修订本宪章需要：
1. 创建 amendment proposal（说明修改内容和原因）
2. 评估影响范围（哪些代码、文档需要调整）
3. 获得项目负责人批准
4. 更新版本号和修订日期
5. 同步更新 plan.md 的 Constitution Check

---

**Version**: 1.0.0
**Ratified**: 2025-10-28
**Last Amended**: 2025-10-28
**Next Review**: 项目完成后或发现重大架构问题时
