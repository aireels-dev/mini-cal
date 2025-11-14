---

description: "Task list template for feature implementation"
---

# Tasks: Enhanced Theme System

**Input**: Design documents from `/specs/002-enhanced-theme-system/`
**Prerequisites**: plan.md (required), spec.md (required for user stories), research.md, data-model.md, contracts/

**Tests**: The examples below include test tasks. Tests are OPTIONAL - only include them if explicitly requested in the feature specification.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

- **Single project**: `src/`, `tests/` at repository root
- **Web app**: `backend/src/`, `frontend/src/`
- **Mobile**: `api/src/`, `ios/src/` or `android/src/`
- Paths shown below assume single project - adjust based on plan.md structure

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [ ] T001 Create theme module directory structure in MiniCal/Themes/
- [ ] T002 [P] Create Themes subdirectories: Models/, Views/, Services/, Resources/, Extensions/
- [ ] T003 [P] Create tests directory structure for theme system in Tests/ThemeTests/
- [ ] T004 Create built-in theme resources directory in MiniCal/Themes/Resources/BuiltIn/

---

## Phase 2: Foundational (Blocking Prerequisites) ✅ COMPLETED

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T005 Implement core theme data models in MiniCal/Themes/Models/ThemeModels.swift
- [x] T006 [P] implement theme configuration structures in MiniCal/Themes/Models/ThemeConfiguration.swift
- [x] T007 [P] Implement user preferences model in MiniCal/Themes/Models/UserPreferences.swift
- [x] T008 Create color utility extensions in MiniCal/Themes/Extensions/Color+Extensions.swift
- [x] T009 Implement theme caching system in MiniCal/Themes/Services/ThemeCache.swift
- [x] T010 Create performance monitoring service in MiniCal/Themes/Services/ThemePerformanceMonitor.swift
- [x] T011 [P] Create built-in theme definition files (classic_blue.json, fresh_green.json, midnight_blue.json, forest_green.json, sunset_orange.json) in MiniCal/Themes/Resources/BuiltIn/
- [x] T012 Implement system appearance monitoring in MiniCal/Themes/Services/SystemAppearanceMonitor.swift

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - 模式主题选择体系 (Priority: P1) 🎯 MVP

**Goal**: 实现三层主题模式选择（黑夜/白天/自动），允许用户选择主题模式并在对应主题组中选择具体主题

**Independent Test**: 通过设置界面的主题选择流程来独立测试，验证模式切换和主题选择的完整交互体验

### Tests for User Story 1 ✅ COMPLETED ⚠️

> **NOTE**: Write these tests FIRST, ensure they FAIL before implementation

- [x] T013 [P] [US1] Unit test for ThemeMode enum functionality in Tests/ThemeTests/ThemeModelsTests.swift
- [x] T014 [P] [US1] Unit test for theme configuration loading in Tests/ThemeTests/ThemeConfigurationTests.swift
- [x] T015 [US1] Integration test for theme mode switching in Tests/ThemeTests/ThemeModeIntegrationTests.swift

### Implementation for User Story 1 ✅ COMPLETED

- [x] T016 [P] [US1] Create enhanced theme manager class in MiniCal/Themes/Services/EnhancedThemeManager.swift
- [x] T017 [US1] Implement theme mode switching logic in EnhancedThemeManager.switchToMode()
- [x] T018 [US1] Implement theme selection for categories in EnhancedThemeManager.setTheme()
- [x] T019 [US1] Implement theme persistence in EnhancedThemeManager.savePreferences() and loadPreferences()
- [ ] T019a [US1] Implement smooth theme transition animations in EnhancedThemeManager (FR-009)
- [x] T020 [P] [US1] Create theme settings view in MiniCal/Themes/Views/ThemeSettingsView.swift
- [x] T021 [US1] Implement theme mode selection UI in ThemeSettingsView (segmented control or radio buttons)
- [x] T022 [P] [US1] Create theme selection UI components in MiniCal/Themes/Views/ThemeCard.swift
- [x] T023 [US1] Implement theme grid view for theme selection in ThemeSettingsView
- [ ] T023a [US1] Add reset to default theme button in ThemeSettingsView (FR-010)
- [x] T024 [US1] Update existing SettingsView.swift to include theme tab
- [x] T025 [US1] Integrate theme manager with app lifecycle in MiniCal/App/MenuBarController.swift
- [ ] T025a [US1] Implement theme restoration on app launch in EnhancedThemeManager.restoreTheme() (FR-007) - **HIGH PRIORITY**

**Checkpoint**: At this point, User Story 1 should be fully functional and testable independently ✅

---

## Phase 4: User Story 2 - Chrome风格主题库 (Priority: P1)

**Goal**: 提供多套参考Chrome内置主题风格的配色方案，用户可以根据个人喜好选择不同的颜色主题

**Independent Test**: 可以通过浏览和切换不同的主题来独立测试，验证每个主题的颜色搭配和视觉效果是否符合预期

### Tests for User Story 2 ⚠️

- [ ] T026 [P] [US2] Unit test for Chrome theme color schemes in Tests/ThemeTests/ChromeThemeTests.swift
- [ ] T027 [US2] Integration test for theme preview functionality in Tests/ThemeTests/ThemePreviewTests.swift

### Implementation for User Story 2

- [ ] T028 [P] [US2] Create additional Chrome-inspired theme definitions:
  - MiniCal/Themes/Resources/BuiltIn/sunset_orange.json
  - MiniCal/Themes/Resources/BuiltIn/ocean_teal.json
  - MiniCal/Themes/Resources/BuiltIn/lavender_purple.json
  - MiniCal/Themes/Resources/BuiltIn/ruby_red.json
  - MiniCal/Themes/Resources/BuiltIn/graphite_gray.json
- [ ] T029 [US2] Implement theme loading from JSON files in ThemeCache.loadBuiltinThemes()
- [ ] T030 [US2] Create theme preview color extraction in ThemeConfiguration.previewColors
- [ ] T031 [P] [US2] Update ThemeCard to display Chrome-style color previews
- [ ] T032 [US2] Implement theme validation for WCAG 2.1 AA color contrast standards (FR-011)
- [ ] T033 [US2] Add theme metadata (author, version, description) to built-in themes

**Checkpoint**: At this point, User Stories 1 AND 2 should both work independently

---

## Phase 5: User Story 3 - 黑夜白天主题独立性 (Priority: P2)

**Goal**: 用户在黑夜模式和白天模式下可以选择不同的主题，系统会记住用户在每种模式下的主题偏好

**Independent Test**: 可以通过切换系统外观模式并验证对应主题的自动应用来独立测试

### Tests for User Story 3 ⚠️

- [ ] T034 [P] [US3] Unit test for independent theme preferences in Tests/ThemeTests/IndependentThemeTests.swift
- [ ] T035 [US3] Integration test for system appearance response in Tests/ThemeTests/SystemAppearanceTests.swift
- [ ] T036a [US3] Integration test for theme persistence in Tests/ThemeTests/ThemePersistenceTests.swift
- [ ] T036b [US3] Integration test for mode-specific theme switching in Tests/ThemeTests/ModeSwitchingTests.swift

### Implementation for User Story 3

- [ ] T036 [US3] Implement independent theme storage in UserThemePreferences (separate lightThemeId and darkThemeId)
- [ ] T037 [US3] Implement effective theme calculation logic in EnhancedThemeManager.effectiveTheme computed property
- [ ] T038 [US3] Implement system appearance change monitoring in SystemAppearanceMonitor
- [ ] T039 [US3] Add automatic theme switching based on system appearance in EnhancedThemeManager
- [ ] T040 [US3] Implement theme persistence that maintains separate preferences for light/dark modes
- [ ] T041 [US3] Add notification system for theme changes due to system appearance
- [ ] T042 [US3] Update UI to show appropriate theme group based on current mode selection

**Checkpoint**: All user stories should now be independently functional

---

## Phase 6: User Story 4 - 主题即时预览功能 (Priority: P2)

**Goal**: 用户在设置中选择主题时，可以立即看到主题效果的预览，无需确认设置就能预览主题效果

**Independent Test**: 可以通过在设置界面浏览不同主题并验证预览效果来独立测试

### Tests for User Story 4 ⚠️

- [ ] T043 [P] [US4] Unit test for theme preview state management in Tests/ThemeTests/ThemePreviewStateTests.swift
- [ ] T044 [US4] UI test for theme preview interaction in Tests/ThemeUITests/ThemePreviewUITests.swift
- [ ] T044a [US4] Integration test for theme preview on hover in Tests/ThemeTests/PreviewHoverTests.swift
- [ ] T044b [US4] Integration test for preview theme application in Tests/ThemeTests/PreviewApplicationTests.swift
- [ ] T044c [US4] Integration test for preview state persistence in Tests/ThemeTests/PreviewPersistenceTests.swift

### Implementation for User Story 4

- [ ] T045 [US4] Create theme preview state model in MiniCal/Themes/Models/ThemePreviewState.swift
- [ ] T046 [US4] Implement theme preview functionality in EnhancedThemeManager.startPreview() and stopPreview()
- [ ] T047 [US4] Add hover gesture handling in ThemeCard for preview on hover
- [ ] T048 [US4] Implement preview theme application without saving preferences
- [ ] T049 [US4] Add preview cancel functionality when mouse leaves theme card
- [ ] T050 [US4] Update CalendarView to respond to theme preview notifications
- [ ] T051 [US4] Add smooth transition animations for theme preview
- [ ] T052 [US4] Implement preview state persistence (remember last preview during session)

**Checkpoint**: Theme preview functionality should now work seamlessly

---

## Phase 7: Integration with Existing Components

**Purpose**: Integrate theme system with existing calendar functionality

**Important**: 主题切换不影响系统菜单栏表示，菜单栏显示依赖系统进行调度。仅日历弹窗窗口（popover）应用主题。

- [ ] T053 [P] Update CalendarView.swift to use theme-aware colors and styles
- [ ] T054 [P] Update MenuBarController.swift - Calendar popover window applies theme, menu bar icon remains system-controlled
- [ ] T055 Update existing UI components to use ThemeableComponents
- [ ] T056 Implement theme-aware color extensions for all UI elements (excluding system menu bar)
- [ ] T057 Add theme notification observers to existing view controllers

---

## Phase 8: Performance Optimization & Polish

**Purpose**: Optimize performance and add finishing touches

- [ ] T058 [P] Implement lazy loading for theme resources
- [ ] T059 [P] Add memory pressure handling for theme cache
- [ ] T060 Optimize theme switching animation performance
- [ ] T061 Add performance monitoring and metrics collection
- [ ] T062 Implement error handling for corrupted theme files
- [ ] T063 Add accessibility support for theme selection (VoiceOver, keyboard navigation)
- [ ] T064 Implement theme transition animations with CATransaction
- [ ] T065 Add high contrast theme support for accessibility

---

## Phase 9: Testing & Quality Assurance

**Purpose**: Comprehensive testing and quality validation

- [ ] T066 [P] Create comprehensive unit tests for all theme models in Tests/ThemeTests/
- [ ] T067 [P] Create UI tests for theme settings interaction in Tests/ThemeUITests/
- [ ] T068 Create performance tests for theme switching speed
- [ ] T069 Create memory leak tests for theme cache management
- [ ] T069a Create UI integrity validation tests for theme switching (FR-012) in Tests/ThemeTests/UIIntegrityTests.swift
- [ ] T070 Create accessibility tests for theme selection interface
- [ ] T071 Create integration tests for system appearance changes
- [ ] T072 Create visual regression tests for theme appearance

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories
- **User Stories (Phase 3-6)**: All depend on Foundational phase completion
  - User stories can then proceed in parallel (if staffed)
  - Or sequentially in priority order (US1/US2 → US3 → US4)
- **Integration (Phase 7)**: Depends on core user stories being complete
- **Optimization (Phase 8)**: Depends on integration being complete
- **Testing (Phase 9)**: Depends on all implementation phases being complete

### User Story Dependencies

- **User Story 1 (P1)**: Can start after Foundational (Phase 2) - No dependencies on other stories
- **User Story 2 (P1)**: Can start after Foundational (Phase 2) - Builds on US1 but independently testable
- **User Story 3 (P2)**: Can start after US1/US2 - Depends on theme selection framework
- **User Story 4 (P2)**: Can start after US1/US2 - Depends on theme system foundation

### Within Each User Story

- Tests (if included) MUST be written and FAIL before implementation
- Models before services
- Services before UI components
- Core implementation before integration
- Story complete before moving to next priority

### Parallel Opportunities

- All Setup tasks marked [P] can run in parallel
- All Foundational tasks marked [P] can run in parallel (within Phase 2)
- Once Foundational phase completes, US1 and US2 can start in parallel (if team capacity allows)
- All tests for a user story marked [P] can run in parallel
- Models within a story marked [P] can run in parallel
- Different user stories can be worked on in parallel by different team members

---

## Parallel Example: User Story 1

```bash
# Launch all tests for User Story 1 together:
Task: "Unit test for ThemeMode enum functionality in Tests/ThemeTests/ThemeModelsTests.swift"
Task: "Unit test for theme configuration loading in Tests/ThemeTests/ThemeConfigurationTests.swift"
Task: "Integration test for theme mode switching in Tests/ThemeTests/ThemeModeIntegrationTests.swift"

# Launch core components for User Story 1 together:
Task: "Create enhanced theme manager class in MiniCal/Themes/Services/EnhancedThemeManager.swift"
Task: "Create theme settings view in MiniCal/Themes/Views/ThemeSettingsView.swift"
Task: "Create theme selection UI components in MiniCal/Themes/Views/ThemeCard.swift"
```

---

## Implementation Strategy

### MVP First (User Stories 1 & 2 Only)

1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (CRITICAL - blocks all stories)
3. Complete Phase 3: User Story 1 - Basic theme mode selection
4. Complete Phase 4: User Story 2 - Chrome theme library
5. **STOP and VALIDATE**: Test User Stories 1 & 2 independently
6. Deploy/demo if ready

### Incremental Delivery

1. Complete Setup + Foundational → Foundation ready
2. Add User Story 1 & 2 → Test independently → Deploy/Demo (MVP!)
3. Add User Story 3 → Test independently → Deploy/Demo
4. Add User Story 4 → Test independently → Deploy/Demo
5. Complete Integration & Optimization phases
6. Each story adds value without breaking previous stories

### Parallel Team Strategy

With multiple developers:

1. Team completes Setup + Foundational together
2. Once Foundational is done:
   - Developer A: User Story 1 (Theme mode selection)
   - Developer B: User Story 2 (Chrome theme library)
3. After US1/US2 complete:
   - Developer A: User Story 3 (Independent preferences)
   - Developer B: User Story 4 (Preview functionality)
4. Team completes Integration & Optimization together

---

## Success Criteria per Phase

### Phase 1-2 (Foundation)
- [ ] All theme models compile without errors
- [ ] Theme cache system loads built-in themes successfully
- [ ] System appearance monitoring works correctly

### Phase 3-4 (MVP)
- [ ] User can select theme mode (Light/Dark/Auto)
- [ ] User can select from Chrome-inspired themes
- [ ] Theme changes persist across app restarts
- [ ] UI updates correctly reflect theme changes

### Phase 5-6 (Full Features)
- [ ] Light and dark themes work independently
- [ ] System appearance changes trigger automatic theme switches
- [ ] Theme preview works on hover without saving
- [ ] All transitions are smooth and performant

### Phase 7-9 (Polish & Quality)
- [ ] All existing UI components support themes
- [ ] Performance benchmarks met (<100ms switching)
- [ ] All accessibility features work correctly
- [ ] Comprehensive test coverage achieved

---

## Notes

- [P] tasks = different files, no dependencies
- [Story] label maps task to specific user story for traceability
- Each user story should be independently completable and testable
- Verify tests fail before implementing
- Commit after each task or logical group
- Stop at any checkpoint to validate story independently
- Avoid: vague tasks, same file conflicts, cross-story dependencies that break independence
- Performance targets: <100ms theme switching, <50ms preview response, <100MB memory usage