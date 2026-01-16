//
//  SubscriptionRecommendationService.swift
//  MiniCal
//
//  Created by MiniCal on 2025-12-17.
//

import Foundation
import Combine

/// 订阅推荐服务
@MainActor
class SubscriptionRecommendationService: ObservableObject {
    // MARK: - Singleton

    static let shared = SubscriptionRecommendationService()

    // MARK: - Published Properties

    /// 所有可用的推荐源
    @Published private(set) var allRecommendations: [RecommendedSubscription] = []

    /// 用户推荐偏好
    @Published var preferences: RecommendationPreferences {
        didSet {
            savePreferences()
        }
    }

    // MARK: - Private Properties

    private let recommendationsFileName = "recommendations.json"
    private let preferencesKey = "RecommendationPreferences"

    // MARK: - Initialization

    private init() {
        self.preferences = Self.loadPreferences()
        loadRecommendations()
    }

    // MARK: - Public Methods

    /// 获取推荐订阅源
    /// - Parameters:
    ///   - calendar: 日历类型
    ///   - region: 地区代码（可选，默认使用系统语言）
    ///   - excludeDismissed: 是否排除已拒绝的推荐
    ///   - limit: 限制返回数量
    /// - Returns: 推荐订阅源列表
    func getRecommendations(
        for calendar: CalendarType,
        region: String? = nil,
        excludeDismissed: Bool = true,
        limit: Int? = nil
    ) -> [RecommendedSubscription] {
        // 如果未启用自动推荐，返回空
        guard preferences.autoShowRecommendations else {
            Logger.debug("Auto recommendations disabled", category: Logger.app)
            return []
        }

        // 确定地区代码（空字符串表示跳过地区过滤）
        let targetRegion = region ?? getSystemRegion()
        let skipRegionFilter = region == ""

        // 筛选适用的推荐
        var filtered = allRecommendations.filter { recommendation in
            // 检查日历类型匹配
            let calendarMatch = recommendation.applicableCalendars.isEmpty ||
                recommendation.applicableCalendars.contains(calendar.rawValue)

            // 检查地区匹配（如果 skipRegionFilter 为 true，则跳过地区检查）
            let regionMatch = skipRegionFilter ||
                recommendation.applicableRegions.isEmpty ||
                recommendation.applicableRegions.contains(targetRegion) ||
                recommendation.applicableRegions.contains(where: { targetRegion.hasPrefix($0) })

            return calendarMatch && regionMatch
        }

        // 排除已拒绝的推荐
        if excludeDismissed {
            let dismissedIds = preferences.permanentlyDismissedRecommendations
                .union(preferences.sessionDismissedRecommendations)

            filtered = filtered.filter { !dismissedIds.contains($0.id) }
        }

        // 检查冷却期
        filtered = filtered.filter { recommendation in
            guard let lastDate = preferences.lastRecommendationDate[recommendation.id] else {
                return true // 从未推荐过
            }

            let daysSince = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 0
            return daysSince >= preferences.cooldownPeriodDays
        }

        // 按信任等级排序（verified > community > unverified）
        filtered.sort { lhs, rhs in
            let order: [RecommendedSubscription.TrustLevel] = [.verified, .community, .unverified]
            let lhsIndex = order.firstIndex(of: lhs.trustLevel) ?? order.count
            let rhsIndex = order.firstIndex(of: rhs.trustLevel) ?? order.count
            return lhsIndex < rhsIndex
        }

        // 限制数量
        if let limit = limit {
            filtered = Array(filtered.prefix(limit))
        }

        Logger.info("Found \(filtered.count) recommendations for \(calendar.rawValue) in \(targetRegion)", category: Logger.app)

        return filtered
    }

    /// 记录推荐已显示
    func markRecommendationShown(_ recommendationId: String) {
        preferences.lastRecommendationDate[recommendationId] = Date()
        Logger.debug("Marked recommendation shown: \(recommendationId)", category: Logger.app)
    }

    /// 永久拒绝推荐
    func dismissRecommendationPermanently(_ recommendationId: String) {
        preferences.permanentlyDismissedRecommendations.insert(recommendationId)
        Logger.info("Permanently dismissed recommendation: \(recommendationId)", category: Logger.app)
    }

    /// 当前会话拒绝推荐
    func dismissRecommendationForSession(_ recommendationId: String) {
        preferences.sessionDismissedRecommendations.insert(recommendationId)
        Logger.debug("Dismissed recommendation for session: \(recommendationId)", category: Logger.app)
    }

    /// 订阅推荐源
    /// - Parameters:
    ///   - recommendation: 推荐订阅源
    ///   - userConfirmed: 用户是否已确认安全提示
    ///   - markAsShown: 是否标记为已显示（引导流程中应设为 false，避免触发冷却期）
    /// - Throws: 订阅错误
    func subscribe(
        _ recommendation: RecommendedSubscription,
        userConfirmed: Bool = false,
        markAsShown: Bool = true
    ) async throws {
        // 验证 URL
        guard let url = URL(string: recommendation.url) else {
            Logger.error("Invalid subscription URL: \(recommendation.url)", category: Logger.app)
            throw RecommendationError.invalidURL
        }

        // 未验证的源必须用户确认
        if recommendation.trustLevel == .unverified && !userConfirmed {
            Logger.warning("Unverified source requires user confirmation", category: Logger.app)
            throw RecommendationError.securityConfirmationRequired
        }

        Logger.info("Subscribing to: \(recommendation.name.localized())", category: Logger.app)

        // 集成到订阅管理系统
        let subscriptionService = CalendarSubscriptionService()

        // 创建订阅对象
        var subscription = CalendarSubscription(
            title: recommendation.name.localized(),
            color: .blue, // 默认蓝色，用户可以在设置中修改
            subscriptionType: .external
        )
        subscription.url = url

        // 保存订阅 ID 用于后续同步
        let subscriptionId = subscription.id

        // 调用订阅服务添加订阅
        try await subscriptionService.addSubscription(subscription)

        Logger.info("Successfully added subscription: \(recommendation.name.localized())", category: Logger.app)

        // 标记已显示（避免重复推荐）
        // 引导流程中不标记，避免触发冷却期导致推荐消失
        if markAsShown {
            markRecommendationShown(recommendation.id)
        }

        // 发送订阅更新通知，触发 UI 刷新
        await MainActor.run {
            NotificationCenter.default.post(name: .subscriptionDidUpdate, object: nil)
        }

        // 立即同步新添加的订阅事件
        Logger.info("Starting immediate sync for subscription: \(recommendation.name.localized())", category: Logger.app)

        // 将 Combine Publisher 转换为 async/await
        do {
            let syncResult = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<SyncResult, Error>) in
                var cancellable: AnyCancellable?
                cancellable = subscriptionService.syncSubscription(id: subscriptionId)
                    .sink(
                        receiveCompletion: { completion in
                            switch completion {
                            case .finished:
                                break
                            case .failure(let error):
                                continuation.resume(throwing: error)
                            }
                            cancellable?.cancel()
                        },
                        receiveValue: { result in
                            continuation.resume(returning: result)
                        }
                    )
            }

            Logger.info("Sync completed: added \(syncResult.eventsAdded), updated \(syncResult.eventsUpdated), deleted \(syncResult.eventsDeleted)", category: Logger.app)
        } catch {
            Logger.error("Failed to sync subscription: \(error)", category: Logger.app)
            // 同步失败不影响订阅添加，仅记录错误
        }
    }

    /// 重置推荐记录（用于测试或用户请求）
    func resetRecommendations() {
        preferences = RecommendationPreferences()
        Logger.info("Reset all recommendation preferences", category: Logger.app)
    }

    /// 重置会话拒绝记录（应用重启时调用）
    func resetSessionDismissals() {
        preferences.sessionDismissedRecommendations.removeAll()
        Logger.debug("Reset session dismissals", category: Logger.app)
    }

    /// 完成首次启动引导
    func completeOnboarding() {
        preferences.onboardingCompleted = true
        Logger.info("Onboarding completed", category: Logger.app)
    }

    /// 检查是否需要显示首次启动引导
    func shouldShowOnboarding() -> Bool {
        return !preferences.onboardingCompleted
    }

    // MARK: - Private Methods

    /// 加载推荐配置文件
    private func loadRecommendations() {
        // 尝试从 Bundle 的 Resources 目录加载
        let url = Bundle.main.url(forResource: "recommendations", withExtension: "json")

        guard let fileURL = url else {
            Logger.error("recommendations.json not found in bundle", category: Logger.app)
            allRecommendations = []
            return
        }

        do {
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            let configuration = try decoder.decode(RecommendationConfiguration.self, from: data)

            allRecommendations = configuration.recommendations

            Logger.info("Loaded \(allRecommendations.count) recommendations (version: \(configuration.version))", category: Logger.app)
        } catch {
            Logger.error("Failed to load recommendations: \(error)", category: Logger.app)
            allRecommendations = []
        }
    }

    /// 获取系统地区代码
    private func getSystemRegion() -> String {
        // 优先使用语言代码
        let languageCode = Locale.current.languageCodeIdentifier
        let scriptCode = Locale.current.scriptCodeIdentifier

        if !languageCode.isEmpty {
            // 处理中文（区分简繁体）
            if languageCode == "zh" {
                if scriptCode == "Hant" {
                    return "zh-Hant"
                }
                return "zh-Hans"
            }
            return languageCode
        }

        // 回退到地区代码
        let regionCode = Locale.current.regionCodeIdentifier
        return regionCode.isEmpty ? "en" : regionCode
    }

    /// 保存用户偏好到 UserDefaults
    private func savePreferences() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(preferences)
            UserDefaults.standard.set(data, forKey: preferencesKey)
            Logger.debug("Saved recommendation preferences", category: Logger.app)
        } catch {
            Logger.error("Failed to save preferences: \(error)", category: Logger.app)
        }
    }

    /// 从 UserDefaults 加载用户偏好
    private static func loadPreferences() -> RecommendationPreferences {
        guard let data = UserDefaults.standard.data(forKey: "RecommendationPreferences") else {
            Logger.debug("No saved preferences, using defaults", category: Logger.app)
            return RecommendationPreferences()
        }

        do {
            let decoder = JSONDecoder()
            let preferences = try decoder.decode(RecommendationPreferences.self, from: data)
            Logger.debug("Loaded saved preferences", category: Logger.app)
            return preferences
        } catch {
            Logger.error("Failed to load preferences: \(error)", category: Logger.app)
            return RecommendationPreferences()
        }
    }
}

// MARK: - Error Types

enum RecommendationError: LocalizedError {
    case invalidURL
    case securityConfirmationRequired

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid subscription URL"
        case .securityConfirmationRequired:
            return "Security confirmation required for unverified sources"
        }
    }
}
