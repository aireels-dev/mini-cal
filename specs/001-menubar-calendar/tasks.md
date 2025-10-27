# Tasks: MacOS菜单栏日历应用

**Input**: Design documents from `/specs/001-menubar-calendar/`
**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/service-interfaces.md, quickstart.md

**Tests**: This project does NOT require TDD. Tests will be added incrementally after implementation.

**Organization**: Tasks are grouped by user story (7 stories total) to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

This is a macOS desktop application using Swift + SwiftUI:
- **Source**: `MiniCal/MiniCal/` (App, Views, Models, Services, Resources, Utilities)
- **Tests**: `MiniCalTests/`, `MiniCalUITests/`
- All paths are relative to project root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic Xcode structure

- [X] T001 Create Xcode project "MiniCal" in MiniCal/ directory with macOS App target
- [X] T002 Configure project settings: minimum deployment target macOS 11.0, Swift 5.9+
- [X] T003 Create project folder structure: MiniCal/App/, Views/, Models/, Services/, Resources/, Utilities/
- [X] T004 [P] Add Assets.xcassets in MiniCal/Resources/ with app icon placeholder
- [X] T005 [P] Create Info.plist configuration for menu bar app (LSUIElement = YES)
- [X] T006 [P] Setup .gitignore for Xcode project files

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T007 Create MiniCalApp.swift entry point in MiniCal/App/ with @main attribute
- [ ] T008 Create AppDelegate.swift in MiniCal/App/ with NSApplicationDelegate conformance
- [ ] T009 Implement MenuBarController.swift in MiniCal/App/ managing NSStatusItem lifecycle
- [ ] T010 [P] Create Constants.swift in MiniCal/Utilities/ with app-wide constants
- [ ] T011 [P] Create Date+Extensions.swift in MiniCal/Utilities/Extensions/ with helper methods
- [ ] T012 [P] Create Calendar+Extensions.swift in MiniCal/Utilities/Extensions/ with calendar utilities
- [ ] T013 Create CalendarDate.swift model in MiniCal/Models/ per data-model.md
- [ ] T014 [P] Create SecondaryDateInfo.swift model in MiniCal/Models/
- [ ] T015 [P] Create CalendarType.swift enum in MiniCal/Models/
- [ ] T016 [P] Create DateEvent.swift model in MiniCal/Models/
- [ ] T017 [P] Create EventType.swift enum in MiniCal/Models/
- [ ] T018 [P] Create EventColor.swift enum in MiniCal/Models/
- [ ] T019 [P] Create EventSource.swift enum in MiniCal/Models/
- [ ] T020 [P] Create Theme.swift model in MiniCal/Models/
- [ ] T021 [P] Create ThemeColors.swift model in MiniCal/Models/
- [ ] T022 [P] Create UserSettings.swift model in MiniCal/Models/
- [ ] T023 [P] Create MenuBarFormat.swift enum in MiniCal/Models/
- [ ] T024 Create MiniCalError.swift error enum in MiniCal/Utilities/

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 菜单栏日期时间显示 (Priority: P1) 🎯 MVP

**Goal**: 在MacOS菜单栏显示可自定义的日期和时间,用户可一眼看到当前时间信息

**Independent Test**: 启动应用后观察菜单栏是否显示日期时间,修改系统时间后验证是否自动更新

### Implementation for User Story 1

- [ ] T025 [US1] Implement MenuBarViewModel.swift in MiniCal/Views/MenuBar/ managing display text and timer
- [ ] T026 [US1] Create MenuBarView.swift in MiniCal/Views/MenuBar/ (SwiftUI view, minimal UI)
- [ ] T027 [US1] Implement SettingsManager.swift in MiniCal/Services/ conforming to protocol from contracts
- [ ] T028 [US1] In MenuBarController: Create NSStatusItem and set initial button title
- [ ] T029 [US1] In MenuBarController: Setup Timer to update menu bar text every 60 seconds
- [ ] T030 [US1] In MenuBarViewModel: Implement updateDisplayText() formatting date per UserSettings
- [ ] T031 [US1] In MenuBarViewModel: Implement startUpdating() initializing timer
- [ ] T032 [US1] In MenuBarFormat enum: Implement format(date:show24Hour:showWeekday:) method
- [ ] T033 [US1] In SettingsManager: Implement load() from UserDefaults
- [ ] T034 [US1] In SettingsManager: Implement save() to UserDefaults
- [ ] T035 [US1] Wire MenuBarViewModel to MenuBarController in AppDelegate
- [ ] T036 [US1] Test: Launch app and verify menu bar displays formatted date/time

**Checkpoint**: 菜单栏显示功能完整,应用可显示实时日期时间

---

## Phase 4: User Story 2 - 月视图日历展开 (Priority: P1)

**Goal**: 点击或鼠标悬停菜单栏图标时展开浮窗显示当前月份日历视图

**Independent Test**: 点击菜单栏图标验证是否弹出月视图,显示正确的日期网格和当前月份,点击浮窗外部验证是否关闭

### Implementation for User Story 2

- [ ] T037 [P] [US2] Create CalendarViewModel.swift in MiniCal/Views/Calendar/ managing month data and navigation
- [ ] T038 [P] [US2] Create CalendarEngine.swift in MiniCal/Services/CalendarEngine/ implementing protocol
- [ ] T039 [P] [US2] Create CalendarPopoverView.swift in MiniCal/Views/Calendar/ as popover root view
- [ ] T040 [P] [US2] Create CalendarMonthView.swift in MiniCal/Views/Calendar/ using LazyVGrid for date grid
- [ ] T041 [P] [US2] Create CalendarDayCell.swift in MiniCal/Views/Calendar/ displaying single date
- [ ] T042 [US2] In CalendarEngine: Implement getMonthData(year:month:secondaryCalendar:) generating 42 cells
- [ ] T043 [US2] In CalendarEngine: Implement getToday() returning current date
- [ ] T044 [US2] In CalendarViewModel: Implement loadMonth(year:month:) calling CalendarEngine
- [ ] T045 [US2] In CalendarViewModel: Implement navigateToMonth(offset:) with debounce logic
- [ ] T046 [US2] In CalendarMonthView: Layout 7-column grid with weekday headers
- [ ] T047 [US2] In CalendarDayCell: Display day number and highlight today
- [ ] T048 [US2] In MenuBarController: Create NSPopover with CalendarPopoverView as content
- [ ] T049 [US2] In MenuBarController: Implement togglePopover() showing/hiding popover
- [ ] T050 [US2] In MenuBarController: Bind button click action to togglePopover()
- [ ] T051 [US2] In MenuBarController: Setup NSTrackingArea for hover detection (0.5s delay)
- [ ] T052 [US2] In CalendarPopoverView: Add left/right navigation buttons for month switching
- [ ] T053 [US2] In CalendarPopoverView: Add ESC key handler to close popover
- [ ] T054 [US2] In CalendarEngine: Implement NSCache for month data caching
- [ ] T055 [US2] Test: Click menu bar icon and verify calendar popover displays current month
- [ ] T056 [US2] Test: Hover over menu bar icon for 0.5s and verify auto-show
- [ ] T057 [US2] Test: Click outside popover and verify it closes
- [ ] T058 [US2] Test: Press ESC key and verify popover closes
- [ ] T059 [US2] Test: Click navigation arrows and verify month switches

**Checkpoint**: 日历浮窗展开功能完整,用户可查看月视图并导航不同月份

---

## Phase 5: User Story 3 - 副日历显示 (Priority: P2)

**Goal**: 在月视图中显示对应的副日历日期(农历、伊斯兰历等),满足文化习俗需求

**Independent Test**: 在设置中启用副日历(如中国农历),打开日历浮窗验证每个日期下方是否显示对应副日历信息

### Implementation for User Story 3

- [ ] T060 [P] [US3] Create SecondaryCalendarConverter.swift in MiniCal/Services/CalendarEngine/
- [ ] T061 [US3] In SecondaryCalendarConverter: Implement convert(gregorianDate:to:) using Foundation.Calendar
- [ ] T062 [US3] In SecondaryCalendarConverter: Implement batchConvert(dates:to:) for performance
- [ ] T063 [US3] In SecondaryCalendarConverter: Implement getFestivalName(for:calendarType:) identifying festivals
- [ ] T064 [US3] In SecondaryCalendarConverter: Add custom Buddhist calendar conversion (gregorian year + 543)
- [ ] T065 [US3] In CalendarEngine: Integrate SecondaryCalendarConverter for batch conversion
- [ ] T066 [US3] In CalendarEngine.getMonthData: Call batchConvert when secondaryCalendar is set
- [ ] T067 [US3] In CalendarDayCell: Display secondaryDate.displayText below day number
- [ ] T068 [US3] In CalendarDayCell: Highlight festival names in special color
- [ ] T069 [US3] In CalendarType enum: Implement displayName property for each calendar type
- [ ] T070 [US3] Test: Enable Chinese lunar calendar in settings and verify correct lunar dates
- [ ] T071 [US3] Test: Switch between different calendar types and verify correct conversions
- [ ] T072 [US3] Test: Verify Spring Festival (春节) and Mid-Autumn Festival (中秋) are highlighted
- [ ] T073 [US3] Test: Disable secondary calendar and verify only gregorian dates show

**Checkpoint**: 副日历功能完整,支持6+种全球主流历法

---

## Phase 6: User Story 4 - 日期状态标记 (Priority: P2)

**Goal**: 用彩色小圆点标记日期状态(假期、会议、节日等),帮助用户快速识别重要日期

**Independent Test**: 打开日历浮窗,观察节假日是否显示红色/橙色圆点,系统日历事件是否显示蓝色圆点,点击日期验证是否显示详细信息

### Implementation for User Story 4

- [ ] T074 [P] [US4] Create HolidayProvider.swift in MiniCal/Services/CalendarEngine/ implementing protocol
- [ ] T075 [P] [US4] Create EventService.swift in MiniCal/Services/ implementing protocol
- [ ] T076 [P] [US4] Create CN.json in MiniCal/Resources/Holidays/ with Chinese holidays data (2025-2027)
- [ ] T077 [P] [US4] Create US.json in MiniCal/Resources/Holidays/ with US holidays data
- [ ] T078 [P] [US4] Create festival-mapping.json in MiniCal/Resources/Holidays/ mapping lunar festivals
- [ ] T079 [US4] In HolidayProvider: Implement loadHolidayData() parsing JSON files
- [ ] T080 [US4] In HolidayProvider: Implement getHolidays(for:region:) querying by date
- [ ] T081 [US4] In HolidayProvider: Implement getMonthHolidays(year:month:region:) for batch query
- [ ] T082 [US4] In HolidayProvider: Implement isDataOutdated() checking latest holiday date
- [ ] T083 [US4] In EventService: Implement requestAuthorization() async calling EKEventStore
- [ ] T084 [US4] In EventService: Implement fetchEvents(for:) async querying EventKit
- [ ] T085 [US4] In EventService: Implement fetchEvents(from:to:) async for date range
- [ ] T086 [US4] In EventService: Implement observeEventStoreChanges(handler:) for live updates
- [ ] T087 [US4] In CalendarEngine: Integrate HolidayProvider to load month holidays
- [ ] T088 [US4] In CalendarEngine: Integrate EventService to load system events (if authorized)
- [ ] T089 [US4] In CalendarEngine.getMonthData: Merge holidays and events into CalendarDate.events
- [ ] T090 [US4] In CalendarDayCell: Add HStack displaying event dots (Circle views)
- [ ] T091 [US4] In CalendarDayCell: Color dots per event.color (red/orange/blue/purple/green)
- [ ] T092 [US4] In CalendarDayCell: Limit max 5 dots, show "+" if more events
- [ ] T093 [US4] Create EventDetailPopover.swift in MiniCal/Views/Calendar/ for event details
- [ ] T094 [US4] In CalendarDayCell: Add tap gesture opening EventDetailPopover
- [ ] T095 [US4] In EventDetailPopover: Display all events for selected date with titles and descriptions
- [ ] T096 [US4] Test: Verify public holidays show red dots
- [ ] T097 [US4] Test: Verify traditional festivals show orange dots
- [ ] T098 [US4] Test: Grant EventKit permission and verify calendar events show blue dots
- [ ] T099 [US4] Test: Deny EventKit permission and verify app still shows holidays
- [ ] T100 [US4] Test: Click date with events and verify detail popover displays correctly
- [ ] T101 [US4] Test: Verify multiple event dots display for same date

**Checkpoint**: 日期状态标记功能完整,用户可查看节假日和日历事件

---

## Phase 7: User Story 5 - 设置页面访问 (Priority: P2)

**Goal**: 通过右键菜单栏或快捷键进入设置页面,自定义应用偏好

**Independent Test**: 右键点击菜单栏图标验证是否显示"设置"菜单项,点击后验证设置窗口打开,或在日历浮窗中按⌘+,验证设置打开

### Implementation for User Story 5

- [ ] T102 [P] [US5] Create SettingsView.swift in MiniCal/Views/Settings/ as main settings window
- [ ] T103 [P] [US5] Create SettingsViewModel.swift in MiniCal/Views/Settings/ managing settings state
- [ ] T104 [P] [US5] Create MenuBarSettingsView.swift in MiniCal/Views/Settings/ for menu bar options
- [ ] T105 [P] [US5] Create ThemeSettingsView.swift in MiniCal/Views/Settings/ for theme selection
- [ ] T106 [US5] In SettingsView: Create tabbed interface with "菜单栏", "日历", "主题" tabs
- [ ] T107 [US5] In SettingsViewModel: Bind UserSettings properties as @Published
- [ ] T108 [US5] In SettingsViewModel: Implement save() calling SettingsManager
- [ ] T109 [US5] In MenuBarController: Add right-click context menu with "设置" item
- [ ] T110 [US5] In MenuBarController: Bind "设置" action to open SettingsView window
- [ ] T111 [US5] In CalendarPopoverView: Add keyboard shortcut ⌘+, opening SettingsView
- [ ] T112 [US5] In SettingsView: Implement window lifecycle (single instance, bring to front if open)
- [ ] T113 [US5] Test: Right-click menu bar icon and verify context menu displays
- [ ] T114 [US5] Test: Click "设置" menu item and verify settings window opens
- [ ] T115 [US5] Test: Press ⌘+, in calendar popover and verify settings window opens
- [ ] T116 [US5] Test: Open settings twice and verify single window instance

**Checkpoint**: 设置页面访问功能完整,用户可打开配置界面

---

## Phase 8: User Story 6 - 菜单栏显示自定义 (Priority: P3)

**Goal**: 在设置页面自定义菜单栏的日期时间显示格式和样式

**Independent Test**: 打开设置,修改显示格式(仅时间/仅日期/24小时制/显示星期),保存后验证菜单栏显示立即更新

### Implementation for User Story 6

- [ ] T117 [US6] In MenuBarSettingsView: Add Picker for menuBarFormat selection
- [ ] T118 [US6] In MenuBarSettingsView: Add Toggle for show24Hour option
- [ ] T119 [US6] In MenuBarSettingsView: Add Toggle for showWeekday option
- [ ] T120 [US6] In MenuBarSettingsView: Add preview text showing current format
- [ ] T121 [US6] In MenuBarSettingsView: Bind controls to SettingsViewModel properties
- [ ] T122 [US6] In SettingsViewModel: Observe settings changes and auto-save
- [ ] T123 [US6] In MenuBarViewModel: Observe SettingsManager.settings via Combine
- [ ] T124 [US6] In MenuBarViewModel: Trigger updateDisplayText() when settings change
- [ ] T125 [US6] In MenuBarFormat.format(): Implement all format options (.dateOnly, .timeOnly, .dateTime)
- [ ] T126 [US6] Test: Change to "仅时间" and verify menu bar shows only time
- [ ] T127 [US6] Test: Enable "24小时制" and verify time displays as 14:30 not 2:30 PM
- [ ] T128 [US6] Test: Enable "显示星期" and verify "周一 10月27日" format
- [ ] T129 [US6] Test: Verify settings persist after app restart

**Checkpoint**: 菜单栏显示自定义功能完整,用户可个性化时间格式

---

## Phase 9: User Story 7 - 主题定制 (Priority: P3)

**Goal**: 在设置中选择不同日历主题,改变日历浮窗的视觉风格

**Independent Test**: 打开设置选择"深色主题",打开日历浮窗验证深色配色,选择"跟随系统"后切换macOS外观模式验证主题自动切换

### Implementation for User Story 7

- [ ] T130 [P] [US7] Create ThemeManager.swift in MiniCal/Services/ implementing protocol
- [ ] T131 [P] [US7] Create themes.json in MiniCal/Resources/Themes/ with light/dark/system themes
- [ ] T132 [US7] In ThemeManager: Implement loadThemes() parsing themes.json
- [ ] T133 [US7] In ThemeManager: Implement applyTheme(_:) updating currentTheme
- [ ] T134 [US7] In ThemeManager: Implement theme(withId:) looking up theme by ID
- [ ] T135 [US7] In ThemeManager: Implement startObservingSystemAppearance() watching NSApp.effectiveAppearance
- [ ] T136 [US7] In ThemeManager: Implement stopObservingSystemAppearance() removing observer
- [ ] T137 [US7] In ThemeColors: Implement color(from:) converting hex to SwiftUI Color
- [ ] T138 [US7] In ThemeSettingsView: Add Picker displaying all available themes
- [ ] T139 [US7] In ThemeSettingsView: Add theme preview cards showing colors
- [ ] T140 [US7] In ThemeSettingsView: Bind theme selection to SettingsViewModel.themeId
- [ ] T141 [US7] In SettingsViewModel: Call ThemeManager.applyTheme() when themeId changes
- [ ] T142 [US7] In SettingsViewModel: Call startObservingSystemAppearance() if "跟随系统" selected
- [ ] T143 [US7] In AppDelegate: Inject ThemeManager into SwiftUI environment
- [ ] T144 [US7] In CalendarPopoverView: Apply theme colors to background
- [ ] T145 [US7] In CalendarMonthView: Apply theme colors to text and borders
- [ ] T146 [US7] In CalendarDayCell: Apply theme.todayHighlight to current day
- [ ] T147 [US7] In CalendarDayCell: Apply theme.weekendText to Saturday/Sunday
- [ ] T148 [US7] Test: Select "浅色主题" and verify calendar uses light colors
- [ ] T149 [US7] Test: Select "深色主题" and verify calendar uses dark colors
- [ ] T150 [US7] Test: Select "跟随系统", switch macOS to dark mode, verify theme changes
- [ ] T151 [US7] Test: Measure theme switching time is <200ms

**Checkpoint**: 主题定制功能完整,支持3个主题和系统跟随

---

## Phase 10: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements and quality assurance

- [ ] T152 [P] Add app icon design in MiniCal/Resources/Assets.xcassets/
- [ ] T153 [P] Create app launch screen and initial load optimization
- [ ] T154 [P] Implement app version check and update reminder
- [ ] T155 [P] Add about window showing app version and credits
- [ ] T156 [P] Create user guide document in docs/user-guide.md
- [ ] T157 Add performance profiling and optimize slow operations
- [ ] T158 Add memory leak detection and fix retain cycles
- [ ] T159 [P] Review and improve error messages for user-facing errors
- [ ] T160 [P] Add logging for debugging (using os.log)
- [ ] T161 [P] Security review: Verify EventKit permission handling
- [ ] T162 [P] Accessibility review: Ensure VoiceOver compatibility
- [ ] T163 Code cleanup: Remove debug print statements and commented code
- [ ] T164 Code review: Ensure SwiftUI best practices and naming conventions
- [ ] T165 Run quickstart.md validation scenarios
- [ ] T166 Prepare for App Store submission (if applicable)

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-9)**: All depend on Foundational phase completion
  - US1 + US2 (P1): Core functionality, should complete first
  - US3-US5 (P2): Enhancement features, can proceed in parallel after P1
  - US6-US7 (P3): Polish features, can proceed in parallel after P2
- **Polish (Phase 10)**: Depends on all desired user stories being complete

### User Story Dependencies

- **US1 (菜单栏显示)**: Can start after Foundational - No dependencies
- **US2 (月视图展开)**: Can start after Foundational - No dependencies (independent of US1)
- **US3 (副日历)**: Depends on US2 (needs CalendarEngine and CalendarDayCell)
- **US4 (状态标记)**: Depends on US2 (needs CalendarEngine and CalendarDayCell)
- **US5 (设置页面)**: Can start after Foundational - No dependencies
- **US6 (菜单栏自定义)**: Depends on US1 (MenuBar) and US5 (Settings)
- **US7 (主题定制)**: Depends on US2 (Calendar views) and US5 (Settings)

### Recommended Execution Order

1. **Phase 1**: Setup (T001-T006)
2. **Phase 2**: Foundational (T007-T024) - Complete all models and base infrastructure
3. **Phase 3**: US1 - 菜单栏显示 (T025-T036) ✅ **First MVP checkpoint**
4. **Phase 4**: US2 - 月视图展开 (T037-T059) ✅ **Second MVP checkpoint**
5. **Phase 7**: US5 - 设置页面 (T102-T116) - Enables customization
6. **Phase 5**: US3 - 副日历显示 (T060-T073)
7. **Phase 6**: US4 - 状态标记 (T074-T101)
8. **Phase 8**: US6 - 菜单栏自定义 (T117-T129)
9. **Phase 9**: US7 - 主题定制 (T130-T151)
10. **Phase 10**: Polish (T152-T166)

### Parallel Opportunities

- **Phase 1 Setup**: All [P] tasks (T003-T006) can run in parallel
- **Phase 2 Foundational**: All model files (T013-T023) can be created in parallel
- **After Foundational**:
  - US1 (MenuBar) + US2 (Calendar) can start in parallel (different subsystems)
  - US5 (Settings) can start in parallel with US1/US2
- **After US2 completes**:
  - US3 (Secondary Calendar) + US4 (Event Dots) can run in parallel
- **After US1+US5 complete**:
  - US6 (MenuBar Customization) can proceed
- **After US2+US5 complete**:
  - US7 (Theme) can proceed

---

## Parallel Example: Foundational Phase

```bash
# All model files can be created in parallel:
Task T013: "Create CalendarDate.swift model in MiniCal/Models/"
Task T014: "Create SecondaryDateInfo.swift model in MiniCal/Models/"
Task T015: "Create CalendarType.swift enum in MiniCal/Models/"
Task T016: "Create DateEvent.swift model in MiniCal/Models/"
Task T017: "Create EventType.swift enum in MiniCal/Models/"
Task T018: "Create EventColor.swift enum in MiniCal/Models/"
Task T019: "Create EventSource.swift enum in MiniCal/Models/"
Task T020: "Create Theme.swift model in MiniCal/Models/"
Task T021: "Create ThemeColors.swift model in MiniCal/Models/"
Task T022: "Create UserSettings.swift model in MiniCal/Models/"
Task T023: "Create MenuBarFormat.swift enum in MiniCal/Models/"
```

## Parallel Example: After Foundational

```bash
# Three independent subsystems can start in parallel:
Task T025-T036: "User Story 1 - MenuBar display" (Developer A)
Task T037-T059: "User Story 2 - Calendar popover" (Developer B)
Task T102-T116: "User Story 5 - Settings window" (Developer C)
```

---

## Implementation Strategy

### MVP First (US1 + US2 Only)

1. Complete Phase 1: Setup (T001-T006)
2. Complete Phase 2: Foundational (T007-T024) - CRITICAL
3. Complete Phase 3: US1 - MenuBar (T025-T036)
4. **STOP and VALIDATE**: Test menu bar display independently
5. Complete Phase 4: US2 - Calendar (T037-T059)
6. **STOP and VALIDATE**: Test calendar popover independently
7. **MVP READY**: User can see time in menu bar and view calendar

### Incremental Delivery

1. MVP = US1 + US2 (Core functionality)
2. Add US5 (Settings) → User can access preferences
3. Add US3 (Secondary Calendar) → Cultural calendar support
4. Add US4 (Event Dots) → Holiday and meeting awareness
5. Add US6 (MenuBar Custom) → Personalized time format
6. Add US7 (Theme) → Visual customization
7. Each story adds value without breaking previous stories

### Parallel Team Strategy (3 developers)

**Week 1-2**: Setup + Foundational (All developers together)

**Week 3**: After Foundational completes
- Developer A: US1 (MenuBar) → T025-T036
- Developer B: US2 (Calendar) → T037-T059
- Developer C: US5 (Settings) → T102-T116

**Week 4**: After US2 completes
- Developer A: US6 (MenuBar Custom) → T117-T129 (needs US1+US5)
- Developer B: US3 (Secondary Calendar) → T060-T073 (needs US2)
- Developer C: US4 (Event Dots) → T074-T101 (needs US2)

**Week 5**: After US2+US5 complete
- Developer A: US7 (Theme) → T130-T151 (needs US2+US5)
- Developer B: Polish → T152-T166
- Developer C: Testing and bug fixes

---

## Task Statistics

- **Total Tasks**: 166
- **Setup**: 6 tasks
- **Foundational**: 18 tasks
- **US1 (MenuBar)**: 12 tasks
- **US2 (Calendar)**: 23 tasks
- **US3 (Secondary Calendar)**: 14 tasks
- **US4 (Event Dots)**: 28 tasks
- **US5 (Settings)**: 15 tasks
- **US6 (MenuBar Custom)**: 13 tasks
- **US7 (Theme)**: 22 tasks
- **Polish**: 15 tasks

**Parallel Tasks**: 51 tasks marked [P] (30.7%)
**MVP Tasks**: 36 tasks (Setup + Foundational + US1 + US2)

---

## Notes

- [P] tasks = different files, no dependencies - can run in parallel
- [Story] label maps task to specific user story for traceability
- Each user story is independently testable after completion
- Stop at any checkpoint to validate story functionality
- Commit after completing each task or logical group
- All file paths are relative to MiniCal Xcode project root
- Follow Swift and SwiftUI naming conventions (UpperCamelCase for types, lowerCamelCase for properties/methods)