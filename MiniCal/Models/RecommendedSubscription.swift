//
//  RecommendedSubscription.swift
//  MiniCal
//
//  Created by MiniCal on 2025-12-17.
//

import Foundation

/// 推荐订阅源数据模型
struct RecommendedSubscription: Codable, Identifiable, Hashable {
    /// 唯一标识符
    let id: String

    /// 订阅源名称（多语言）
    let name: LocalizedString

    /// 订阅源描述（多语言）
    let description: LocalizedString

    /// iCal 订阅 URL
    let url: String

    /// 适用地区/语言代码列表（如 ["CN", "zh-Hans", "zh-Hant"]）
    let applicableRegions: [String]

    /// 适用日历类型列表
    let applicableCalendars: [String]

    /// 信任等级
    let trustLevel: TrustLevel

    /// 提供方名称
    let provider: String

    /// 标签（如 "holiday", "official", "religious"）
    let tags: [String]

    /// 图标名称（可选，SF Symbols）
    let iconName: String?

    /// 更新频率说明
    let updateFrequency: String?

    // MARK: - Nested Types

    /// 本地化字符串
    struct LocalizedString: Codable, Hashable {
        let en: String
        let zhHans: String?
        let zhHant: String?
        let ar: String?
        let fa: String?
        let he: String?
        let ja: String?
        let ko: String?
        let th: String?
        let tr: String?
        let ur: String?
        let vi: String?

        enum CodingKeys: String, CodingKey {
            case en
            case zhHans = "zh-Hans"
            case zhHant = "zh-Hant"
            case ar, fa, he, ja, ko, th, tr, ur, vi
        }

        /// 根据当前系统语言获取本地化文本
        func localized() -> String {
            let languageCode = Locale.current.language.languageCode?.identifier ?? "en"

            switch languageCode {
            case "zh":
                if Locale.current.language.script?.identifier == "Hant" {
                    return zhHant ?? zhHans ?? en
                }
                return zhHans ?? en
            case "ar": return ar ?? en
            case "fa": return fa ?? en
            case "he": return he ?? en
            case "ja": return ja ?? en
            case "ko": return ko ?? en
            case "th": return th ?? en
            case "tr": return tr ?? en
            case "ur": return ur ?? en
            case "vi": return vi ?? en
            default: return en
            }
        }
    }

    /// 信任等级
    enum TrustLevel: String, Codable {
        /// 官方认证（政府、知名机构）
        case verified = "verified"

        /// 社区推荐（经过验证的社区贡献）
        case community = "community"

        /// 未验证（用户自定义）
        case unverified = "unverified"

        /// 显示名称
        var displayName: String {
            switch self {
            case .verified:
                return "recommendation.trust_level.verified".localized()
            case .community:
                return "recommendation.trust_level.community".localized()
            case .unverified:
                return "recommendation.trust_level.unverified".localized()
            }
        }

        /// 图标
        var icon: String {
            switch self {
            case .verified: return "checkmark.seal.fill"
            case .community: return "star.fill"
            case .unverified: return "exclamationmark.triangle.fill"
            }
        }

        /// 颜色（语义化）
        var semanticColor: String {
            switch self {
            case .verified: return "green"
            case .community: return "blue"
            case .unverified: return "orange"
            }
        }
    }
}

// MARK: - Recommendation Container

/// 推荐订阅源配置容器
struct RecommendationConfiguration: Codable {
    /// 配置版本
    let version: String

    /// 最后更新日期
    let lastUpdate: String

    /// 推荐列表
    let recommendations: [RecommendedSubscription]
}

// MARK: - User Recommendation Preferences

/// 用户推荐偏好（存储在 UserDefaults）
struct RecommendationPreferences: Codable {
    /// 是否完成首次启动引导
    var onboardingCompleted: Bool = false

    /// 永久拒绝的推荐源 ID 列表
    var permanentlyDismissedRecommendations: Set<String> = []

    /// 当前会话拒绝的推荐源 ID 列表（重启后重置）
    var sessionDismissedRecommendations: Set<String> = []

    /// 上次推荐日期（用于冷却期控制）
    var lastRecommendationDate: [String: Date] = [:]

    /// 是否启用自动推荐
    var autoShowRecommendations: Bool = true

    /// 推荐冷却期（天数）
    var cooldownPeriodDays: Int = 7
}
