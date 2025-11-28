//
//  CalendarSize.swift
//  MiniCal
//
//  Created on 2025/10/28.
//

import Foundation
import CoreGraphics

/// 日历面板尺寸档位
enum CalendarSize: String, CaseIterable, Codable {
    case compact
    case standard
    case large
    case xlarge

    /// 显示名称
    var displayName: String {
        NSLocalizedString("size.\(rawValue)", comment: "")
    }

    /// 面板尺寸（统一比例 10:11，接近正方形设计）
    var dimensions: CGSize {
        switch self {
        case .compact:
            return CGSize(width: 300, height: 330)  // 比例 0.909，基准
        case .standard:
            return CGSize(width: 360, height: 396)  // 比例 0.909，+60px
        case .large:
            return CGSize(width: 420, height: 462)  // 比例 0.909，+60px
        case .xlarge:
            return CGSize(width: 480, height: 528)  // 比例 0.909，+60px
        }
    }

    /// 面板宽度
    var width: CGFloat {
        dimensions.width
    }

    /// 面板高度
    var height: CGFloat {
        dimensions.height
    }

    /// 网格尺寸（面板宽度减去左右内边距）
    var gridSize: CGFloat {
        width - 20  // 左右各留 10pt 边距
    }

    /// 单个日期单元格尺寸（每档递增 8px）
    var cellSize: CGFloat {
        switch self {
        case .compact:
            return 36  // 基准
        case .standard:
            return 44  // +8
        case .large:
            return 52  // +8
        case .xlarge:
            return 60  // +8
        }
    }

    /// 日期数字字体大小（加粗显示，提升层级）
    var dateFontSize: CGFloat {
        switch self {
        case .compact:
            return 15  // 差距 7pt
        case .standard:
            return 17  // 差距 8pt
        case .large:
            return 19  // 差距 9pt
        case .xlarge:
            return 22  // 差距 10pt
        }
    }

    /// 本地历法字体大小（细体显示，降低层级）
    var secondaryFontSize: CGFloat {
        switch self {
        case .compact:
            return 8
        case .standard:
            return 9
        case .large:
            return 10
        case .xlarge:
            return 12
        }
    }

    /// 事件指示器尺寸
    var eventIndicatorSize: CGFloat {
        switch self {
        case .compact:
            return 3
        case .standard:
            return 4
        case .large:
            return 5
        case .xlarge:
            return 6
        }
    }

    /// 尺寸描述（显示具体像素值和宽高比）
    var sizeDescription: String {
        let ratio = width / height
        let ratioLabel = NSLocalizedString("settings.size_description", comment: "")
        return "\(Int(width)) × \(Int(height)) (\(ratioLabel) \(String(format: "%.3f", ratio)))"
    }

    /// 简短尺寸描述
    var shortDescription: String {
        "\(Int(width)) × \(Int(height))"
    }

    // MARK: - Event List Popup Dimensions

    /// 事件列表弹窗宽度
    var eventListWidth: CGFloat {
        switch self {
        case .compact:
            return 320
        case .standard:
            return 380
        case .large:
            return 440
        case .xlarge:
            return 500
        }
    }

    /// 事件列表表单模式高度
    var eventListFormHeight: CGFloat {
        switch self {
        case .compact:
            return 450
        case .standard:
            return 500
        case .large:
            return 550
        case .xlarge:
            return 600
        }
    }

    /// 事件列表最大滚动高度
    var eventListMaxScrollHeight: CGFloat {
        switch self {
        case .compact:
            return 260
        case .standard:
            return 300
        case .large:
            return 340
        case .xlarge:
            return 380
        }
    }

    /// 事件列表表单内容高度
    var eventListFormContentHeight: CGFloat {
        switch self {
        case .compact:
            return 330
        case .standard:
            return 370
        case .large:
            return 410
        case .xlarge:
            return 450
        }
    }

    // MARK: - Event List Font Sizes

    /// 事件列表标题字体大小
    var eventListTitleFontSize: CGFloat {
        switch self {
        case .compact:
            return 13
        case .standard:
            return 14
        case .large:
            return 15
        case .xlarge:
            return 16
        }
    }

    /// 事件列表副标题字体大小
    var eventListSubtitleFontSize: CGFloat {
        switch self {
        case .compact:
            return 11
        case .standard:
            return 12
        case .large:
            return 13
        case .xlarge:
            return 14
        }
    }

    /// 事件列表按钮字体大小
    var eventListButtonFontSize: CGFloat {
        switch self {
        case .compact:
            return 12
        case .standard:
            return 13
        case .large:
            return 14
        case .xlarge:
            return 15
        }
    }

    /// 事件列表图标大小
    var eventListIconSize: CGFloat {
        switch self {
        case .compact:
            return 32
        case .standard:
            return 36
        case .large:
            return 40
        case .xlarge:
            return 44
        }
    }
}
