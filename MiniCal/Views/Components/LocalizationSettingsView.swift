//
//  LocalizationSettingsView.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import SwiftUI

/// 本地化设置视图
struct LocalizationSettingsView: View {
    @ObservedObject private var localizationManager = LocalizationManager.shared

    @State private var selectedInterfaceLocale: SupportedLocale?
    @State private var selectedCalendarLocale: SupportedLocale?
    @State private var useIndependentCalendarLocale: Bool = false

    init() {
        let context = LocalizationManager.shared.context
        _selectedInterfaceLocale = State(initialValue: context.interfaceLocale)
        _selectedCalendarLocale = State(initialValue: context.calendarLocale)
        _useIndependentCalendarLocale = State(initialValue: context.calendarLocale != nil)
    }

    var body: some View {
        Form {
            Section(header: Text("Interface Language")) {
                Picker("Interface Language", selection: $selectedInterfaceLocale) {
                    // 自动选项（nil 值）
                    Text("settings.language.auto").tag(nil as SupportedLocale?)

                    Divider()

                    // 手动选择的语言
                    ForEach(SupportedLocale.allCases, id: \.self) { locale in
                        Text(locale.displayName).tag(locale as SupportedLocale?)
                    }
                }
                .onChange(of: selectedInterfaceLocale) { _, newValue in
                    updateLocalization()
                }

                // 显示当前实际使用的语言（仅在自动模式下）
                if selectedInterfaceLocale == nil {
                    HStack {
                        Text("settings.language.current")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(localizationManager.context.effectiveInterfaceLocale.displayName)
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }

                Text("The language used for menus, settings, and UI elements")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section(header: Text("Calendar Language")) {
                Toggle("Use separate language for calendar", isOn: $useIndependentCalendarLocale)
                    .onChange(of: useIndependentCalendarLocale) { _, newValue in
                        if !newValue {
                            selectedCalendarLocale = nil
                        } else {
                            selectedCalendarLocale = localizationManager.context.effectiveInterfaceLocale
                        }
                        updateLocalization()
                    }

                if useIndependentCalendarLocale {
                    Picker("Calendar Language", selection: Binding(
                        get: { selectedCalendarLocale ?? localizationManager.context.effectiveInterfaceLocale },
                        set: { selectedCalendarLocale = $0 }
                    )) {
                        ForEach(SupportedLocale.allCases, id: \.self) { locale in
                            Text(locale.displayName).tag(locale)
                        }
                    }
                    .onChange(of: selectedCalendarLocale) { _, _ in
                        updateLocalization()
                    }

                    Text("The language used for calendar names, festivals, and dates")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundColor(.blue)
                        Text("Language Support")
                            .font(.headline)
                    }

                    Text("Full support: English, Simplified Chinese, Traditional Chinese, Arabic, Hebrew")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("Partial support: Japanese, Korean, Vietnamese, Persian, Thai, Turkish")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Divider()

                    Text("RTL Support")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Text("Arabic, Hebrew, Persian, and Urdu automatically use right-to-left layout")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 4)
            }

            Section {
                Button("Reset to System Language") {
                    selectedInterfaceLocale = nil  // 自动模式
                    selectedCalendarLocale = nil
                    useIndependentCalendarLocale = false
                    updateLocalization()
                }
            }
        }
        .formStyle(.grouped)
    }

    private func updateLocalization() {
        let newContext = LocalizationContext(
            interfaceLocale: selectedInterfaceLocale,
            calendarLocale: useIndependentCalendarLocale ? selectedCalendarLocale : nil
        )
        localizationManager.updateContext(newContext)

        // 通知需要重新加载
        NotificationCenter.default.post(name: .localizationDidChange, object: nil)
    }
}

// MARK: - Notification

extension Notification.Name {
    static let localizationDidChange = Notification.Name("localizationDidChange")
}

#Preview {
    LocalizationSettingsView()
        .frame(width: 500, height: 600)
}
