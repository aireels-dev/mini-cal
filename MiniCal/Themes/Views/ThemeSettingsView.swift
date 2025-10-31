//
//  ThemeSettingsView.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import SwiftUI

struct ThemeSettingsView: View {
    @ObservedObject private var themeManager = EnhancedThemeManager.shared
    @State private var selectedMode: ThemeMode
    @State private var previewState = ThemePreviewState()

    init() {
        self._selectedMode = State(initialValue: EnhancedThemeManager.shared.currentMode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                themeModeSection
                themeSelectionSection
                advancedOptionsSection
            }
            .padding()
        }
        .background(Color(hex: themeManager.effectiveTheme.background.main))
        .navigationTitle("主题设置")
        .onAppear {
            selectedMode = themeManager.currentMode
        }
        .onDisappear {
            if previewState.isPreviewing {
                themeManager.stopPreview()
            }
        }
    }

    private var themeModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("主题模式")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.text.primary))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    ThemeModeRow(
                        mode: mode,
                        isSelected: selectedMode == mode,
                        theme: themeManager.effectiveTheme,
                        onTap: {
                            selectedMode = mode
                            themeManager.switchToMode(mode)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var themeSelectionSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("选择主题")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.text.primary))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                ForEach(themesForCurrentMode) { theme in
                    ThemeCard(
                        theme: theme,
                        isSelected: currentThemeForMode?.id == theme.id,
                        themeManager: themeManager,
                        onTap: {
                            handleThemeSelection(theme)
                        },
                        onHover: {
                            handleThemePreview(theme)
                        }
                    )
                }
            }
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var advancedOptionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("高级选项")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color(hex: themeManager.effectiveTheme.text.primary))

            VStack(alignment: .leading, spacing: 12) {
                Toggle("实时预览", isOn: .constant(true))

                Toggle("平滑过渡", isOn: .constant(true))
            }
            .foregroundColor(Color(hex: themeManager.effectiveTheme.text.primary))
        }
        .padding()
        .background(Color(hex: themeManager.effectiveTheme.surface.main))
        .cornerRadius(12)
    }

    private var themesForCurrentMode: [ThemeConfiguration] {
        switch selectedMode {
        case .light:
            return themeManager.themes(for: .light)
        case .dark:
            return themeManager.themes(for: .dark)
        case .auto:
            return themeManager.themes(for: .light) + themeManager.themes(for: .dark)
        }
    }

    private var currentThemeForMode: ThemeConfiguration? {
        switch selectedMode {
        case .light:
            return themeManager.lightTheme
        case .dark:
            return themeManager.darkTheme
        case .auto:
            return themeManager.effectiveTheme
        }
    }

    private func handleThemeSelection(_ theme: ThemeConfiguration) {
        switch selectedMode {
        case .light:
            themeManager.setTheme(theme, for: .light)
        case .dark:
            themeManager.setTheme(theme, for: .dark)
        case .auto:
            if theme.category == .light {
                themeManager.setTheme(theme, for: .light)
            } else {
                themeManager.setTheme(theme, for: .dark)
            }
        }

        previewState.stopPreview()
    }

    private func handleThemePreview(_ theme: ThemeConfiguration) {
        themeManager.startPreview(theme: theme)
        previewState.startPreview(themeId: theme.id, originalThemeId: currentThemeForMode?.id ?? "")
    }
}

struct ThemeModeRow: View {
    let mode: ThemeMode
    let isSelected: Bool
    let theme: ThemeConfiguration
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Text(mode.displayName)
                    .font(.body)
                    .foregroundColor(Color(hex: theme.text.primary))

                Spacer()

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(Color(hex: theme.primary.main))
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(Color(hex: theme.text.secondary))
                }
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

struct ThemeSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        ThemeSettingsView()
    }
}