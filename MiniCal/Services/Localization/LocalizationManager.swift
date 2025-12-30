//
//  LocalizationManager.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation
import Combine

/// 本地化管理器
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()

    @Published private(set) var context: LocalizationContext

    /// 缓存：避免重复查询
    private var stringCache: [CacheKey: String] = [:]
    private let cacheQueue = DispatchQueue(label: "com.minical.localization.cache")

    private init() {
        // 从 UserDefaults 加载或使用默认值
        if let data = UserDefaults.standard.data(forKey: "LocalizationContext"),
           let saved = try? JSONDecoder().decode(LocalizationContext.self, from: data) {
            self.context = saved
        } else {
            self.context = .default
        }
    }

    // MARK: - Context Management

    /// 更新本地化上下文
    func updateContext(_ newContext: LocalizationContext) {
        context = newContext

        // 保存到 UserDefaults
        if let data = try? JSONEncoder().encode(newContext) {
            UserDefaults.standard.set(data, forKey: "LocalizationContext")
        }

        // 设置应用语言（用于 String Catalogs）
        if let interfaceLocale = newContext.interfaceLocale {
            // 手动选择的语言
            UserDefaults.standard.set([interfaceLocale.rawValue], forKey: "AppleLanguages")
        } else {
            // 自动模式：清除自定义设置，使用系统语言
            UserDefaults.standard.removeObject(forKey: "AppleLanguages")
        }
        UserDefaults.standard.synchronize()

        // 清空缓存
        clearCache()

        // 触发全局刷新
        DispatchQueue.main.async {
            NotificationCenter.default.post(name: .localizationDidChange, object: nil)
        }
    }

    /// 更新界面语言（nil 表示自动模式）
    func updateInterfaceLocale(_ locale: SupportedLocale?) {
        let newContext = LocalizationContext(
            interfaceLocale: locale,
            calendarLocale: context.calendarLocale
        )
        updateContext(newContext)
    }

    /// 更新历法语言
    func updateCalendarLocale(_ locale: SupportedLocale?) {
        let newContext = LocalizationContext(
            interfaceLocale: context.interfaceLocale,
            calendarLocale: locale
        )
        updateContext(newContext)
    }

    // MARK: - String Localization

    /// 获取本地化字符串
    func localized(
        _ key: String,
        table: String? = nil,
        bundle: Bundle = .main,
        locale: SupportedLocale? = nil,
        comment: String = ""
    ) -> String {
        let effectiveLocale = locale ?? context.effectiveInterfaceLocale
        let cacheKey = CacheKey(key: key, table: table, locale: effectiveLocale.rawValue)

        // 先检查缓存
        if let cached = getCached(cacheKey) {
            return cached
        }

        // 获取本地化字符串
        let localeIdentifier = effectiveLocale.rawValue
        let localizedString = localizedString(
            key: key,
            table: table,
            bundle: bundle,
            localeIdentifier: localeIdentifier,
            comment: comment
        )

        // 缓存结果（缓存翻译后的字符串，而不是语言标识符）
        cache(localizedString, for: cacheKey)

        return localizedString
    }

    /// 获取历法专用本地化字符串
    func localizedCalendar(
        _ key: String,
        table: String? = "CalendarNames",
        calendarType: CalendarType? = nil
    ) -> String {
        let locale = context.effectiveCalendarLocale
        return localized(key, table: table, locale: locale)
    }

    // MARK: - Private Helpers

    private func localizedString(
        key: String,
        table: String?,
        bundle: Bundle,
        localeIdentifier: String,
        comment: String
    ) -> String {
        // 获取特定语言的 bundle
        guard let path = bundle.path(forResource: localeIdentifier, ofType: "lproj"),
              let localeBundle = Bundle(path: path) else {
            // Fallback 到英语
            return fallbackLocalization(key: key, table: table, bundle: bundle)
        }

        let localizedString = NSLocalizedString(
            key,
            tableName: table,
            bundle: localeBundle,
            value: key,
            comment: comment
        )

        // 如果返回的是 key 本身，说明未找到翻译，使用 fallback
        if localizedString == key {
            return fallbackLocalization(key: key, table: table, bundle: bundle)
        }

        return localizedString
    }

    private func fallbackLocalization(
        key: String,
        table: String?,
        bundle: Bundle
    ) -> String {
        // 尝试使用英语
        guard let path = bundle.path(forResource: "en", ofType: "lproj"),
              let enBundle = Bundle(path: path) else {
            return key
        }

        let fallback = NSLocalizedString(
            key,
            tableName: table,
            bundle: enBundle,
            value: key,
            comment: ""
        )

        return fallback != key ? fallback : key
    }

    // MARK: - Cache Management

    private func getCached(_ key: CacheKey) -> String? {
        return cacheQueue.sync {
            stringCache[key]
        }
    }

    private func cache(_ value: String, for key: CacheKey) {
        cacheQueue.async { [weak self] in
            // 抑制 Swift 6 Main Actor 警告 - 已确保线程安全
            // CacheKey 是 @unchecked Sendable，所有操作在串行队列上执行
            self?.stringCache[key] = value
        }
    }

    private func clearCache() {
        cacheQueue.async { [weak self] in
            // 抑制 Swift 6 Main Actor 警告 - 已确保线程安全
            // CacheKey 是 @unchecked Sendable，所有操作在串行队列上执行
            self?.stringCache.removeAll()
        }
    }

    // MARK: - Cache Key

    // 使用 @unchecked Sendable 因为 CacheKey 只包含不可变值类型，是线程安全的
    private struct CacheKey: Hashable, @unchecked Sendable {
        let key: String
        let table: String?
        let locale: String
    }
}
