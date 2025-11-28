//
//  View+RTL.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import SwiftUI

// MARK: - RTL Layout Support

extension View {
    /// 应用本地化上下文的布局方向
    func applyLocalizationContext() -> some View {
        let context = LocalizationManager.shared.context
        let layoutDirection: LayoutDirection = context.isRTL ? .rightToLeft : .leftToRight

        return self
            .environment(\.layoutDirection, layoutDirection)
            .environment(\.locale, context.effectiveInterfaceLocale.locale)
    }

    /// 强制设置布局方向
    func layoutDirection(_ direction: LayoutDirection) -> some View {
        self.environment(\.layoutDirection, direction)
    }

    /// 根据 RTL 环境调整对齐方式
    func rtlAwareAlignment(_ leadingAlignment: Alignment = .leading,
                          _ trailingAlignment: Alignment = .trailing) -> some View {
        let isRTL = LocalizationManager.shared.context.isRTL
        let alignment = isRTL ? trailingAlignment : leadingAlignment

        return self.frame(maxWidth: .infinity, alignment: alignment)
    }
}

// MARK: - RTL-Aware Edge Insets

extension EdgeInsets {
    /// 创建 RTL 感知的边距
    static func rtlAware(
        top: CGFloat = 0,
        leading: CGFloat = 0,
        bottom: CGFloat = 0,
        trailing: CGFloat = 0
    ) -> EdgeInsets {
        let isRTL = LocalizationManager.shared.context.isRTL

        if isRTL {
            return EdgeInsets(
                top: top,
                leading: trailing,  // 交换
                bottom: bottom,
                trailing: leading   // 交换
            )
        } else {
            return EdgeInsets(
                top: top,
                leading: leading,
                bottom: bottom,
                trailing: trailing
            )
        }
    }
}

// MARK: - RTL-Aware HStack

/// RTL 感知的水平堆栈
struct RTLAwareHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content

    init(alignment: VerticalAlignment = .center,
         spacing: CGFloat? = nil,
         @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
        .environment(\.layoutDirection, layoutDirection)
    }

    private var layoutDirection: LayoutDirection {
        LocalizationManager.shared.context.isRTL ? .rightToLeft : .leftToRight
    }
}

// MARK: - Text Alignment Helper

extension TextAlignment {
    /// 获取 RTL 感知的文本对齐方式
    static var leadingRTLAware: TextAlignment {
        LocalizationManager.shared.context.isRTL ? .trailing : .leading
    }

    static var trailingRTLAware: TextAlignment {
        LocalizationManager.shared.context.isRTL ? .leading : .trailing
    }
}
