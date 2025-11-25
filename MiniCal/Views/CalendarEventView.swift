import SwiftUI

struct CalendarEventView: View {
    let events: [CalendarEvent]
    let selectedDate: Date?
    let onEventTap: (CalendarEvent) -> Void

    @State private var showingEventDetail = false
    @State private var selectedEvent: CalendarEvent?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if events.isEmpty {
                emptyStateView
            } else {
                eventListHeader
                eventListView
            }
        }
        .padding()
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 40))
                .foregroundColor(.secondary)

            Text("暂无事件")
                .font(.headline)
                .foregroundColor(.secondary)

            if let selectedDate = selectedDate {
                Text(selectedDateFormatter.string(from: selectedDate))
                    .font(.caption)
                    .foregroundColor(Color.secondary.opacity(0.7))
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 120)
        .padding(.vertical, 20)
    }

    // MARK: - Event List Header
    private var eventListHeader: some View {
        HStack {
            Text("今日事件")
                .font(.headline)
                .fontWeight(.semibold)

            Spacer()

            Text("\(events.count) 个事件")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 4)
    }

    // MARK: - Event List
    private var eventListView: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(events) { event in
                    EventRowView(event: event) {
                        onEventTap(event)
                    }
                }
            }
            .padding(.horizontal, 4)
        }
        .frame(maxHeight: 300)
    }

    // MARK: - Formatters
    private var selectedDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy年MM月dd日"
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter
    }
}

// MARK: - Event Row View
struct EventRowView: View {
    let event: CalendarEvent
    let onTap: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            // Event color indicator
            RoundedRectangle(cornerRadius: 2)
                .fill(eventColorForEvent(event))
                .frame(width: 4)
                .padding(.vertical, 8)

            VStack(alignment: .leading, spacing: 4) {
                // Event title
                Text(event.title)
                    .font(.body)
                    .fontWeight(.medium)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                // Event time and location
                HStack(spacing: 8) {
                    Text(timeRangeString)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    if let location = event.location {
                        Circle()
                            .fill(Color.secondary)
                            .frame(width: 4, height: 4)

                        Text(location)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                // Event badges
                eventBadges
            }

            Spacer()

            // Event time indicator
            VStack(alignment: .trailing, spacing: 4) {
                if event.isAllDay {
                    Text("全天")
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.blue)
                } else {
                    Text(eventTimeRange)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if event.isCurrentEvent {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHovered ? Color(NSColor.controlAccentColor).opacity(0.1) : Color.clear)
        )
        .onTapGesture {
            onTap()
        }
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
        .focusable(false) // 禁用焦点环，去除蓝色边框
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(event.title), \(timeRangeString)")
    }

    // MARK: - Computed Properties
    private var timeRangeString: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")

        if event.isAllDay {
            return "全天"
        } else if Calendar.current.isDate(event.startDate, inSameDayAs: event.endDate) {
            return "\(formatter.string(from: event.startDate))"
        } else {
            return "\(formatter.string(from: event.startDate)) - \(formatter.string(from: event.endDate))"
        }
    }

    private var eventTimeRange: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")
        return formatter.string(from: event.startDate)
    }

    private var eventBadges: some View {
        HStack(spacing: 4) {
            if event.isMultiDay {
                Text("多日")
                    .font(.caption2)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(4)
                    .foregroundColor(.purple)
            }

            if let attendees = event.attendees, !attendees.isEmpty {
                Image(systemName: "person.2")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if event.url != nil {
                Image(systemName: "link")
                    .font(.caption2)
                    .foregroundColor(.blue)
            }

            if event.recurrenceRule != nil {
                Image(systemName: "repeat")
                    .font(.caption2)
                    .foregroundColor(.green)
            }
        }
    }

    private func eventColorForEvent(_ event: CalendarEvent) -> Color {
        // 根据事件来源返回对应颜色
        return event.getDisplayColor()
    }
}

// MARK: - Event Detail Modal View
struct EventDetailModalView: View {
    let event: CalendarEvent
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var viewModel: CalendarViewModel

    @State private var showingEditView = false
    @State private var showingDeleteAlert = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // Event title
                    Text(event.title)
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 8)

                    // Event time
                    VStack(alignment: .leading, spacing: 8) {
                        Text("时间")
                            .font(.headline)
                        .foregroundColor(.primary)

                        Text(eventTimeDescription)
                            .font(.body)
                            .foregroundColor(.primary)
                    }

                    // Event location
                    if let location = event.location {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("地点")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(location)
                            .font(.body)
                            .foregroundColor(.primary)
                        }
                    }

                    // Event notes
                    if let notes = event.notes {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("备注")
                            .font(.headline)
                            .foregroundColor(.primary)

                        Text(notes)
                            .font(.body)
                            .foregroundColor(.primary)
                        }
                    }

                    // Event attendees
                    if let attendees = event.attendees, !attendees.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("参与者")
                            .font(.headline)
                            .foregroundColor(.primary)

                            ForEach(attendees) { attendee in
                                HStack {
                                    Text(attendee.name)
                                        .font(.body)

                                    Spacer()

                                    statusIndicator(for: attendee.status)
                                }
                            }
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("事件详情")
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    if event.isEditable {
                        // 删除按钮
                        Button(action: { showingDeleteAlert = true }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                        .help("删除事件")
                    }

                    Button("完成") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
        .alert("确认删除", isPresented: $showingDeleteAlert) {
            Button("取消", role: .cancel) {}
            Button("删除", role: .destructive) {
                Task {
                    try await viewModel.deleteEvent(event)
                    presentationMode.wrappedValue.dismiss()
                }
            }
        } message: {
            Text("确定要删除事件「\(event.title)」吗？此操作无法撤销。")
        }
    }

    private var eventTimeDescription: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "zh_CN")

        if event.isAllDay {
            return formatter.string(from: event.startDate)
        } else {
            let startFormatter = DateFormatter()
            startFormatter.dateStyle = .medium
            startFormatter.timeStyle = .short
            startFormatter.locale = Locale(identifier: "zh_CN")

            let endFormatter = DateFormatter()
            endFormatter.dateStyle = .medium
            endFormatter.timeStyle = .short
            endFormatter.locale = Locale(identifier: "zh_CN")

            return "\(startFormatter.string(from: event.startDate)) - \(endFormatter.string(from: event.endDate))"
        }
    }

    private func statusIndicator(for status: EventAttendee.AttendeeStatus) -> some View {
        let (color, text): (Color, String)

        switch status {
        case .accepted:
            color = .green
            text = "已接受"
        case .declined:
            color = .red
            text = "已拒绝"
        case .tentative:
            color = .orange
            text = "暂定"
        default:
            color = .gray
            text = "待处理"
        }

        return Text(text)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .cornerRadius(4)
            .foregroundColor(color)
    }
}

// MARK: - Preview
struct CalendarEventView_Previews: PreviewProvider {
    static var previews: some View {
        let sampleEvents = [
            CalendarEvent(
                title: "团队会议",
                startDate: Date(),
                endDate: Date().addingTimeInterval(3600),
                source: .eventKit
            ),
            CalendarEvent(
                title: "午餐约会",
                startDate: Date().addingTimeInterval(3600),
                endDate: Date().addingTimeInterval(7200),
                source: .user
            )
        ]

        CalendarEventView(
            events: sampleEvents,
            selectedDate: Date(),
            onEventTap: { _ in }
        )
        .frame(width: 400, height: 500)
        .padding()
    }
}