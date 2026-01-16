//
//  RecommendationSourceCell.swift
//  MiniCal
//
//  Created by MiniCal on 2025-12-17.
//

import SwiftUI
import AppKit

/// 推荐订阅源单元格视图
struct RecommendationSourceCell: View {
    // MARK: - Properties

    let recommendation: RecommendedSubscription
    let isSelected: Bool
    let isSubscribed: Bool  // 是否已订阅
    let onSelect: () -> Void
    let onDismiss: (() -> Void)?

    // MARK: - Initialization

    init(
        recommendation: RecommendedSubscription,
        isSelected: Bool = false,
        isSubscribed: Bool = false,
        onSelect: @escaping () -> Void,
        onDismiss: (() -> Void)? = nil
    ) {
        self.recommendation = recommendation
        self.isSelected = isSelected
        self.isSubscribed = isSubscribed
        self.onSelect = onSelect
        self.onDismiss = onDismiss
    }

    // MARK: - Body

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // 图标
            iconView

            // 内容
            VStack(alignment: .leading, spacing: 4) {
                // 标题行
                HStack(spacing: 6) {
                    Text(recommendation.name.localized())
                        .font(.headline)
                        .foregroundColor(.primary)

                    trustBadge

                    Spacer()
                }

                // 描述
                Text(recommendation.description.localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(2)

                // 提供方
                HStack(spacing: 4) {
                    Image(systemName: "building.2.fill")
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    Text(recommendation.provider)
                        .font(.caption2)
                        .foregroundColor(.secondary)

                    if let updateFrequency = recommendation.updateFrequency {
                        Text("•")
                            .font(.caption2)
                            .foregroundColor(.secondary)

                        Text(updateFrequency)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.top, 2)

                // 标签
                if !recommendation.tags.isEmpty {
                    tagsView
                        .padding(.top, 4)
                }
            }

            // 操作按钮
            VStack(spacing: 8) {
                // 订阅/已订阅/已选择按钮
                if isSubscribed {
                    // 已订阅状态
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.caption)
                        Text("recommendation.subscribed".localized())
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .foregroundColor(.green)
                    .cornerRadius(6)
                } else if isSelected {
                    // 本次引导中已选择
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.green)
                } else {
                    // 未订阅
                    Button(action: onSelect) {
                        Text("recommendation.subscribe".localized())
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                }

                // 拒绝按钮
                if let onDismiss = onDismiss {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark.circle")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    .help("recommendation.dismiss".localized())
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(recommendationBackgroundColor)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? Color.accentColor : Color.gray.opacity(0.2), lineWidth: isSelected ? 2 : 1)
                )
        )
    }

    // MARK: - Subviews

    /// 图标视图
    private var iconView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.1))
                .frame(width: 44, height: 44)

            Image(systemName: recommendation.iconName ?? "calendar")
                .font(.title2)
                .foregroundColor(.accentColor)
        }
    }

    /// 信任等级徽章
    @ViewBuilder
    private var trustBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: recommendation.trustLevel.icon)
                .font(.caption2)

            Text(recommendation.trustLevel.displayName)
                .font(.caption2)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(trustBadgeColor.opacity(0.15))
        .foregroundColor(trustBadgeColor)
        .cornerRadius(4)
    }

    /// 信任等级颜色
    private var trustBadgeColor: Color {
        switch recommendation.trustLevel {
        case .verified: return .green
        case .community: return .blue
        case .unverified: return .orange
        }
    }

    private var recommendationBackgroundColor: Color {
        if #available(macOS 12.0, *) {
            return Color(nsColor: .controlBackgroundColor)
        }
        return Color(NSColor.controlBackgroundColor)
    }

    /// 标签视图
    private var tagsView: some View {
        HStack(spacing: 4) {
            ForEach(recommendation.tags.prefix(3), id: \.self) { tag in
                Text("#\(tag)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
            }
        }
    }
}

// MARK: - Preview

#Preview {
    VStack(spacing: 16) {
        RecommendationSourceCell(
            recommendation: RecommendedSubscription(
                id: "test-1",
                name: RecommendedSubscription.LocalizedString(
                    en: "China Public Holidays",
                    zhHans: "中国法定节假日",
                    zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                ),
                description: RecommendedSubscription.LocalizedString(
                    en: "Official public holidays in China",
                    zhHans: "国务院办公厅发布的中国法定节假日安排",
                    zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                ),
                url: "https://example.com/holidays.ics",
                applicableRegions: ["CN", "zh-Hans"],
                applicableCalendars: ["chinese"],
                trustLevel: .verified,
                provider: "Apple iCloud",
                tags: ["holiday", "official", "public"],
                iconName: "building.columns.fill",
                updateFrequency: "Yearly"
            ),
            isSelected: false,
            onSelect: {},
            onDismiss: {}
        )

        RecommendationSourceCell(
            recommendation: RecommendedSubscription(
                id: "test-2",
                name: RecommendedSubscription.LocalizedString(
                    en: "Islamic Holidays",
                    zhHans: "伊斯兰节日",
                    zhHant: nil, ar: "الأعياد الإسلامية", fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                ),
                description: RecommendedSubscription.LocalizedString(
                    en: "Major Islamic holidays",
                    zhHans: "主要伊斯兰节日",
                    zhHant: nil, ar: "الأعياد الإسلامية الرئيسية", fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                ),
                url: "https://example.com/islamic.ics",
                applicableRegions: ["SA", "ar"],
                applicableCalendars: ["islamic"],
                trustLevel: .community,
                provider: "Islamic Community",
                tags: ["religious", "islamic"],
                iconName: "moon.stars.fill",
                updateFrequency: "Yearly"
            ),
            isSelected: true,
            onSelect: {},
            onDismiss: nil
        )
    }
    .padding()
    .frame(width: 400)
}
