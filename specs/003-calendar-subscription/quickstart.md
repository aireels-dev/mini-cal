# Quick Start Guide: 日历事件订阅管理

**Feature**: `003-calendar-subscription` | **Date**: 2025-10-30
**Target Audience**: 开发者和测试人员

## 快速开始

本指南将帮助您快速理解和使用日历事件订阅管理功能。包括开发环境设置、核心功能演示和测试场景。

## 开发环境要求

### 系统要求

- macOS 11.0+
- Xcode 14.0+
- Swift 5.9+
- EventKit权限（系统日历访问）

## Quick Setup

### 1. 基本初始化

```swift
import SwiftUI
import MiniCal

@main
struct MiniCalApp: App {
    @StateObject private var calendarService = CalendarService()
    @StateObject private var subscriptionService = CalendarSubscriptionService()
    @StateObject private var eventService = CalendarEventService()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(calendarService)
                .environmentObject(subscriptionService)
                .environmentObject(eventService)
        } label: {
            MenuBarIcon()
        }
    }
}
```

### 2. 权限请求

```swift
class PermissionManager: ObservableObject {
    @Published var isAuthorized = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined

    private let eventStore = EKEventStore()

    func requestPermission() async {
        let status = EKEventStore.authorizationStatus(for: .event)

        switch status {
        case .authorized:
            isAuthorized = true
        case .denied, .restricted:
            isAuthorized = false
        case .notDetermined:
            if #available(macOS 14.0, *) {
                let granted = try? await eventStore.requestFullAccessToEvents()
                isAuthorized = granted ?? false
            } else {
                let granted = await withCheckedContinuation { continuation in
                    eventStore.requestAccess(to: .event) { granted, _ in
                        continuation.resume(returning: granted)
                    }
                }
                isAuthorized = granted
            }
        @unknown default:
            isAuthorized = false
        }

        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
    }
}
```

## Core Usage Examples

### 1. 显示日历事件

```swift
struct CalendarView: View {
    @StateObject private var calendarViewModel = CalendarViewModel()
    @State private var selectedDate = Date()

    var body: some View {
        VStack {
            // 月份导航
            MonthNavigationView(
                currentDate: $selectedDate,
                onMonthChange: { newDate in
                    calendarViewModel.loadEvents(for: newDate)
                }
            )

            // 日历网格
            CalendarGridView(
                currentDate: selectedDate,
                events: calendarViewModel.events
            ) { date in
                // 点击日期处理
                showEventList(for: date)
            }
        }
        .onAppear {
            calendarViewModel.loadEvents(for: selectedDate)
        }
    }

    private func showEventList(for date: Date) {
        // 显示事件列表
        calendarViewModel.selectedDate = date
        calendarViewModel.showEventList = true
    }
}
```

### 2. 添加系统日历订阅

```swift
struct SubscriptionManagerView: View {
    @StateObject private var subscriptionService = CalendarSubscriptionService()
    @State private var showingAddAlert = false
    @State private var newSubscriptionURL = ""

    var body: some View {
        VStack {
            List {
                ForEach(subscriptionService.subscriptions) { subscription in
                    SubscriptionRowView(subscription: subscription)
                }
            }

            Button("添加外部订阅") {
                showingAddAlert = true
            }

            Button("检测系统日历") {
                Task {
                    await detectAndAddSystemCalendars()
                }
            }
        }
        .alert("添加订阅", isPresented: $showingAddAlert) {
            TextField("订阅URL", text: $newSubscriptionURL)
            Button("添加") {
                addExternalSubscription()
            }
            Button("取消", role: .cancel) { }
        }
    }

    private func addExternalSubscription() {
        Task {
            do {
                guard let url = URL(string: newSubscriptionURL) else {
                    // 显示错误
                    return
                }

                try await subscriptionService.addExternalSubscription(
                    url: url,
                    name: extractName(from: url)
                )
                newSubscriptionURL = ""
            } catch {
                // 处理错误
            }
        }
    }

    private func detectAndAddSystemCalendars() async {
        do {
            let systemCalendars = await subscriptionService.detectSystemCalendars()
            for calendar in systemCalendars {
                try await subscriptionService.addSubscription(calendar)
            }
        } catch {
            // 处理错误
        }
    }
}
```

### 3. 创建新事件

```swift
struct EventCreationView: View {
    let targetDate: Date
    let onSave: (DateEvent) -> Void
    let onCancel: () -> Void

    @State private var title = ""
    @State private var description = ""
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)
    @State private var isAllDay = false
    @State private var location = ""
    @State private var selectedColor: Color = .blue

    @StateObject private var eventService = CalendarEventService()
    @State private var isCreating = false
    @State private var errorMessage: String?

    var body: some View {
        VStack(spacing: 16) {
            // 标题输入
            VStack(alignment: .leading) {
                Text("事件标题")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("输入事件标题", text: $title)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 时间设置
            HStack {
                VStack(alignment: .leading) {
                    Text("开始时间")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DatePicker("", selection: $startTime, displayedComponents: isAllDay ? [] : [.date, .hourAndMinute])
                        .labelsHidden()
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("结束时间")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    DatePicker("", selection: $endTime, displayedComponents: isAllDay ? [] : [.date, .hourAndMinute])
                        .labelsHidden()
                }
            }

            Toggle("全天事件", isOn: $isAllDay)

            // 事件类型和颜色选择
            HStack {
                VStack(alignment: .leading) {
                    Text("事件颜色")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    ColorPicker("", selection: $selectedColor)
                        .labelsHidden()
                }

                Spacer()

                VStack(alignment: .leading) {
                    Text("事件类型")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Picker("类型", selection: .constant(.meeting)) {
                        ForEach(EventType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }
            }

            // 位置输入
            VStack(alignment: .leading) {
                Text("地点")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextField("输入地点（可选）", text: $location)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
            }

            // 描述输入
            VStack(alignment: .leading) {
                Text("描述")
                    .font(.caption)
                    .foregroundColor(.secondary)

                TextEditor(text: $description)
                    .frame(height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                    )
            }

            // 错误信息
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.top, 4)
            }

            // 操作按钮
            HStack {
                Button("取消") {
                    onCancel()
                }
                .buttonStyle(PlainButtonStyle())

                Spacer()

                Button("保存") {
                    createEvent()
                }
                .buttonStyle(BorderedButtonStyle())
                .disabled(title.isEmpty || isCreating)
            }

            if isCreating {
                ProgressView("保存中...")
                    .padding(.top, 8)
            }
        }
        .padding()
        .frame(width: 400)
        .onAppear {
            startTime = targetDate
            endTime = targetDate.addingTimeInterval(3600)
        }
    }

    private func createEvent() {
        isCreating = true
        errorMessage = nil

        Task {
            do {
                let event = DateEvent(
                    title: title,
                    date: targetDate,
                    type: .meeting,
                    color: EventColor(selectedColor),
                    source: .user,
                    startDate: isAllDay ? Calendar.current.startOfDay(for: startTime) : startTime,
                    endDate: isAllDay ? Calendar.current.startOfDay(for: endTime).addingTimeInterval(86400) : endTime,
                    allDay: isAllDay,
                    location: location.isEmpty ? nil : location,
                    notes: description.isEmpty ? nil : description
                )

                let createdEvent = try await eventService.createEvent(event)

                await MainActor.run {
                    isCreating = false
                    onSave(createdEvent)
                }
            } catch {
                await MainActor.run {
                    isCreating = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
```

### 4. 事件列表显示

```swift
struct EventListView: View {
    let date: Date
    let events: [DateEvent]
    let onCreateEvent: () -> Void
    let onEventTap: (DateEvent) -> Void

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            HStack {
                Text(date.formatted(.dateTime.month().day()))
                    .font(.title2)
                    .fontWeight(.semibold)

                Spacer()

                Button(action: onCreateEvent) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
            }
            .padding()

            // 事件列表
            if events.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.plus")
                        .font(.largeTitle)
                        .foregroundColor(.secondary)

                    Text("暂无事件")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("点击下方按钮添加新事件")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Button("添加事件") {
                        onCreateEvent()
                    }
                    .buttonStyle(BorderedButtonStyle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(events) { event in
                            EventRowView(event: event) {
                                onEventTap(event)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .frame(width: 350, height: 400)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct EventRowView: View {
    let event: DateEvent
    let onTap: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 颜色标识
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(event.color))
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 4) {
                // 事件标题
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(1)

                // 时间信息
                HStack {
                    Text(formatEventTime(event.startDate, to: event.endDate))
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if event.isAllDay {
                        Text("全天")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    if let location = event.location {
                        Text("• \(location)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }

            Spacer()

            // 可编辑指示器
            if event.isEditable {
                Image(systemName: "pencil.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap()
        }
    }

    private func formatEventTime(_ startDate: Date, to endDate: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short

        if Calendar.current.isDate(startDate, inSameDayAs: endDate) {
            return formatter.string(from: startDate) + " - " + formatter.string(from: endDate)
        } else {
            formatter.dateStyle = .short
            formatter.timeStyle = .short
            return formatter.string(from: startDate) + " - " + formatter.string(from: endDate)
        }
    }
}
```

### 5. 订阅源管理

```swift
struct SubscriptionRowView: View {
    @ObservedObject var subscription: CalendarSubscription
    let onToggle: (UUID) -> Void
    let onDelete: (UUID) -> Void
    let onColorChange: (UUID, Color) -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 状态指示器
            Circle()
                .fill(subscription.isActive ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            // 颜色选择器
            ColorPicker("", selection: Binding(
                get: { subscription.color },
                set: { newColor in
                    onColorChange(subscription.id, newColor)
                }
            ))
            .labelsHidden()
            .disabled(!subscription.isActive)

            // 订阅源信息
            VStack(alignment: .leading, spacing: 4) {
                Text(subscription.name)
                    .font(.body)
                    .fontWeight(.medium)

                HStack {
                    Text(subscription.source.displayName)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let lastSync = subscription.lastSyncDate {
                        Text("• \(lastSync.formatted(.relative(presentation: .named)))")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Text("\(subscription.eventCount) 个事件")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            // 操作按钮
            HStack(spacing: 8) {
                Button(action: { onToggle(subscription.id) }) {
                    Image(systemName: subscription.isActive ? "eye" : "eye.slash")
                        .font(.caption)
                }
                .buttonStyle(PlainButtonStyle())

                Button(action: { onDelete(subscription.id) }) {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(.vertical, 8)
    }
}
```

## Testing Examples

### 1. 服务测试

```swift
import XCTest
@testable import MiniCal

class CalendarSubscriptionServiceTests: XCTestCase {
    var subscriptionService: CalendarSubscriptionService!
    var mockEventStore: MockEKEventStore!
    var mockColorService: MockColorManagementService!

    override func setUp() {
        super.setUp()
        mockEventStore = MockEKEventStore()
        mockColorService = MockColorManagementService()
        subscriptionService = CalendarSubscriptionService(
            eventStore: mockEventStore,
            colorService: mockColorService
        )
    }

    func testAddSubscription() async throws {
        // Given
        let subscription = CalendarSubscription(
            name: "测试日历",
            color: .blue,
            source: .external
        )

        // When
        try await subscriptionService.addSubscription(subscription)

        // Then
        let subscriptions = await subscriptionService.getAllSubscriptions().values.first!
        XCTAssertTrue(subscriptions.contains(subscription))
    }

    func testValidateSubscriptionURL() async {
        // Given
        let validURL = URL(string: "https://example.com/calendar.ics")!
        let invalidURL = URL(string: "https://example.com/invalid")!

        // When
        let validResult = await subscriptionService.validateSubscriptionURL(validURL)
        let invalidResult = await subscriptionService.validateSubscriptionURL(invalidURL)

        // Then
        XCTAssertTrue(validResult.isValid)
        XCTAssertFalse(invalidResult.isValid)
    }
}
```

### 2. UI测试

```swift
import XCTest
@testable import MiniCal

class CalendarViewUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }

    func testCalendarViewDisplaysEvents() {
        // 点击菜单栏图标
        app.statusItems.firstMatch.click()

        // 验证日历视图显示
        XCTAssertTrue.app.windows["MiniCal"].exists)

        // 验证事件显示
        let eventItems = app.scrollViews.firstMatch.buttons
        XCTAssertTrue(eventItems.count > 0)
    }

    func testCreateEventFlow() {
        // 点击菜单栏图标
        app.statusItems.firstMatch.click()

        // 点击有事件的日期
        app.buttons["今天"].click()

        // 点击添加事件按钮
        app.buttons["添加事件"].click()

        // 填写事件信息
        let titleField = app.textFields["事件标题"]
        titleField.tap()
        titleField.typeText("测试事件")

        // 点击保存
        app.buttons["保存"].click()

        // 验证事件创建成功
        XCTAssertTrue(app.alerts["成功"].exists)
    }
}
```

## Performance Tips

### 1. 事件缓存

```swift
class CachedCalendarService: CalendarService {
    private let cache = NSCache<NSString, [DateEvent]>()
    private let cacheQueue = DispatchQueue(label: "cache", qos: .userInitiated)

    override func getEvents(for date: Date) -> AnyPublisher<[DateEvent], Error> {
        let cacheKey = date.description as NSString

        return Future { [weak self] promise in
            self?.cacheQueue.async {
                if let cached = self?.cache.object(forKey: cacheKey) {
                    promise(.success(cached))
                    return
                }

                super.getEvents(for: date)
                    .sink(
                        receiveCompletion: { completion in
                            if case .failure(let error) = completion {
                                promise(.failure(error))
                            }
                        },
                        receiveValue: { events in
                            self?.cache.setObject(events, forKey: cacheKey)
                            promise(.success(events))
                        }
                    )
                    .store(in: &self.cancellables)
            }
        }
        .eraseToAnyPublisher()
    }
}
```

### 2. 增量同步

```swift
class IncrementalSyncService: CalendarSyncService {
    private var lastSyncDates: [UUID: Date] = [:]

    func syncSubscriptionIncremental(id: UUID) async throws {
        let lastSyncDate = lastSyncDates[id] ?? Date.distantPast
        let now = Date()

        // 只同步指定日期后的事件
        let events = try await fetchEventsSince(lastSyncDate, for: id)

        // 更新本地缓存
        try await updateLocalCache(with: events, for: id)

        // 记录同步时间
        lastSyncDates[id] = now
    }
}
```

## Troubleshooting

### Common Issues

1. **权限被拒绝**
   ```swift
   // 检查权限状态
   let status = EKEventStore.authorizationStatus(for: .event)
   if status == .denied {
       // 引导用户到系统设置
       NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars")!)
   }
   ```

2. **同步失败**
   ```swift
   // 实现重试机制
   func syncWithRetry(subscriptionId: UUID, maxRetries: Int = 3) async throws {
       for attempt in 1...maxRetries {
           do {
               try await syncSubscription(subscriptionId)
               return
           } catch {
               if attempt == maxRetries {
                   throw error
               }
               try await Task.sleep(nanoseconds: UInt64(pow(2.0, Double(attempt)) * 1_000_000_000))
           }
       }
   }
   ```

3. **内存使用过高**
   ```swift
   // 定期清理缓存
   Timer.scheduledTimer(withTimeInterval: 300, repeats: true) { _ in
       calendarService.clearOldCache()
   }
   ```

## Best Practices

1. **错误处理**: 始终提供用户友好的错误信息和恢复建议
2. **性能**: 使用缓存和异步操作避免阻塞UI
3. **权限**: 优雅处理权限拒绝情况，提供降级功能
4. **测试**: 为关键功能编写单元测试和UI测试
5. **用户体验**: 提供加载指示器和进度反馈
6. **数据一致性**: 使用事务确保数据完整性
7. **资源管理**: 及时释放不需要的资源，避免内存泄漏

这个快速入门指南提供了日历事件订阅管理功能的核心使用示例和最佳实践，帮助开发者快速集成和使用这些功能。