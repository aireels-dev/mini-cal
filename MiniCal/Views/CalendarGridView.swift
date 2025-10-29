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

            // 日期网格（带转场动画）
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

    /// 键盘快捷键处理
    private func handleKeyPress(_ event: NSEvent) -> NSEvent? {
        // 左箭头 = 上一个月
        if event.keyCode == 123 { // Left arrow
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.goToPreviousMonth()
            }
            return nil
        }
        // 右箭头 = 下一个月
        else if event.keyCode == 124 { // Right arrow
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.goToNextMonth()
            }
            return nil
        }
        // 上箭头 = 上一年
        else if event.keyCode == 126 { // Up arrow
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.goToPreviousYear()
            }
            return nil
        }
        // 下箭头 = 下一年
        else if event.keyCode == 125 { // Down arrow
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                viewModel.goToNextYear()
            }
            return nil
        }
        return event
    }

    /// 滚动事件处理（触摸板手势）
    private func handleScrollEvent(_ event: NSEvent) -> NSEvent? {
        // 🔍 调试日志：输出所有滚动事件
        print("📱 [手势调试] 收到滚动事件")
        print("  hasPreciseScrollingDeltas: \(event.hasPreciseScrollingDeltas)")
        print("  phase: \(event.phase.rawValue) (0=none, 1=began, 2=changed, 3=ended, 4=cancelled, 5=mayBegin)")
        print("  momentumPhase: \(event.momentumPhase.rawValue)")
        print("  scrollingDeltaX: \(event.scrollingDeltaX)")
        print("  scrollingDeltaY: \(event.scrollingDeltaY)")

        // 检查是否是触摸板手势（不是鼠标滚轮）
        guard event.hasPreciseScrollingDeltas else {
            print("  ❌ 不是触摸板手势（鼠标滚轮），跳过")
            return event
        }

        // 累积滚动量
        if event.phase == .began || event.phase == .changed {
            scrollDeltaX += event.scrollingDeltaX
            scrollDeltaY += event.scrollingDeltaY
            print("  📊 累积中 - X: \(scrollDeltaX), Y: \(scrollDeltaY)")
            return event
        }

        // 手势结束，判断方向
        if event.phase == .ended {
            let threshold: CGFloat = 30.0  // 提高阈值避免误触

            print("  ✅ 手势结束 - 累积值 X: \(scrollDeltaX), Y: \(scrollDeltaY)")

            // 水平滑动（月份切换）
            if abs(scrollDeltaX) > abs(scrollDeltaY) && abs(scrollDeltaX) > threshold {
                print("  ➡️ 触发月份切换: \(scrollDeltaX > 0 ? "上一月" : "下一月")")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if scrollDeltaX > 0 {
                        // 向右滑动 = 上一个月
                        viewModel.goToPreviousMonth()
                    } else {
                        // 向左滑动 = 下一个月
                        viewModel.goToNextMonth()
                    }
                }
            }
            // 垂直滑动（年份切换）
            else if abs(scrollDeltaY) > abs(scrollDeltaX) && abs(scrollDeltaY) > threshold {
                print("  ⬆️ 触发年份切换: \(scrollDeltaY > 0 ? "上一年" : "下一年")")
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    if scrollDeltaY > 0 {
                        // 向下滑动 = 上一年
                        viewModel.goToPreviousYear()
                    } else {
                        // 向上滑动 = 下一年
                        viewModel.goToNextYear()
                    }
                }
            } else {
                print("  ⚠️ 未达到阈值（threshold: \(threshold)）")
            }

            // 重置累积值
            scrollDeltaX = 0
            scrollDeltaY = 0
            return nil
        }

        return event
    }

    /// 月份切换转场动画（差速移动，增强层次感）
    private var monthTransition: AnyTransition {
        switch viewModel.navigationDirection {
        case .forward:
            // 前进：新月份从右侧慢速滑入，旧月份向左侧快速滑出
            return .asymmetric(
                insertion: .modifier(
                    active: SlideModifier(offset: 1.2, opacity: 0),  // 新月份：远距离进入
                    identity: SlideModifier(offset: 0, opacity: 1)
                ),
                removal: .modifier(
                    active: SlideModifier(offset: -0.8, opacity: 0),  // 旧月份：近距离退出
                    identity: SlideModifier(offset: 0, opacity: 1)
                )
            )
        case .backward:
            // 后退：新月份从左侧慢速滑入，旧月份向右侧快速滑出
            return .asymmetric(
                insertion: .modifier(
                    active: SlideModifier(offset: -1.2, opacity: 0),  // 新月份：远距离进入
                    identity: SlideModifier(offset: 0, opacity: 1)
                ),
                removal: .modifier(
                    active: SlideModifier(offset: 0.8, opacity: 0),   // 旧月份：近距离退出
                    identity: SlideModifier(offset: 0, opacity: 1)
                )
            )
        case .none:
            // 无方向（如跳转到今天）：快速淡入淡出
            return .opacity
        }
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

// MARK: - 自定义滑动修饰器（支持差速动画）

struct SlideModifier: ViewModifier {
    let offset: CGFloat  // 偏移倍数（相对于屏幕宽度）
    let opacity: Double

    func body(content: Content) -> some View {
        content
            .offset(x: offset * (NSScreen.main?.frame.width ?? 400))
            .opacity(opacity)
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
