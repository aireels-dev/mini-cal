//
//  ThemeManager.swift
//  MiniCal
//
//  Created on 2025/10/28.
//

import SwiftUI
import Combine

/// 主题管理器，负责加载、应用和切换主题
class ThemeManager: ObservableObject {

    // MARK: - Singleton

    static let shared = ThemeManager()

    // MARK: - Published Properties

    @Published private(set) var currentTheme: Theme
    @Published private(set) var availableThemes: [Theme] = []

    // MARK: - Private Properties

    private var appearanceObserver: NSKeyValueObservation?
    private let settingsManager = SettingsManager.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Initialization

    private init() {
        // 加载主题数据
        let themes = ThemeManager.loadThemes()
        self.availableThemes = themes

        // 根据设置获取初始主题
        let themeId = settingsManager.currentSettings.themeId
        let initialTheme = themes.first { $0.id == themeId } ?? themes.first { $0.id == "system" } ?? Theme(
            id: "system",
            name: "跟随系统",
            colors: ThemeColors(
                background: "#FFFFFF",
                text: "#000000",
                secondaryText: "#666666",
                border: "#E0E0E0",
                todayHighlight: "#007AFF",
                weekendText: "#FF3B30",
                selectedDate: "#007AFF"
            ),
            isSystemTheme: true
        )
        self.currentTheme = initialTheme

        // 监听设置变化
        settingsManager.$currentSettings
            .map { $0.themeId }
            .removeDuplicates()
            .sink { [weak self] newThemeId in
                self?.applyTheme(withId: newThemeId)
            }
            .store(in: &cancellables)
    }

    // MARK: - Public Methods

    /// 应用指定ID的主题
    func applyTheme(withId id: String) {
        Logger.measureTime(operation: "Apply theme '\(id)'", category: Logger.performance) {
            guard let theme = self.theme(withId: id) else {
                Logger.warning("Theme with id '\(id)' not found, using default", category: Logger.theme)
                self.currentTheme = defaultTheme()
                return
            }

            self.currentTheme = theme

            // 如果是"跟随系统"主题，开始监听系统外观变化
            if id == "system" {
                startObservingSystemAppearance()
            } else {
                stopObservingSystemAppearance()
            }

            Logger.info("Applied theme: \(theme.name)", category: Logger.theme)
        }
    }

    /// 根据ID查找主题
    func theme(withId id: String) -> Theme? {
        return availableThemes.first { $0.id == id }
    }

    /// 获取当前有效的主题颜色（处理系统跟随）
    func effectiveColors() -> ThemeColors {
        if currentTheme.id == "system" {
            // 检测当前系统外观
            let isDarkMode = NSApp.effectiveAppearance.name == .darkAqua
            let effectiveTheme = theme(withId: isDarkMode ? "dark" : "light") ?? defaultTheme()
            return effectiveTheme.colors
        }
        return currentTheme.colors
    }

    /// 开始监听系统外观变化
    func startObservingSystemAppearance() {
        guard appearanceObserver == nil else { return }

        appearanceObserver = NSApp.observe(\.effectiveAppearance, options: [.new]) { [weak self] _, _ in
            // 系统外观变化时，触发UI更新
            DispatchQueue.main.async {
                self?.objectWillChange.send()
            }
        }

        Logger.debug("Started observing system appearance", category: Logger.theme)
    }

    /// 停止监听系统外观变化
    func stopObservingSystemAppearance() {
        appearanceObserver?.invalidate()
        appearanceObserver = nil
        Logger.debug("Stopped observing system appearance", category: Logger.theme)
    }

    // MARK: - Private Methods

    /// 加载主题配置文件
    private static func loadThemes() -> [Theme] {
        guard let url = Bundle.main.url(forResource: "themes", withExtension: "json", subdirectory: "Resources/Themes") else {
            Logger.warning("themes.json not found, using default themes", category: Logger.theme)
            return defaultThemes()
        }

        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let themes = try decoder.decode([Theme].self, from: data)
            Logger.info("Loaded \(themes.count) themes from themes.json", category: Logger.theme)
            return themes
        } catch {
            Logger.error("Failed to load themes.json", error: error, category: Logger.theme)
            return defaultThemes()
        }
    }

    /// 默认主题列表（当加载失败时使用）
    private static func defaultThemes() -> [Theme] {
        return [
            Theme(
                id: "system",
                name: "跟随系统",
                colors: ThemeColors(
                    background: "#FFFFFF",
                    text: "#000000",
                    secondaryText: "#666666",
                    border: "#E0E0E0",
                    todayHighlight: "#007AFF",
                    weekendText: "#FF3B30",
                    selectedDate: "#007AFF"
                ),
                isSystemTheme: true
            ),
            Theme(
                id: "light",
                name: "浅色",
                colors: ThemeColors(
                    background: "#FFFFFF",
                    text: "#000000",
                    secondaryText: "#666666",
                    border: "#E0E0E0",
                    todayHighlight: "#007AFF",
                    weekendText: "#FF3B30",
                    selectedDate: "#007AFF"
                ),
                isSystemTheme: false
            ),
            Theme(
                id: "dark",
                name: "深色",
                colors: ThemeColors(
                    background: "#1C1C1E",
                    text: "#FFFFFF",
                    secondaryText: "#EBEBF5",
                    border: "#38383A",
                    todayHighlight: "#0A84FF",
                    weekendText: "#FF453A",
                    selectedDate: "#0A84FF"
                ),
                isSystemTheme: false
            )
        ]
    }

    /// 获取默认主题
    private func defaultTheme() -> Theme {
        return availableThemes.first { $0.id == "system" } ?? Theme(
            id: "system",
            name: "跟随系统",
            colors: ThemeColors(
                background: "#FFFFFF",
                text: "#000000",
                secondaryText: "#666666",
                border: "#E0E0E0",
                todayHighlight: "#007AFF",
                weekendText: "#FF3B30",
                selectedDate: "#007AFF"
            ),
            isSystemTheme: true
        )
    }

    // MARK: - Deinit

    deinit {
        stopObservingSystemAppearance()
    }
}
