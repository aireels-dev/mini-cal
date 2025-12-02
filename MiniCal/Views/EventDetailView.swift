//
//  EventDetailView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct EventDetailView: View {
    let date: CalendarDate
    let themeColors: ThemeColors
    let onClose: () -> Void
    @EnvironmentObject var viewModel: CalendarViewModel

    @State private var showingEventCreation = false
    @State private var showingEventDetail = false
    @State private var selectedEvent: CalendarEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // 标题栏
            HStack {
                Text(dateText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(themeColors.textColor)

                Spacer()

                HStack(spacing: 8) {
                    // 添加事件按钮
                    Button(action: { showingEventCreation = true }) {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(themeColors.accentColor)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("添加事件")

                    // 关闭按钮
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(themeColors.secondaryTextColor)
                            .font(.system(size: 18))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .help("关闭")
                }
            }

            Divider()
                .background(themeColors.borderColor)

            // 事件列表
            if viewModel.isLoadingEvents {
                VStack(spacing: 12) {
                    ProgressView()
                        .scaleEffect(0.8)
                    Text("event.loading")
                        .font(.system(size: 14))
                        .foregroundColor(themeColors.secondaryTextColor)
                }
                .padding()
            } else if let error = viewModel.eventLoadError {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.orange)
                        .font(.system(size: 20))
                    Text("event.load_failed")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(themeColors.textColor)
                    Text(error.localizedDescription)
                        .font(.system(size: 12))
                        .foregroundColor(themeColors.secondaryTextColor)
                        .multilineTextAlignment(.center)
                    Button("重试") {
                        viewModel.loadEvents(for: date.gregorianDate)
                    }
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.accentColor)
                }
                .padding()
            } else {
                let dayEvents = viewModel.getEventsForDate(date.gregorianDate)
                CalendarEventView(
                    events: dayEvents,
                    selectedDate: date.gregorianDate,
                    onEventTap: { event in
                        // 处理事件点击，可以显示详情或执行其他操作
                        handleEventTap(event)
                    }
                )
                .frame(maxHeight: 350)
            }

            // 订阅源状态指示器
            Divider()
                .background(themeColors.borderColor)
                .padding(.top, 4)

            SubscriptionStatusIndicator(
                syncStatus: viewModel.syncStatusMonitor.overallSyncStatus,
                themeColors: themeColors,
                onRefresh: {
                    Task {
                        await viewModel.refreshAllSubscriptions()
                    }
                }
            )
        }
        .padding(16)
        .frame(width: 350)
        .background(
            VisualEffectView(
                material: .hudWindow,
                blendingMode: .behindWindow,
                state: .active
            )
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 4)
        .sheet(isPresented: $showingEventCreation) {
            EventCreationView(
                selectedDate: date.gregorianDate,
                onSave: { event in
                    Task {
                        try await viewModel.createEvent(event)
                        showingEventCreation = false
                    }
                },
                onCancel: {
                    showingEventCreation = false
                }
            )
        }
        // 移除重复加载：事件已由 CalendarViewModel 统一加载
        .sheet(isPresented: $showingEventDetail) {
            if let event = selectedEvent {
                EventDetailModalView(event: event)
                    .environmentObject(viewModel)
            }
        }
    }

    private var dateText: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "zh_CN")
        formatter.dateFormat = "M月d日 EEEE"
        return formatter.string(from: date.gregorianDate)
    }

    private func handleEventTap(_ event: CalendarEvent) {
        selectedEvent = event
        showingEventDetail = true
    }
}

// MARK: - Subscription Status Indicator

struct SubscriptionStatusIndicator: View {
    let syncStatus: OverallSyncStatus
    let themeColors: ThemeColors
    let onRefresh: () -> Void

    var body: some View {
        HStack {
            statusIndicator
            Text(statusText)
                .font(.system(size: 11))
                .foregroundColor(themeColors.secondaryTextColor)

            Spacer()

            Button(action: onRefresh) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 12))
                    .foregroundColor(themeColors.accentColor)
            }
            .buttonStyle(PlainButtonStyle())
            .help("刷新订阅")
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(themeColors.backgroundColor.opacity(0.3))
        .cornerRadius(6)
    }

    private var statusIndicator: some View {
        Group {
            switch syncStatus {
            case .idle:
                Circle()
                    .fill(Color.gray)
                    .frame(width: 6, height: 6)
            case .syncing:
                ProgressView()
                    .scaleEffect(0.6)
            case .error:
                Image(systemName: "exclamationmark.triangle.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 8))
            }
        }
    }

    private var statusText: String {
        return syncStatus.displayName
    }
}

// MARK: - Event Creation View

struct EventCreationView: View {
    let selectedDate: Date
    let onSave: (CalendarEvent) -> Void
    let onCancel: () -> Void

    @State private var eventTitle = ""
    @State private var eventNotes = ""
    @State private var isAllDay = false
    @State private var startTime = Date()
    @State private var endTime = Date().addingTimeInterval(3600)

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("event.title")
                        .font(.headline)
                    TextField("输入事件标题", text: $eventTitle)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }

                VStack(alignment: .leading, spacing: 8) {
                    Toggle("全天事件", isOn: $isAllDay)

                    if !isAllDay {
                        HStack {
                            VStack(alignment: .leading) {
                                Text("event.start_time")
                                    .font(.caption)
                                DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                            }

                            Spacer()

                            VStack(alignment: .leading) {
                                Text("event.end_time")
                                    .font(.caption)
                                DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                            }
                        }
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("common.note")
                        .font(.headline)
                    TextField("输入备注（可选）", text: $eventNotes, axis: .vertical)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .lineLimit(3...6)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("新建事件")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("取消") {
                        onCancel()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        saveEvent()
                    }
                    .disabled(eventTitle.isEmpty)
                }
            }
        }
        .onAppear {
            startTime = selectedDate
            endTime = selectedDate.addingTimeInterval(3600)
        }
    }

    private func saveEvent() {
        var newEvent = CalendarEvent(
            title: eventTitle,
            startDate: isAllDay ? Calendar.current.startOfDay(for: selectedDate) : startTime,
            endDate: isAllDay ? Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: selectedDate))! : endTime,
            source: .user
        )
        newEvent.notes = eventNotes.isEmpty ? nil : eventNotes
        newEvent.isAllDay = isAllDay
        onSave(newEvent)
    }
}

#Preview {
    let testDate = CalendarDate(date: Date(), isCurrentMonth: true)

    EventDetailView(
        date: testDate,
        themeColors: .light,
        onClose: {}
    )
    .environmentObject(CalendarViewModel())
}
