//
//  CalendarGridView.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import SwiftUI

struct CalendarGridView: View {
    @ObservedObject var viewModel: CalendarViewModel
    let themeColors: ThemeColors
    let calendarSize: CalendarSize
    var onDateTap: ((CalendarDate) -> Void)?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
    @State private var eventMonitor: Any?
    @State private var scrollMonitor: Any?
    @State private var scrollDeltaX: CGFloat = 0
    @State private var scrollDeltaY: CGFloat = 0
    @State private var gestureAxis: GestureAxis?
    @State private var lastDeltaX: CGFloat = 0
    @State private var lastDeltaY: CGFloat = 0
    @State private var isNavigating = false
    
    var body: some View {
        calendarBody(dates: viewModel.calendarDates)
        .clipped()
        .padding(.horizontal, 12)
        .onAppear {
            setupKeyboardMonitor()
            setupScrollMonitor()
        }
        .onDisappear {
            removeKeyboardMonitor()
            removeScrollMonitor()
        }
              // 状态同步现在通过 ViewModel 的立即生效状态处理，无需额外监听
    }

    // MARK: - Keyboard Monitor Setup

    private func setupKeyboardMonitor() {
        // 移除旧监听器（如果存在）
        removeKeyboardMonitor()

        // 添加新的键盘事件监听器
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            return handleKeyPress(event)
        }
    }

    private func removeKeyboardMonitor() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    // MARK: - Scroll Monitor Setup (触摸板手势)

    private func setupScrollMonitor() {
        // 移除旧监听器（如果存在）
        removeScrollMonitor()

        // 监听滚动事件（触摸板手势）
        scrollMonitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            return handleScrollEvent(event)
        }
    }

    private func removeScrollMonitor() {
        if let monitor = scrollMonitor {
            NSEvent.removeMonitor(monitor)
            scrollMonitor = nil
        }
    }

    // MARK: - Event Handlers

    /// 键盘快捷键处理（彻底优化版）
    private func handleKeyPress(_ event: NSEvent) -> NSEvent? {
        // 检查窗口焦点：只在日历浮窗有焦点时响应
        guard isCalendarWindowActive() else {
            return event
        }

        // 检查当前是否有文本输入框获得焦点（避免拦截设置窗口的输入）
        if NSApp.keyWindow?.firstResponder as? NSTextView != nil {
            return event
        }

        // 左箭头 = 上一个月（月份减小）
        if event.keyCode == 123 { // Left arrow
            viewModel.goToPreviousMonth()
            return nil
        }
        // 右箭头 = 下一个月（月份增大）
        else if event.keyCode == 124 { // Right arrow
            viewModel.goToNextMonth()
            return nil
        }
        // 上箭头 = 下一年（年份增大）
        else if event.keyCode == 126 { // Up arrow
            viewModel.goToNextYear()
            return nil
        }
        // 下箭头 = 上一年（年份减小）
        else if event.keyCode == 125 { // Down arrow
            viewModel.goToPreviousYear()
            return nil
        }
        // W键 = 下一年（年份增大）
        else if event.keyCode == 13 { // W key
            viewModel.goToNextYear()
            return nil
        }
        // A键 = 上一个月（月份减小）
        else if event.keyCode == 0 { // A key
            viewModel.goToPreviousMonth()
            return nil
        }
        // S键 = 上一年（年份减小）
        else if event.keyCode == 1 { // S key
            viewModel.goToPreviousYear()
            return nil
        }
        // D键 = 下一个月（月份增大）
        else if event.keyCode == 2 { // D key
            viewModel.goToNextMonth()
            return nil
        }
        return event
    }

    /// 滚动事件处理（触摸板手势，彻底优化版）
    private func handleScrollEvent(_ event: NSEvent) -> NSEvent? {
        // 检查窗口焦点：只在日历浮窗有焦点时响应
        guard isCalendarWindowActive() else {
            return event
        }

        // 仅当指针在浮窗范围内时响应（避免设置窗口滚动触发）
        guard isPointerInsidePopover() else {
            return event
        }

        // 检查是否是触摸板手势（不是鼠标滚轮）
        guard event.hasPreciseScrollingDeltas else {
            return event
        }
        if isNavigating {
            return nil
        }

        if event.phase == .began {
            scrollDeltaX = 0
            scrollDeltaY = 0
            lastDeltaX = 0
            lastDeltaY = 0
            gestureAxis = nil
        }

        if event.phase == .began || event.phase == .changed {
            scrollDeltaX += event.scrollingDeltaX
            scrollDeltaY += event.scrollingDeltaY
            lastDeltaX = event.scrollingDeltaX
            lastDeltaY = event.scrollingDeltaY

            if gestureAxis == nil {
                let axisLockThreshold: CGFloat = 4
                if abs(scrollDeltaX) > abs(scrollDeltaY), abs(scrollDeltaX) > axisLockThreshold {
                    gestureAxis = .horizontal
                } else if abs(scrollDeltaY) > abs(scrollDeltaX), abs(scrollDeltaY) > axisLockThreshold {
                    gestureAxis = .vertical
                }
            }

            let threshold = calendarSize.gridSize * 0.25
            let fastThreshold: CGFloat = 60

            if gestureAxis == .horizontal {
                if abs(scrollDeltaX) > threshold || abs(lastDeltaX) > fastThreshold {
                    let sign: CGFloat = scrollDeltaX < 0 ? -1 : 1
                    triggerNavigation(axis: .horizontal, sign: sign)
                }
                return nil
            } else if gestureAxis == .vertical {
                if abs(scrollDeltaY) > threshold || abs(lastDeltaY) > fastThreshold {
                    let sign: CGFloat = scrollDeltaY < 0 ? -1 : 1
                    triggerNavigation(axis: .vertical, sign: sign)
                }
                return nil
            }
        }

        let isGestureEnding = event.phase == .cancelled
            || (event.phase == .ended && event.momentumPhase == [])
            || event.momentumPhase == .ended
        if isGestureEnding {
            resetGestureState()
            return nil
        }

        return event
    }

    // MARK: - Window Focus Check

    /// 检查日历窗口是否处于活动状态
    private func isCalendarWindowActive() -> Bool {
        guard let keyWindow = NSApp.keyWindow else { return false }
        // 检查是否是 NSPopover 的窗口（日历浮窗）
        return keyWindow.className.contains("NSPopover")
    }

    /// 检查指针是否在日历浮窗范围内
    private func isPointerInsidePopover() -> Bool {
        guard let popoverWindow = NSApp.windows.first(where: { $0.className.contains("NSPopover") && $0.isVisible }) else {
            return false
        }
        let mouseLocation = NSEvent.mouseLocation
        return popoverWindow.frame.contains(mouseLocation)
    }

    // MARK: - Gesture Navigation

    private func resetGestureState() {
        scrollDeltaX = 0
        scrollDeltaY = 0
        lastDeltaX = 0
        lastDeltaY = 0
        gestureAxis = nil
        isNavigating = false
    }

    private func triggerNavigation(axis: GestureAxis, sign: CGFloat) {
        isNavigating = true
        let monthOffset = axis == .horizontal ? (sign < 0 ? 1 : -1) : 0
        let yearOffset = axis == .vertical ? (sign < 0 ? -1 : 1) : 0
        let targetDate = viewModel.previewDate(monthOffset: monthOffset, yearOffset: yearOffset)
        viewModel.applyGestureNavigation(to: targetDate, previewDates: nil)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.resetGestureState()
        }
    }



    private func format(_ size: CGSize) -> String {
        String(format: "{%.1f, %.1f}", size.width, size.height)
    }

    // MARK: - Week Header

    @ViewBuilder
    private func calendarBody(dates: [CalendarDate]) -> some View {
        VStack(spacing: 0) {
            // 星期标题行
            weekdayHeaderRow
                .padding(.bottom, 8)

            // 日期网格（带优化转场动画）
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(dates) { date in
                    CalendarDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        themeColors: themeColors,
                        calendarSize: calendarSize,
                        onTap: {
                            viewModel.selectDate(date)
                            // 所有日期均可点击，显示事件详情（即使没有事件）
                            onDateTap?(date)
                        }
                    )
                    .frame(height: calendarSize.cellSize)
                }
            }
        }
    }

    private var weekdayHeaderRow: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(viewModel.weekdayHeaders(), id: \.self) { weekday in
                Text(weekday)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(themeColors.secondaryTextColor.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
        }
    }
}

// MARK: - 平滑动效修饰器（解决频闪问题）

struct SmoothSlideModifier: ViewModifier {
    let offsetX: CGFloat      // X轴偏移
    let offsetY: CGFloat      // Y轴偏移
    let scale: CGFloat        // 缩放比例
    let opacity: Double       // 透明度

    func body(content: Content) -> some View {
        content
            .scaleEffect(scale)
            .offset(x: offsetX, y: offsetY)
            .opacity(opacity)
    }
}

private enum GestureAxis {
    case horizontal
    case vertical
}

#Preview {
    CalendarGridView(
        viewModel: CalendarViewModel(),
        themeColors: .light,
        calendarSize: .standard
    )
    .frame(width: 300, height: 300)
    .background(ThemeColors.light.backgroundColor)
}
