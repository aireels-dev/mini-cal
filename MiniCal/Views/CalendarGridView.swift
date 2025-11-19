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
    
    var body: some View {
        VStack(spacing: 0) {
            // 星期标题行
            weekdayHeaderRow
                .padding(.bottom, 8)

            // 日期网格（带优化转场动画）
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(viewModel.calendarDates) { date in
                    CalendarDayCell(
                        date: date,
                        isSelected: viewModel.isSelected(date),
                        themeColors: themeColors,
                        calendarSize: calendarSize,
                        onTap: {
                            viewModel.selectDate(date)
                            if !date.events.isEmpty {
                                onDateTap?(date)
                            }
                        }
                    )
                    .frame(height: calendarSize.cellSize)
                }
            }
            .id(viewModel.currentMonth) // 关键：用于触发转场
            .transition(monthTransition)
            .animation(.easeInOut(duration: 0.35), value: viewModel.currentMonth)
        }
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

        let animation = Animation.easeInOut(duration: 0.35)

        // 左箭头 = 上一个月（月份减小）
        if event.keyCode == 123 { // Left arrow
            withAnimation(animation) {
                viewModel.goToPreviousMonth()
            }
            return nil
        }
        // 右箭头 = 下一个月（月份增大）
        else if event.keyCode == 124 { // Right arrow
            withAnimation(animation) {
                viewModel.goToNextMonth()
            }
            return nil
        }
        // 上箭头 = 上一年（年份减小）
        else if event.keyCode == 126 { // Up arrow
            withAnimation(animation) {
                viewModel.goToPreviousYear()
            }
            return nil
        }
        // 下箭头 = 下一年（年份增大）
        else if event.keyCode == 125 { // Down arrow
            withAnimation(animation) {
                viewModel.goToNextYear()
            }
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

        // 检查是否是触摸板手势（不是鼠标滚轮）
        guard event.hasPreciseScrollingDeltas else {
            return event
        }

        // 累积滚动量
        if event.phase == .began || event.phase == .changed {
            scrollDeltaX += event.scrollingDeltaX
            scrollDeltaY += event.scrollingDeltaY
            return event
        }

        // 手势结束，判断方向
        if event.phase == .ended {
            let threshold: CGFloat = 25.0  // 优化阈值
            let animation = Animation.easeInOut(duration: 0.35)

            // 水平滑动（月份切换）
            if abs(scrollDeltaX) > abs(scrollDeltaY) && abs(scrollDeltaX) > threshold {
                withAnimation(animation) {
                    if scrollDeltaX < 0 {
                        viewModel.goToPreviousMonth()
                    } else {
                        viewModel.goToNextMonth()
                    }
                }
            }
            // 垂直滑动（年份切换）
            else if abs(scrollDeltaY) > abs(scrollDeltaX) && abs(scrollDeltaY) > threshold {
                withAnimation(animation) {
                    if scrollDeltaY < 0 {
                        viewModel.goToPreviousYear()
                    } else {
                        viewModel.goToNextYear()
                    }
                }
            }

            // 重置累积值
            scrollDeltaX = 0
            scrollDeltaY = 0
            return nil
        }

        return event
    }

    /// 日历切换转场动画（彻底解决延迟问题）
    private var monthTransition: AnyTransition {
        // 优先使用立即生效的导航状态，完全解决延迟问题
        let effectiveType = viewModel.currentNavigationType != .none ?
                           viewModel.currentNavigationType :
                           viewModel.navigationType
        let effectiveDirection = viewModel.currentNavigationDirection != .none ?
                               viewModel.currentNavigationDirection :
                               viewModel.navigationDirection

        let isHorizontal = effectiveType == .month

        // 动画参数 - 更平滑的设置
        let slideDistance: CGFloat = 280  // 减小滑动距离
        let fadeThreshold: Double = 0.3    // 透明度阈值，避免突然消失

        switch effectiveDirection {
        case .forward:
            // 前进动画：月份增大（从左向右）或年份增大（下一年）
            return .asymmetric(
                insertion: .modifier(
                    active: SmoothSlideModifier(
                        offsetX: isHorizontal ? -slideDistance : 0,
                        offsetY: isHorizontal ? 0 : -slideDistance,  // 下一年：新内容从上方进入
                        scale: 0.95,
                        opacity: fadeThreshold
                    ),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                ),
                removal: .modifier(
                    active: SmoothSlideModifier(
                        offsetX: isHorizontal ? slideDistance : 0,
                        offsetY: isHorizontal ? 0 : slideDistance,  // 下一年：旧内容向下退出
                        scale: 0.95,
                        opacity: fadeThreshold
                    ),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                )
            )
        case .backward:
            // 后退动画：月份减小（从右向左）或年份减小（上一年）
            return .asymmetric(
                insertion: .modifier(
                    active: SmoothSlideModifier(
                        offsetX: isHorizontal ? slideDistance : 0,
                        offsetY: isHorizontal ? 0 : slideDistance,   // 上一年：新内容从下方进入
                        scale: 0.95,
                        opacity: fadeThreshold
                    ),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                ),
                removal: .modifier(
                    active: SmoothSlideModifier(
                        offsetX: isHorizontal ? -slideDistance : 0,
                        offsetY: isHorizontal ? 0 : -slideDistance,  // 上一年：旧内容向上退出
                        scale: 0.95,
                        opacity: fadeThreshold
                    ),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                )
            )
        case .none:
            // 无方向动画：简单的缩放淡入
            return .asymmetric(
                insertion: .modifier(
                    active: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 0.9, opacity: 0.0),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                ),
                removal: .modifier(
                    active: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.1, opacity: 0.0),
                    identity: SmoothSlideModifier(offsetX: 0, offsetY: 0, scale: 1.0, opacity: 1.0)
                )
            )
        }
    }

    // MARK: - Window Focus Check

    /// 检查日历窗口是否处于活动状态
    private func isCalendarWindowActive() -> Bool {
        guard let keyWindow = NSApp.keyWindow else { return false }
        // 检查是否是 NSPopover 的窗口（日历浮窗）
        return keyWindow.className.contains("NSPopover")
    }

    // MARK: - Week Header

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
            .animation(.easeInOut(duration: 0.35), value: offsetX)
            .animation(.easeInOut(duration: 0.35), value: offsetY)
            .animation(.easeInOut(duration: 0.25), value: scale)
            .animation(.easeInOut(duration: 0.2), value: opacity)
    }
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
