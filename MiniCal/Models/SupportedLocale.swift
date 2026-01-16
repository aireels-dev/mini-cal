//
//  SupportedLocale.swift
//  MiniCal
//
//  Created on 2025/11/27.
//

import Foundation

/// 支持的语言环境
enum SupportedLocale: String, CaseIterable, Codable {
    // P0 语言
    case simplifiedChinese = "zh-Hans"      // 简体中文
    case traditionalChinese = "zh-Hant"     // 繁体中文
    case english = "en"                     // 英语
    case arabic = "ar"                      // 阿拉伯语
    case hebrew = "he"                      // 希伯来语

    // P1 语言
    case japanese = "ja"                    // 日语
    case korean = "ko"                      // 韩语
    case vietnamese = "vi"                  // 越南语
    case persian = "fa"                     // 波斯语
    case thai = "th"                        // 泰语
    case turkish = "tr"                     // 土耳其语
    case urdu = "ur"                        // 乌尔都语

    var locale: Locale {
        return Locale(identifier: rawValue)
    }

    var displayName: String {
        switch self {
        case .simplifiedChinese: return "简体中文"
        case .traditionalChinese: return "繁體中文"
        case .english: return "English"
        case .arabic: return "العربية"
        case .hebrew: return "עברית"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .vietnamese: return "Tiếng Việt"
        case .persian: return "فارسی"
        case .thai: return "ไทย"
        case .turkish: return "Türkçe"
        case .urdu: return "اردو"
        }
    }

    var isRTL: Bool {
        switch self {
        case .arabic, .hebrew, .persian, .urdu:
            return true
        default:
            return false
        }
    }

    /// 获取该语言环境推荐的历法类型
    var recommendedCalendar: CalendarType? {
        switch self {
        case .simplifiedChinese, .traditionalChinese:
            return .chinese
        case .arabic, .turkish, .urdu:
            return .islamic
        case .hebrew:
            return .hebrew
        case .persian:
            return .persian
        case .japanese:
            return .japanese
        case .thai:
            return .buddhist
        case .vietnamese, .korean:
            return .chinese  // 越南和韩国也使用农历变体
        case .english:
            return nil  // 英语环境不推荐特定历法
        }
    }

    /// 从系统 Locale 推荐语言环境
    static func recommend(from systemLocale: Locale = .current) -> SupportedLocale {
        let languageCode = systemLocale.languageCodeIdentifier
        let regionCode = systemLocale.regionCodeIdentifier

        // 优先匹配语言代码
        if let match = SupportedLocale.allCases.first(where: { $0.rawValue.hasPrefix(languageCode) }) {
            return match
        }

        // 根据地区代码推荐
        switch regionCode {
        case "CN", "SG": return .simplifiedChinese
        case "TW", "HK", "MO": return .traditionalChinese
        case "SA", "AE", "EG", "IQ": return .arabic
        case "IL": return .hebrew
        case "IR": return .persian
        case "JP": return .japanese
        case "KR": return .korean
        case "VN": return .vietnamese
        case "TH": return .thai
        case "TR": return .turkish
        case "PK": return .urdu
        default: return .english
        }
    }
}
