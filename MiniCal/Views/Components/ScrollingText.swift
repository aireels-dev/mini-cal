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

    @State private var isHovered = false
    @State private var textWidth: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @State private var animationTimer: Timer?

    private let scrollSpeed: Double = 15.0  // 每秒滚动的像素数（降低速度）

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
                                textWidth = textGeometry.size.width
                            }
                            .onChange(of: text) { oldValue, newValue in
                                textWidth = textGeometry.size.width
                                resetScroll()
                            }
                    }
                )
                .frame(width: geometry.size.width, alignment: .center)
                .clipped()
                .onHover { hovering in
                    isHovered = hovering
                    if hovering {
                        startScrolling(containerWidth: geometry.size.width)
                    } else {
                        stopScrolling()
                    }
                }
        }
        .frame(maxWidth: maxWidth)
    }

    private var needsScrolling: Bool {
        return textWidth > (maxWidth ?? 0)
    }

    private func startScrolling(containerWidth: CGFloat) {
        guard needsScrolling else { return }

        // 计算需要滚动的距离
        let scrollDistance = textWidth - containerWidth

        // 计算滚动时间（基于距离和速度）
        let duration = scrollDistance / scrollSpeed

        // 延迟500ms后开始滚动
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            guard self.isHovered else { return }

            // 向左滚动
            withAnimation(.linear(duration: duration)) {
                scrollOffset = -scrollDistance - 8  // 多滚动8pt留白
            }

            // 滚动完成后，延迟1秒回到起点
            DispatchQueue.main.asyncAfter(deadline: .now() + duration + 1.0) {
                guard self.isHovered else { return }

                withAnimation(.linear(duration: duration)) {
                    scrollOffset = 0
                }

                // 循环滚动
                DispatchQueue.main.asyncAfter(deadline: .now() + duration + 0.5) {
                    if self.isHovered {
                        startScrolling(containerWidth: containerWidth)
                    }
                }
            }
        }
    }

    private func stopScrolling() {
        withAnimation(.easeOut(duration: 0.3)) {
            scrollOffset = 0
        }
    }

    private func resetScroll() {
        scrollOffset = 0
        animationTimer?.invalidate()
        animationTimer = nil
    }
}

#Preview {
    VStack(spacing: 20) {
        // 短文本
        ScrollingText(
            text: "春节",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .orange,
            maxWidth: 60
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))

        // 长文本需要滚动
        ScrollingText(
            text: "中华人民共和国国庆节",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .red,
            maxWidth: 60
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))

        // 超长文本
        ScrollingText(
            text: "二十四节气之大寒节气",
            font: .system(size: 12, weight: .medium),
            foregroundColor: .green,
            maxWidth: 60
        )
        .frame(height: 20)
        .border(Color.gray.opacity(0.3))
    }
    .padding(20)
}
