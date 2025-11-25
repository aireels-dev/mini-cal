//
//  DayEventListView.swift
//  MiniCal
//
//  日期事件列表视图
//

import SwiftUI

struct DayEventListView: View {
    let date: Date
    let events: [CalendarEvent]
    let themeColors: ThemeColors
    let onEventTap: (CalendarEvent) -> Void
    let onManageEvents: () -> Void
    let onSaveEvent: (CalendarEvent) -> Void

    @State private var showCreateForm = false
    @State private var newEventTitle = ""
    @State private var newEventStartDate: Date
    @State private var newEventEndDate: Date
    @State private var isAllDay = false
    @State private var newEventLocation = ""
    @State private var newEventNotes = ""
    @State private var showValidationError = false

    init(date: Date,
         events: [CalendarEvent],
         themeColors: ThemeColors,
         onEventTap: @escaping (CalendarEvent) -> Void,
         onManageEvents: @escaping () -> Void,
         onSaveEvent: @escaping (CalendarEvent) -> Void) {
        self.date = date
        self.events = events
        self.themeColors = themeColors
        self.onEventTap = onEventTap
        self.onManageEvents = onManageEvents
        self.onSaveEvent = onSaveEvent

        // 初始化默认时间
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: date)
        let nextHour = (startHour + 1) % 24

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = nextHour
        components.minute = 0

        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? date

        _newEventStartDate = State(initialValue: start)
        _newEventEndDate = State(initialValue: end)
    }

    var body: some View {
        VStack(spacing: 0) {
            // 头部
            DayEventHeader(date: date, themeColors: themeColors)

            Divider()
                .background(themeColors.borderColor)

            // 内容区域：根据状态显示列表或表单
            if showCreateForm {
                createEventFormView
            } else {
                // 事件列表
                if events.isEmpty {
                    emptyStateView
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(sortedEvents) { event in
                                DayEventRow(
                                    event: event,
                                    themeColors: themeColors,
                                    onTap: {
                                        onEventTap(event)
                                    }
                                )

                                if event.id != sortedEvents.last?.id {
                                    Divider()
                                        .background(themeColors.borderColor.opacity(0.3))
                                        .padding(.horizontal, 16)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    .frame(maxHeight: 300)
                }
            }

            Divider()
                .background(themeColors.borderColor)

            // 底部操作区
            bottomActionView
        }
        .frame(width: 350, height: showCreateForm ? 480 : nil)  // 动态高度：表单模式480，列表模式自适应
        .background(
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
    }

    // MARK: - Empty State View

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(themeColors.secondaryTextColor.opacity(0.5))

            VStack(spacing: 4) {
                Text("这天没有事件")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(themeColors.textColor)

                Text("享受轻松的一天")
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.secondaryTextColor)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 50)
    }

    // MARK: - Bottom Action View

    private var bottomActionView: some View {
        HStack {
            if showCreateForm {
                // 表单模式：取消和保存按钮
                Button(action: cancelCreateEvent) {
                    HStack(spacing: 6) {
                        Image(systemName: "xmark.circle")
                            .font(.system(size: 13))
                        Text("取消")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(themeColors.secondaryTextColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeColors.backgroundColor.opacity(0.3))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)

                Button(action: saveNewEvent) {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 13))
                        Text("保存")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeColors.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)
                .disabled(!isValidInput)
            } else {
                // 列表模式：添加事件和管理订阅按钮
                Button(action: { showCreateForm = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 13))
                        Text("添加事件")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeColors.accentColor)
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)

                Button(action: onManageEvents) {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar.badge.plus")
                            .font(.system(size: 13))
                        Text("管理订阅")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(themeColors.accentColor)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(themeColors.accentColor.opacity(0.1))
                    .cornerRadius(6)
                }
                .buttonStyle(PlainButtonStyle())
                .focusable(false)

                Spacer()

                // 事件统计
                Text("\(events.count) 个事件")
                    .font(.system(size: 11))
                    .foregroundColor(themeColors.secondaryTextColor)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(themeColors.backgroundColor.opacity(0.3))
    }

    // MARK: - Create Event Form View

    private var createEventFormView: some View {
        ScrollView {
            VStack(spacing: 14) {
                // 标题输入
                VStack(alignment: .leading, spacing: 6) {
                    Text("标题")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor)

                    TextField("事件标题", text: $newEventTitle)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .padding(8)
                        .background(themeColors.backgroundColor.opacity(0.3))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(showValidationError && newEventTitle.isEmpty ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                }

                // 全天开关
                Toggle(isOn: $isAllDay) {
                    Text("全天")
                        .font(.system(size: 13))
                        .foregroundColor(themeColors.textColor)
                }
                .toggleStyle(.switch)

                // 时间选择
                VStack(spacing: 8) {
                    HStack {
                        Text("开始")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeColors.secondaryTextColor)
                            .frame(width: 45, alignment: .leading)

                        DatePicker("", selection: $newEventStartDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    HStack {
                        Text("结束")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(themeColors.secondaryTextColor)
                            .frame(width: 45, alignment: .leading)

                        DatePicker("", selection: $newEventEndDate, displayedComponents: isAllDay ? [.date] : [.date, .hourAndMinute])
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }

                    if newEventEndDate <= newEventStartDate {
                        Text("结束时间必须晚于开始时间")
                            .font(.system(size: 10))
                            .foregroundColor(.red)
                    }
                }

                // 位置输入（可选）
                VStack(alignment: .leading, spacing: 6) {
                    Text("位置（可选）")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor)

                    TextField("添加位置", text: $newEventLocation)
                        .textFieldStyle(PlainTextFieldStyle())
                        .font(.system(size: 13))
                        .padding(8)
                        .background(themeColors.backgroundColor.opacity(0.3))
                        .cornerRadius(6)
                }

                // 备注输入（可选）
                VStack(alignment: .leading, spacing: 6) {
                    Text("备注（可选）")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(themeColors.secondaryTextColor)

                    TextEditor(text: $newEventNotes)
                        .font(.system(size: 13))
                        .frame(height: 60)
                        .padding(4)
                        .background(themeColors.backgroundColor.opacity(0.3))
                        .cornerRadius(6)
                        .scrollContentBackground(.hidden)
                }
            }
            .padding(16)
        }
        .frame(height: 360)  // 固定高度，确保表单完全可视
        .simultaneousGesture(  // 阻止滚动手势传播到父视图
            DragGesture(minimumDistance: 0)
                .onChanged { _ in }
        )
    }

    // MARK: - Form Actions

    private var isValidInput: Bool {
        return !newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
               newEventEndDate > newEventStartDate
    }

    private func saveNewEvent() {
        guard isValidInput else {
            showValidationError = true
            return
        }

        // 创建本地事件
        var event = CalendarEvent(
            title: newEventTitle.trimmingCharacters(in: .whitespacesAndNewlines),
            startDate: newEventStartDate,
            endDate: newEventEndDate,
            source: .user,
            isAllDay: isAllDay
        )

        if !newEventLocation.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            event.location = newEventLocation.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if !newEventNotes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            event.notes = newEventNotes.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        onSaveEvent(event)
        resetForm()
        showCreateForm = false
    }

    private func cancelCreateEvent() {
        resetForm()
        showCreateForm = false
    }

    private func resetForm() {
        newEventTitle = ""
        newEventLocation = ""
        newEventNotes = ""
        isAllDay = false
        showValidationError = false

        // 重置时间为默认值
        let calendar = Calendar.current
        let startHour = calendar.component(.hour, from: date)
        let nextHour = (startHour + 1) % 24

        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = nextHour
        components.minute = 0

        let start = calendar.date(from: components) ?? date
        let end = calendar.date(byAdding: .hour, value: 1, to: start) ?? date

        newEventStartDate = start
        newEventEndDate = end
    }

    // MARK: - Computed Properties

    /// 排序后的事件列表（全天事件优先，然后按开始时间排序）
    private var sortedEvents: [CalendarEvent] {
        events.sorted { event1, event2 in
            if event1.isAllDay != event2.isAllDay {
                return event1.isAllDay // 全天事件排前面
            }
            return event1.startDate < event2.startDate
        }
    }
}

#Preview {
    let events = [
        CalendarEvent(
            title: "团队站会",
            startDate: Date(),
            endDate: Date().addingTimeInterval(1800),
            source: .eventKit
        ),
        CalendarEvent(
            title: "产品评审",
            startDate: Date().addingTimeInterval(3600),
            endDate: Date().addingTimeInterval(7200),
            source: .external
        ),
        CalendarEvent(
            title: "周报总结",
            startDate: Date().addingTimeInterval(14400),
            endDate: Date().addingTimeInterval(18000),
            source: .user
        )
    ]

    return VStack(spacing: 20) {
        // 有事件的情况
        DayEventListView(
            date: Date(),
            events: events,
            themeColors: .light,
            onEventTap: { _ in },
            onManageEvents: {},
            onSaveEvent: { _ in }
        )

        // 空状态
        DayEventListView(
            date: Date(),
            events: [],
            themeColors: .light,
            onEventTap: { _ in },
            onManageEvents: {},
            onSaveEvent: { _ in }
        )
    }
}
