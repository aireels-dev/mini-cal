//
//  CalendarSwitchRecommendationCard.swift
//  MiniCal
//
//  Created by MiniCal on 2025-12-17.
//

import SwiftUI

/// 日历切换推荐卡片（非阻断式底部弹出）
struct CalendarSwitchRecommendationCard: View {
    // MARK: - Properties

    let calendarType: CalendarType
    let recommendations: [RecommendedSubscription]
    let onSubscribe: (RecommendedSubscription) -> Void
    let onDismiss: () -> Void
    let onDismissForever: () -> Void

    // MARK: - State

    @State private var isExpanded = false
    @State private var showingSecurityAlert = false
    @State private var pendingSubscription: RecommendedSubscription?
    @State private var hovering = false
    @State private var autoHideTask: Task<Void, Never>?

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 主内容
            HStack(alignment: .top, spacing: 12) {
                // 图标
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                    .frame(width: 32)

                // 文本内容
                VStack(alignment: .leading, spacing: 6) {
                    Text("recommendation.switch_calendar.title".localized(with: ["calendar": calendarType.displayName]))
                        .font(.headline)
                        .foregroundColor(.primary)

                    if !isExpanded {
                        Text("recommendation.switch_calendar.subtitle".localized(with: ["count": "\(recommendations.count)"]))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // 按钮组
                HStack(spacing: 8) {
                    // 展开/收起
                    if !recommendations.isEmpty {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isExpanded.toggle()
                                cancelAutoHide()
                            }
                        }) {
                            Text(isExpanded ? "recommendation.collapse".localized() : "recommendation.view_all".localized())
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

                    // 关闭按钮
                    Button(action: handleDismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)

            // 展开内容
            if isExpanded {
                Divider()

                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(recommendations.prefix(3)) { recommendation in
                            RecommendationSourceCell(
                                recommendation: recommendation,
                                isSelected: false,
                                onSelect: {
                                    handleSubscribe(recommendation)
                                },
                                onDismiss: {
                                    // 这里暂不提供单独拒绝，只能整体拒绝
                                }
                            )
                        }

                        // 永久拒绝选项
                        Button(action: {
                            onDismissForever()
                        }) {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                    .font(.caption)

                                Text("recommendation.dismiss_forever".localized())
                                    .font(.caption)
                            }
                            .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 8)
                    }
                    .padding(16)
                }
                .frame(maxHeight: 300)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .windowBackgroundColor))
                .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.accentColor.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .onHover { hovering in
            self.hovering = hovering
            if hovering {
                cancelAutoHide()
            } else if !isExpanded {
                scheduleAutoHide()
            }
        }
        .onAppear {
            if !isExpanded {
                scheduleAutoHide()
            }
        }
        .alert("recommendation.security_alert.title".localized(), isPresented: $showingSecurityAlert) {
            Button("recommendation.security_alert.cancel".localized(), role: .cancel) {
                pendingSubscription = nil
            }

            Button("recommendation.security_alert.confirm".localized()) {
                if let subscription = pendingSubscription {
                    onSubscribe(subscription)
                    pendingSubscription = nil
                }
            }
        } message: {
            if let subscription = pendingSubscription {
                VStack(alignment: .leading, spacing: 8) {
                    Text("recommendation.security_alert.message".localized(with: AppBrand.displayName))

                    Text("URL: \(subscription.url)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }

    // MARK: - Methods

    /// 处理订阅
    private func handleSubscribe(_ recommendation: RecommendedSubscription) {
        cancelAutoHide()

        // 未验证的源需要安全确认
        if recommendation.trustLevel == .unverified {
            pendingSubscription = recommendation
            showingSecurityAlert = true
        } else {
            onSubscribe(recommendation)
        }
    }

    /// 处理关闭
    private func handleDismiss() {
        cancelAutoHide()
        onDismiss()
    }

    /// 安排自动隐藏
    private func scheduleAutoHide() {
        cancelAutoHide()

        autoHideTask = Task {
            try? await Task.sleep(for: .seconds(3))

            if !Task.isCancelled && !hovering && !isExpanded {
                await MainActor.run {
                    onDismiss()
                }
            }
        }
    }

    /// 取消自动隐藏
    private func cancelAutoHide() {
        autoHideTask?.cancel()
        autoHideTask = nil
    }
}

// MARK: - String Localization Extension

extension String {
    /// 带参数的本地化
    func localized(with replacements: [String: String]) -> String {
        var result = self.localized()
        for (key, value) in replacements {
            result = result.replacingOccurrences(of: "{\(key)}", with: value)
        }
        return result
    }
}

// MARK: - Preview

#Preview {
    ZStack {
        Color.gray.opacity(0.1)

        VStack {
            Spacer()

            CalendarSwitchRecommendationCard(
                calendarType: .chinese,
                recommendations: [
                    RecommendedSubscription(
                        id: "test-1",
                        name: RecommendedSubscription.LocalizedString(
                            en: "China Public Holidays",
                            zhHans: "中国法定节假日",
                            zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                        ),
                        description: RecommendedSubscription.LocalizedString(
                            en: "Official public holidays",
                            zhHans: "国务院发布的法定节假日",
                            zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                        ),
                        url: "https://example.com/holidays.ics",
                        applicableRegions: ["CN"],
                        applicableCalendars: ["chinese"],
                        trustLevel: .verified,
                        provider: "Apple iCloud",
                        tags: ["holiday", "official"],
                        iconName: "building.columns.fill",
                        updateFrequency: "Yearly"
                    ),
                    RecommendedSubscription(
                        id: "test-2",
                        name: RecommendedSubscription.LocalizedString(
                            en: "Traditional Festivals",
                            zhHans: "传统节日",
                            zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                        ),
                        description: RecommendedSubscription.LocalizedString(
                            en: "Chinese traditional festivals",
                            zhHans: "中国传统节日",
                            zhHant: nil, ar: nil, fa: nil, he: nil, ja: nil, ko: nil, th: nil, tr: nil, ur: nil, vi: nil
                        ),
                        url: "https://example.com/festivals.ics",
                        applicableRegions: ["CN"],
                        applicableCalendars: ["chinese"],
                        trustLevel: .community,
                        provider: "GitHub Community",
                        tags: ["festival", "cultural"],
                        iconName: "sparkles",
                        updateFrequency: "Yearly"
                    )
                ],
                onSubscribe: { _ in },
                onDismiss: {},
                onDismissForever: {}
            )
        }
    }
    .frame(width: 600, height: 400)
}
