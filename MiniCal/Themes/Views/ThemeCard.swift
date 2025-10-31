//
//  ThemeCard.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI

struct ThemeCard: View {
    let theme: ThemeConfiguration
    let isSelected: Bool
    let themeManager: EnhancedThemeManager
    let onTap: () -> Void
    let onHover: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // 预览色块
            HStack(spacing: 4) {
                ForEach(Array(theme.previewColors.prefix(3).enumerated()), id: \.offset) { index, colorHex in
                    Rectangle()
                        .fill(Color(hex: colorHex))
                        .frame(height: 40)
                        .cornerRadius(4)
                }
            }
            .frame(height: 40)

            // 主题名称
            Text(theme.displayName)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(Color(themeManager.effectiveTheme.text.primary))
                .lineLimit(1)

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(backgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(borderColor, lineWidth: isSelected ? 3 : 1)
                )
        )
        .onTapGesture(perform: onTap)
        .onHover { hovering in
            if hovering {
                onHover()
            }
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private var backgroundColor: Color {
        if isSelected {
            return Color(themeManager.effectiveTheme.primary.main).opacity(0.1)
        } else {
            return Color(themeManager.effectiveTheme.surface.main)
        }
    }

    private var borderColor: Color {
        if isSelected {
            return Color(themeManager.effectiveTheme.primary.main)
        } else {
            return Color(themeManager.effectiveTheme.text.secondary).opacity(0.3)
        }
    }
}

// MARK: - Corner Radius Extension

extension View {
    func cornerRadius(_ radius: CGFloat) -> some View {
        clipShape(RoundedRectangle(cornerRadius: radius))
    }
}

// MARK: - Preview

struct ThemeCard_Previews: PreviewProvider {
    static var previews: some View {
        ThemeCard(
            theme: ThemeConfiguration.defaultLight,
            isSelected: false,
            themeManager: EnhancedThemeManager.shared,
            onTap: {},
            onHover: {}
        )
        .frame(width: 150, height: 120)
    }
}