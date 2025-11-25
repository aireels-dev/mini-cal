# Feature Specification: 日历事件订阅管理

**Feature Branch**: `003-calendar-subscription`
**Created**: 2025-10-30
**Status**: Draft
**Input**: User description: "添加日历事件订阅管理， 支持自动同步系统日历事件，系统的订阅服务，除从同步过来的日历外，支持通过uri订阅日历事件；所有日历自动分配一个特征颜色，以小圆点形式展现在日历前边，用户可修改； 对于有订阅事件的日期，在日历浮窗底部显示圆点标识，点击对应天，弹出事件列表；列表底部也支持添加事件。结合以上描述，完整整套逻辑。"

## Glossary *(terminology reference)*

本规范中使用的关键术语及其精确定义：

### 核心概念

| 术语 | 英文标识 | 定义 | 使用场景 |
|------|---------|------|---------|
| **订阅源** | `CalendarSubscription` | 一个日历数据源，可以是系统日历或外部 URI 订阅 | 用户管理、数据模型、服务层 |
| **系统日历订阅** | System Calendar Subscription | 通过 EventKit 访问的 macOS 本地日历（如 iCloud 日历、本地日历） | 权限请求、EventKit 集成 |
| **外部 URI 订阅** | External Subscription / URI Subscription | 通过 HTTP(S) URI 订阅的 iCalendar 格式日历（如 Google Calendar 共享链接） | 网络请求、iCal 解析 |
| **日历事件** | `CalendarEvent` | 业务层事件模型，包含标题、时间、描述、所属订阅源等完整信息 | ViewModel、UI 显示、业务逻辑 |
| **系统事件对象** | `EKEvent` | EventKit 框架的原生事件类型 | EventKit 服务层、数据转换 |
| **日期事件标记** | `DateEvent` | 日历视图中日期单元的事件标记（可能仅包含日期和颜色信息） | 日历网格显示、圆点标识 |
| **订阅源颜色标识** | Subscription Color / Color Tag | 用于区分不同订阅源的颜色圆点 | UI 显示、颜色管理 |

### 同步相关

| 术语 | 英文标识 | 定义 |
|------|---------|------|
| **初始同步** | Initial Sync | 首次添加订阅源或授权权限后的完整数据导入 |
| **增量同步** | Incremental Sync | 仅同步上次同步后的变更数据 |
| **手动刷新** | Manual Refresh | 用户主动触发的同步操作 |
| **自动同步** | Auto Sync | 按配置间隔自动触发的后台同步 |
| **实时通知同步** | Real-time Sync | 基于 EventKit 通知的即时同步（仅系统日历） |

### 状态定义

| 术语 | 定义 | 可能的值 |
|------|------|---------|
| **同步状态** | 订阅源当前的同步健康状态 | `synced`（正常）、`syncing`（同步中）、`failed`（失败）、`stale`（过期） |
| **订阅类型** | 订阅源的数据来源类型 | `system`（系统日历）、`external`（外部 URI） |

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - 自动同步系统日历事件 (Priority: P1)

用户能够自动同步系统日历中的所有事件到MiniCal应用中，无需手动配置。系统会定期检查并同步更新。

**Why this priority**: 这是核心功能的基础，用户需要能够看到自己已有的日历事件，这是使用应用的前提条件。

**Independent Test**: 可以通过连接到系统日历，验证是否能正确读取和显示现有事件，独立测试数据同步功能。

**Acceptance Scenarios**:

1. **Given** 用户首次启动应用，**When** 用户授权系统日历访问权限，**Then** 应用在 30 秒内完成初始同步，导入所有系统日历事件
2. **Given** 系统日历中有新事件添加，**When** 应用按配置间隔检查更新（默认 5 分钟），**Then** 新事件在下次同步周期内显示到 MiniCal 中
3. **Given** 系统日历中的事件被修改或删除，**When** EventKit 发送变更通知或下次同步周期触发，**Then** 对应事件在 MiniCal 中立即更新或移除
4. **Given** 用户在系统设置中撤销日历权限，**When** MiniCal 检测到权限变更，**Then** 显示权限提示并隐藏系统日历事件（保留外部订阅事件）

---

### User Story 2 - URI订阅外部日历 (Priority: P1)

用户可以通过URI地址订阅外部日历源（如Google Calendar、Outlook等），扩展事件来源。

**Why this priority**: 扩展了事件来源，让用户可以整合多个日历系统，提高应用实用性。

**Independent Test**: 通过添加URI订阅源，验证是否能正确解析和显示外部日历事件。

**Acceptance Scenarios**:

1. **Given** 用户有外部日历URI，**When** 用户在订阅管理中添加URI，**Then** 外部日历事件自动同步
2. **Given** 外部日历事件更新，**When** 应用检查订阅源，**Then** MiniCal显示最新的事件信息
3. **Given** 用户取消订阅某个日历，**When** 确认取消，**Then** 该日历的所有事件从MiniCal中移除

---

### User Story 3 - 日历颜色标识管理 (Priority: P2)

每个日历订阅源都会自动分配一个特征颜色，以小圆点形式显示在日历中，用户可以自定义修改这些颜色。

**Why this priority**: 颜色标识帮助用户快速区分不同来源的事件，提升视觉识别效率。

**Independent Test**: 验证不同日历事件在界面中显示正确的小圆点颜色，用户能够修改颜色并保存设置。

**Acceptance Scenarios**:

1. **Given** 新的日历订阅源添加，**When** 系统处理订阅，**Then** 自动为该日历分配一个独特的颜色标识
2. **Given** 用户想要修改日历颜色，**When** 用户选择新颜色并确认，**Then** 该日历的所有事件显示新颜色
3. **Given** 多个日历有同一天的事件（如系统日历 3 个 + 外部订阅 5 个），**When** 日历显示，**Then**:
   - 最多显示 5 个颜色圆点（按订阅源优先级排序）
   - 超出部分显示 "+3" 文字标识
   - 悬停时显示完整订阅源列表（8 个订阅源，共 8 个事件）

---

### User Story 4 - 事件日期可视化标识 (Priority: P1)

在日历界面中，有事件的日期会在底部显示小圆点标识，直观显示哪些日期有事件安排。

**Why this priority**: 提供快速的事件概览，用户一眼就能看出哪些日期有安排，提升用户体验。

**Independent Test**: 验证有事件的日期是否正确显示底部圆点标识，无事件日期不显示标识。

**Acceptance Scenarios**:

1. **Given** 某个日期有至少一个事件，**When** 日历界面加载，**Then** 该日期底部显示对应事件的颜色圆点
2. **Given** 某个日期有多个不同日历的事件，**When** 日历显示，**Then** 底部显示多个颜色圆点
3. **Given** 某个日期的事件全部被删除，**When** 界面刷新，**Then** 该日期的圆点标识消失

---

### User Story 5 - 事件列表查看和添加 (Priority: P1)

点击有事件的日期，会弹出事件列表显示当天所有事件，列表底部提供添加新事件的功能。

**Why this priority**: 这是用户查看详细信息和管理事件的核心交互方式。

**Independent Test**: 验证点击日期能正确显示事件列表，以及添加事件功能是否正常工作。

**Acceptance Scenarios**:

1. **Given** 用户点击有事件的日期，**When** 点击操作触发，**Then** 弹出当天事件列表
2. **Given** 事件列表弹出，**When** 用户点击列表底部的添加按钮，**Then** 显示添加事件界面
3. **Given** 用户填写新事件信息并保存，**When** 保存操作完成，**Then** 新事件立即显示在列表中并同步到对应日历

---

### Edge Cases

- **网络连接失败时**: 应用显示缓存的事件数据，并在网络恢复后自动同步
- **重复订阅处理**: 系统检测并提示用户已存在相同的日历订阅，避免重复添加
- **大量事件处理**: 当单个日期事件数量过多时，界面提供滚动查看功能
- **权限撤销处理**: 当用户撤销系统日历权限时，应用友好提示并隐藏相关事件
- **URI订阅失效**: 外部URI订阅失效时，系统标识并提示用户重新配置

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: 系统必须自动检测并请求系统日历访问权限
- **FR-002**: 系统必须支持 EventKit 框架自动同步系统日历事件，包括：
  - **初始同步**: 首次授权后导入所有现有事件
  - **增量更新**: 默认每 5 分钟检查事件变更（用户可配置：1/5/15/30/60 分钟或仅手动同步）
  - **实时响应**: 监听 `EKEventStoreChanged` 通知，系统日历变更时立即同步
  - **应用激活**: 应用从后台恢复时自动检查更新
- **FR-003**: 系统必须支持通过 URI 订阅外部日历源（标准 iCalendar RFC 5545 格式）
- **FR-004**: 系统必须为每个日历订阅源自动分配唯一特征颜色（从预设调色板中选择，确保视觉区分度不低于 WCAG AA 标准对比度 4.5:1）
- **FR-005**: 用户必须能够自定义修改日历的颜色标识
- **FR-006**: 系统必须在有事件的日期底部显示对应颜色的圆点标识，包括：
  - **单事件**: 显示单个颜色圆点
  - **多事件**: 按日历优先级排列多个圆点（最多显示 5 个，超出显示"+N"标识）
  - **圆点顺序**: 优先显示用户自定义顺序，其次按事件开始时间
  - **交互**: 悬停显示事件数量提示
- **FR-007**: 系统必须支持点击日期弹出当天所有事件的详细列表
- **FR-008**: 事件列表必须提供添加新事件的功能入口（基于 EventKit 创建本地事件）
- **FR-009**: 系统必须支持订阅源管理（添加、编辑、删除、手动刷新）
- **FR-010**: 系统必须在网络异常时提供离线访问功能（显示缓存事件，网络恢复后自动同步）

### Key Entities *(data models and their relationships)*

#### 1. CalendarSubscription（订阅源）

**属性**:
- `id: UUID` - 唯一标识符
- `name: String` - 订阅源名称（用户可编辑）
- `type: SubscriptionType` - 订阅类型（`system` / `external`）
- `uri: URL?` - 外部订阅的 URI（系统日历为 nil）
- `color: EventColor` - 分配的颜色标识
- `syncStatus: SyncStatus` - 当前同步状态
- `lastSyncDate: Date?` - 最后同步时间
- `syncInterval: TimeInterval` - 同步间隔（秒，用户可配置）
- `isEnabled: Bool` - 是否启用（禁用后不显示该订阅的事件）
- `createdAt: Date` - 创建时间

**关系**: 一对多 `CalendarEvent`

#### 2. CalendarEvent（日历事件）

**属性**:
- `id: UUID` - 唯一标识符
- `title: String` - 事件标题
- `startDate: Date` - 开始时间
- `endDate: Date` - 结束时间
- `isAllDay: Bool` - 是否全天事件
- `location: String?` - 地点
- `description: String?` - 描述
- `subscriptionId: UUID` - 所属订阅源 ID
- `ekEventIdentifier: String?` - EventKit 事件标识符（仅系统日历）
- `recurrenceRule: String?` - 重复规则（iCal RRULE 格式）

**关系**: 多对一 `CalendarSubscription`

#### 3. DateEvent（日期事件标记）

**用途**: 日历网格视图中的轻量级事件标记

**属性**:
- `date: Date` - 日期（仅日期部分）
- `eventIds: [UUID]` - 该日期所有事件的 ID 列表
- `colorTags: [EventColor]` - 该日期显示的颜色圆点列表（最多 5 个）

**关系**: 通过 `eventIds` 关联多个 `CalendarEvent`

#### 4. UserPreferences（用户偏好设置）

**属性**:
- `defaultSyncInterval: TimeInterval` - 默认同步间隔（300 秒 / 5 分钟）
- `maxVisibleColorTags: Int` - 日期上最多显示的颜色圆点数量（默认 5）
- `subscriptionPriorityOrder: [UUID]` - 订阅源显示优先级排序
- `enableSystemCalendar: Bool` - 是否启用系统日历集成
- `enableAutoSync: Bool` - 是否启用自动同步（关闭则仅手动刷新）

### Sync Strategy *(technical clarification)*

**同步触发机制**:
1. **定时轮询**: 后台定时器按用户配置间隔检查（默认 5 分钟）
2. **应用激活**: 应用从后台恢复到前台时立即检查
3. **手动触发**: 用户在订阅管理页面点击"刷新"按钮
4. **EventKit 通知**: 系统日历变更时通过 `EKEventStoreChanged` 通知触发

**增量同步逻辑**:
- 使用 `lastSyncDate` 标记，仅拉取变更后的事件
- 系统日历通过 EventKit 的 `predicateForEvents` 过滤时间范围
- 外部订阅通过 HTTP `If-Modified-Since` 头优化网络请求

### Color Assignment Algorithm *(technical clarification)*

**预设调色板**: 16 色饱和度适中的主题色（参考 macOS 系统颜色）
- 红、橙、黄、绿、薄荷绿、青、蓝、靛蓝、紫、粉、棕、灰（浅色模式）
- 对应的深色模式变体（自动适配系统外观）

**分配规则**:
1. **首次分配**: 按订阅源添加顺序循环分配（避免相邻订阅源颜色过于接近）
2. **冲突检测**: 如现有订阅源已使用某颜色，跳过该颜色选择下一个
3. **智能推荐**: 系统日历优先分配蓝色，节假日日历优先红色（如适用）
4. **用户自定义**: 用户可从调色板中选择任意颜色替换自动分配的颜色

**对比度保证**:
- 圆点颜色与背景对比度 ≥ 4.5:1（WCAG AA 标准）
- 深色模式自动切换到高对比度变体

### iCalendar Support *(RFC 5545 compliance)*

**支持的 iCalendar 版本**: 2.0（RFC 5545）

**必需解析字段**:
- `VCALENDAR`: 日历容器
- `VEVENT`: 事件对象
- `DTSTART`: 开始时间（必需）
- `DTEND` 或 `DURATION`: 结束时间或持续时间（至少一个）
- `SUMMARY`: 事件标题（必需）

**可选解析字段**:
- `DESCRIPTION`: 事件描述
- `LOCATION`: 地点
- `RRULE`: 重复规则（基础支持：FREQ, INTERVAL, UNTIL, COUNT）
- `UID`: 唯一标识符（用于增量同步去重）
- `LAST-MODIFIED`: 最后修改时间（用于增量同步）

**不支持字段**（忽略，不影响解析）:
- `VALARM`: 提醒（宪法禁止）
- `ATTENDEE`: 参与者（超出范围）
- `ORGANIZER`: 组织者（超出范围）

**错误处理**:
- 缺少必需字段时跳过该事件并记录错误
- 解析失败时返回具体错误信息和行号
- 部分事件失败不影响其他事件导入

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 用户能够在30秒内完成首次系统日历授权和事件同步
- **SC-002**: 外部日历URI订阅添加成功率不低于95%
- **SC-003**: 事件同步延迟不超过5分钟，实时性满足用户需求
- **SC-004**: 用户能够识别不同来源的事件，颜色区分准确率达到100%
- **SC-005**: 有事件日期的标识准确率达到98%以上
- **SC-006**: 事件列表加载时间不超过2秒
- **SC-007**: 新事件添加成功率不低于99%
- **SC-008**: 系统支持至少10个不同日历订阅源同时管理
- **SC-009**: 单日显示 100 个事件时界面仍保持流畅（事件列表滚动帧率 ≥ 50fps，列表加载时间 < 2 秒，符合 SC-006）
- **SC-010**: 用户满意度调研显示事件管理功能满意度达到85%以上

### Acceptance Criteria Details *(verification methods)*

**SC-002 验证方法**:
- **测试样本**: 100 个真实 iCalendar URI（来自 Google Calendar、Outlook、Apple iCloud、开源日历服务器）
- **成功定义**: URI 解析成功 + 至少获取到 1 个有效事件 + 保存到本地订阅列表
- **失败类型统计**:
  - 网络超时（不计入失败率，应重试）
  - 无效 URI 格式（用户输入错误，友好提示）
  - 不支持的日历格式（明确提示仅支持 iCalendar）
  - 服务器拒绝访问（需用户检查权限）
- **目标**: 有效 URI 的成功率 ≥ 95%

**SC-003 验证方法**:
- **测试场景**: 外部日历添加新事件，记录到 MiniCal 显示的延迟时间
- **测量**: 事件创建时间戳 vs MiniCal 首次显示时间戳
- **条件**: 默认同步间隔（5 分钟），应用保持运行状态
- **目标**: 95% 的事件在 5 分钟内同步显示

**SC-010 验证方法**:
- 通过用户测试问卷收集（项目完成后执行）
- 最低样本量：20 名真实用户，使用 7 天以上
- 满意度评分：1-5 分（5 分最满意），平均分 ≥ 4.25 分（对应 85% 满意度）