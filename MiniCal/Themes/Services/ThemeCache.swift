//
//  ThemeCache.swift
//  MiniCal
//
//  Created by Enhanced Theme System on 2025-10-30.
//

import Foundation
import SwiftUI
import Combine

// MARK: - Theme Cache Protocol

protocol ThemeCacheProtocol {
    func theme(for id: String) -> ThemeConfiguration?
    func cacheTheme(_ theme: ThemeConfiguration)
    func allThemes() -> [ThemeConfiguration]
    func themes(for category: ThemeCategory) -> [ThemeConfiguration]
    func clearCache()
    func removeTheme(with id: String)
}

// MARK: - Theme Cache Implementation

/// 主题缓存管理器
class ThemeCache: ThemeCacheProtocol, ObservableObject {
    static let shared = ThemeCache()

    private var themes: [String: ThemeConfiguration] = [:]
    private let fileManager = FileManager.default
    private let cacheQueue = DispatchQueue(label: "com.minical.theme.cache", qos: .utility)
    private let maxCacheSize = 50

    // MARK: - Initialization

    private init() {
        setupMemoryPressureObserver()
        loadBuiltinThemes()
        loadCustomThemes()
    }

    // MARK: - Cache Operations

    /// 获取主题
    func theme(for id: String) -> ThemeConfiguration? {
        return cacheQueue.sync {
            return themes[id]
        }
    }

    /// 缓存主题
    func cacheTheme(_ theme: ThemeConfiguration) {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            // 检查缓存大小限制
            if self.themes.count >= self.maxCacheSize {
                self.performLRUEviction()
            }

            self.themes[theme.id] = theme
        }
    }

    /// 获取所有主题
    func allThemes() -> [ThemeConfiguration] {
        return cacheQueue.sync {
            return Array(themes.values)
        }
    }

    /// 按分类获取主题
    func themes(for category: ThemeCategory) -> [ThemeConfiguration] {
        return cacheQueue.sync {
            return themes.values.filter { $0.category == category }
        }
    }

    /// 清空缓存
    func clearCache() {
        cacheQueue.async { [weak self] in
            self?.themes.removeAll()
        }
    }

    /// 移除特定主题
    func removeTheme(with id: String) {
        cacheQueue.async { [weak self] in
            self?.themes.removeValue(forKey: id)
        }
    }

    // MARK: - Built-in Themes Loading

    /// 加载内置主题
    private func loadBuiltinThemes() {
        // 加载默认主题
        let defaultThemes = [ThemeConfiguration.defaultLight, ThemeConfiguration.defaultDark]
        for theme in defaultThemes {
            themes[theme.id] = theme
        }

        // 从JSON文件加载内置主题
        loadBuiltinThemesFromFiles()
    }

    /// 从JSON文件加载内置主题
    private func loadBuiltinThemesFromFiles() {
        guard let bundlePath = Bundle.main.path(forResource: "BuiltIn", ofType: nil),
              let bundle = Bundle(path: bundlePath) else {
            print("BuiltIn themes bundle not found")
            return
        }

        guard let resourceURL = bundle.resourceURL else { return }

        do {
            let themeFiles = try fileManager.contentsOfDirectory(
                at: resourceURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for fileURL in themeFiles where fileURL.pathExtension == "json" {
                loadThemeFromFile(fileURL, isBuiltIn: true)
            }
        } catch {
            print("Failed to load built-in themes: \(error)")
        }
    }

    // MARK: - Custom Themes Loading

    /// 加载用户自定义主题
    private func loadCustomThemes() {
        guard let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return
        }

        let themesURL = documentsURL.appendingPathComponent("MiniCal/Themes")
        guard fileManager.fileExists(atPath: themesURL.path) else {
            return
        }

        do {
            let themeFiles = try fileManager.contentsOfDirectory(
                at: themesURL,
                includingPropertiesForKeys: nil,
                options: [.skipsHiddenFiles]
            )

            for fileURL in themeFiles where fileURL.pathExtension == "json" {
                loadThemeFromFile(fileURL, isBuiltIn: false)
            }
        } catch {
            print("Failed to load custom themes: \(error)")
        }
    }

    /// 从文件加载单个主题
    private func loadThemeFromFile(_ fileURL: URL, isBuiltIn: Bool) {
        do {
            let data = try Data(contentsOf: fileURL)
            var theme = try JSONDecoder().decode(ThemeConfiguration.self, from: data)

            // 确保isBuiltIn标志正确
            if !isBuiltIn {
                theme = ThemeConfiguration(
                    id: theme.id,
                    name: theme.name,
                    displayName: theme.displayName,
                    category: theme.category,
                    isBuiltIn: false,
                    primary: theme.primary,
                    secondary: theme.secondary,
                    accent: theme.accent,
                    background: theme.background,
                    surface: theme.surface,
                    text: theme.text,
                    calendar: theme.calendar,
                    status: theme.status,
                    author: theme.author,
                    version: theme.version,
                    description: theme.description,
                    previewColors: theme.previewColors
                )
            }

            // 验证主题配置
            let errors = theme.validate()
            if errors.isEmpty {
                themes[theme.id] = theme
            } else {
                print("Invalid theme configuration in \(fileURL.lastPathComponent): \(errors)")
            }
        } catch {
            print("Failed to load theme from \(fileURL.lastPathComponent): \(error)")
        }
    }

    // MARK: - Cache Management

    /// LRU缓存清理
    private func performLRUEviction() {
        // 简单的LRU实现：移除一些非内置主题
        let customThemes = themes.values.filter { !$0.isBuiltIn }
        let themesToRemove = Array(customThemes.prefix(5))

        for theme in themesToRemove {
            themes.removeValue(forKey: theme.id)
        }
    }

    /// 设置内存压力观察器
    private func setupMemoryPressureObserver() {
        let source = DispatchSource.makeMemoryPressureSource(
            eventMask: [.warning, .critical],
            queue: cacheQueue
        )

        source.setEventHandler { [weak self] in
            self?.handleMemoryPressure()
        }

        source.resume()
    }

    /// 处理内存压力
    private func handleMemoryPressure() {
        // 清理一半的自定义主题缓存
        let customThemes = themes.values.filter { !$0.isBuiltIn }
        let themesToRemove = Array(customThemes.prefix(customThemes.count / 2))

        for theme in themesToRemove {
            themes.removeValue(forKey: theme.id)
        }

        print("Memory pressure detected, cleared theme cache")
    }

    // MARK: - Theme Validation

    /// 验证主题配置
    func validateTheme(_ theme: ThemeConfiguration) -> [ValidationError] {
        var errors: [ValidationError] = []

        // 基础验证
        errors.append(contentsOf: theme.validate())

        // 缓存特定验证
        if themes.keys.contains(theme.id) {
            errors.append(ValidationError(
                field: "id",
                message: "主题ID已存在: \(theme.id)"
            ))
        }

        return errors
    }

    /// 检查主题是否存在
    func themeExists(with id: String) -> Bool {
        return cacheQueue.sync {
            return themes[id] != nil
        }
    }
}

// MARK: - Theme Cache Extensions

extension ThemeCache {
    /// 重新加载所有主题
    func reloadAllThemes() {
        cacheQueue.async { [weak self] in
            guard let self = self else { return }

            self.themes.removeAll()
            self.loadBuiltinThemes()
            self.loadCustomThemes()
        }
    }

    /// 导出主题配置
    func exportTheme(_ theme: ThemeConfiguration) -> Data? {
        do {
            return try JSONEncoder().encode(theme)
        } catch {
            print("Failed to export theme \(theme.id): \(error)")
            return nil
        }
    }

    /// 导入主题配置
    func importTheme(from data: Data) -> ThemeConfiguration? {
        do {
            let theme = try JSONDecoder().decode(ThemeConfiguration.self, from: data)
            let errors = validateTheme(theme)

            if errors.isEmpty {
                cacheTheme(theme)
                return theme
            } else {
                print("Failed to import theme: \(errors)")
                return nil
            }
        } catch {
            print("Failed to decode theme data: \(error)")
            return nil
        }
    }

    /// 获取缓存统计信息
    func cacheStatistics() -> ThemeCacheStatistics {
        return cacheQueue.sync {
            let builtinCount = themes.values.filter { $0.isBuiltIn }.count
            let customCount = themes.values.filter { !$0.isBuiltIn }.count
            let totalCount = themes.count

            return ThemeCacheStatistics(
                totalThemes: totalCount,
                builtinThemes: builtinCount,
                customThemes: customCount,
                maxCacheSize: maxCacheSize
            )
        }
    }
}

// MARK: - Cache Statistics

/// 主题缓存统计信息
struct ThemeCacheStatistics {
    let totalThemes: Int
    let builtinThemes: Int
    let customThemes: Int
    let maxCacheSize: Int

    var isNearCapacity: Bool {
        return totalThemes >= (maxCacheSize * 4) / 5
    }
}

// MARK: - Theme File Manager

/// 主题文件管理器
class ThemeFileManager {
    private let fileManager = FileManager.default

    /// 保存自定义主题到文件
    func saveCustomTheme(_ theme: ThemeConfiguration) -> Bool {
        guard let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }

        let themesDirectory = documentsURL.appendingPathComponent("MiniCal/Themes")

        // 创建目录（如果不存在）
        do {
            try fileManager.createDirectory(at: themesDirectory, withIntermediateDirectories: true)
        } catch {
            print("Failed to create themes directory: \(error)")
            return false
        }

        let fileURL = themesDirectory.appendingPathComponent("\(theme.id).json")

        do {
            let data = try JSONEncoder().encode(theme)
            try data.write(to: fileURL)
            return true
        } catch {
            print("Failed to save theme to file: \(error)")
            return false
        }
    }

    /// 删除自定义主题文件
    func deleteCustomTheme(with id: String) -> Bool {
        guard let documentsURL = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return false
        }

        let fileURL = documentsURL.appendingPathComponent("MiniCal/Themes/\(id).json")

        do {
            try fileManager.removeItem(at: fileURL)
            return true
        } catch {
            print("Failed to delete theme file: \(error)")
            return false
        }
    }
}