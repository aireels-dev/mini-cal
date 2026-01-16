//
//  ScrollingText.swift
//  MiniCal
//
//  自动滚动文本组件 - 鼠标悬浮时滚动显示完整内容
//

import SwiftUI

struct ScrollingText: View {
    let text: String
    let font: Font
    let foregroundColor: Color
    let maxWidth: CGFloat?
    let autoScrollKey: AnyHashable?

    @State private var isHovered = false
    @State private var textWidth: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var autoScrollTask: Task<Void, Never>?
    @State private var hoverScrollTask: Task<Void, Never>?

    private let scrollSpeed: Double = 15.0  // 每秒滚动的像素数（降低速度）
    private let autoScrollDelay: TimeInterval = 0.4
    private let autoScrollPause: TimeInterval = 0.6
    private let hoverRepeatInterval: TimeInterval = 2.0
    private let scrollPadding: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            Text(text)
                .font(font)
                .foregroundColor(foregroundColor)
                .lineLimit(1)
                .fixedSize()
                .offset(x: scrollOffset)
                .background(
                    GeometryReader { textGeometry in
                        Color.clear
                            .onAppear {
                                updateTextWidth(textGeometry.size.width)
                                triggerAutoScrollIfNeeded()
                            }
                            .onChange(of: text) { _, _ in
                                updateTextWidth(textGeometry.size.width)
                                resetScroll()
                                triggerAutoScrollIfNeeded()
                            }
                            .onChange(of: textGeometry.size.width) { _, newValue in
                                updateTextWidth(newValue)
                                triggerAutoScrollIfNeeded()
                            }
                    }
                )
                .frame(
                    width: geometry.size.width,
                    alignment: needsScrolling(containerWidth: geometry.size.width) ? .leading : .center
                )
                .clipped()
                .contentShape(Rectangle())
                .onAppear {
                    containerWidth = geometry.size.width
                    triggerAutoScrollIfNeeded()
                }
                .onChange(of: geometry.size.width) { _, newValue in
                    containerWidth = newValue
                    triggerAutoScrollIfNeeded()
                }
                .onHover { hovering in
                    isHovered = hovering
                    if hovering {
                        startHoverScrolling(containerWidth: geometry.size.width)
                    } else {
                        stopScrolling()
                    }
                }
                .onChange(of: autoScrollKey) { _, _ in
                    guard !isHovered else { return }
                    scheduleAutoScroll(containerWidth: containerWidth)
                }
                .onDisappear {
                    cancelAllTasks()
                }
        }
        .frame(maxWidth: maxWidth)
    }

    private func needsScrolling(containerWidth: CGFloat) -> Bool {
        textWidth > containerWidth
    }

    private func updateTextWidth(_ newWidth: CGFloat) {
        textWidth = newWidth
        if containerWidth > 0, !needsScrolling(containerWidth: containerWidth) {
            resetScroll()
        }
    }

    private func startHoverScrolling(containerWidth: CGFloat) {
        guard needsScrolling(containerWidth: containerWidth) else { return }

        cancelAllTasks()
        hoverScrollTask = Task { @MainActor in
            await sleepSeconds(0.5)
            while !Task.isCancelled, isHovered {
                let scrollDistance = max(0, textWidth - containerWidth)
                let duration = scrollDistance / scrollSpeed

                withAnimation(.linear(duration: duration)) {
                    scrollOffset = -scrollDistance - scrollPadding
                }

                await sleepSeconds(duration + autoScrollPause)
                guard !Task.isCancelled, isHovered else { break }

                withAnimation(.linear(duration: duration)) {
                    scrollOffset = 0
                }

                await sleepSeconds(duration + hoverRepeatInterval)
            }
        }
    }

    private func scheduleAutoScroll(containerWidth: CGFloat) {
        guard containerWidth > 0, needsScrolling(containerWidth: containerWidth) else {
            resetScroll()
            return
        }
        cancelAutoScrollTask()
        scrollOffset = 0

        autoScrollTask = Task { @MainActor in
            await sleepSeconds(autoScrollDelay)
            guard !Task.isCancelled, !isHovered else { return }

            let scrollDistance = max(0, textWidth - containerWidth)
            let duration = scrollDistance / scrollSpeed

            withAnimation(.linear(duration: duration)) {
                scrollOffset = -scrollDistance - scrollPadding
            }

            await sleepSeconds(duration + autoScrollPause)
            guard !Task.isCancelled, !isHovered else { return }

            withAnimation(.linear(duration: duration)) {
                scrollOffset = 0
            }
        }
    }

    private func stopScrolling() {
        cancelHoverScrollTask()
        withAnimation(.easeOut(duration: 0.3)) {
            scrollOffset = 0
        }
    }

    private func resetScroll() {
        scrollOffset = 0
        cancelAllTasks()
    }

    private func triggerAutoScrollIfNeeded() {
        guard !isHovered, containerWidth > 0 else { return }
        scheduleAutoScroll(containerWidth: containerWidth)
    }

    private func cancelAutoScrollTask() {
        autoScrollTask?.cancel()
        autoScrollTask = nil
    }

    private func cancelHoverScrollTask() {
        hoverScrollTask?.cancel()
        hoverScrollTask = nil
    }

    private func cancelAllTasks() {
        cancelAutoScrollTask()
        cancelHoverScrollTask()
    }

    private func sleepSeconds(_ seconds: TimeInterval) async {
        let clamped = max(0, seconds)
        let nanoseconds = UInt64(clamped * 1_000_000_000)
        try? await Task.sleep(nanoseconds: nanoseconds)
    }
}

#Preview {
    VStack(spacing: 20) {
        // 短文本
        ScrollingText(
            text: "春节",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .orange,
            maxWidth: 60,
            autoScrollKey: nil
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))

        // 长文本需要滚动
        ScrollingText(
            text: "中华人民共和国国庆节",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .red,
            maxWidth: 60,
            autoScrollKey: nil
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))

        // 超长文本
        ScrollingText(
            text: "二十四节气之大寒节气",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .green,
            maxWidth: 60,
            autoScrollKey: nil
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))
    }
    .padding(20)
}
