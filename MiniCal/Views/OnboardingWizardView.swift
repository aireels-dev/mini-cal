//
//  OnboardingWizardView.swift
//  MiniCal
//
//  Created by MiniCal on 2025-12-17.
//

import SwiftUI

/// 首次启动向导视图
struct OnboardingWizardView: View {
    // MARK: - Environment

    @Environment(\.dismiss) private var dismiss

    // MARK: - State

    @State private var currentStep: OnboardingStep = .welcome
    @State private var selectedCalendar: CalendarType? = nil  // nil 表示"无"
    @State private var selectedRecommendations: Set<String> = []
    @State private var showingSecurityAlert = false
    @State private var pendingSubscription: RecommendedSubscription?
    @State private var localThemeMode: ThemeMode = .auto
    @State private var existingSubscriptions: [CalendarSubscription] = []

    // MARK: - Services

    @StateObject private var recommendationService = SubscriptionRecommendationService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var settingsManager = SettingsManager.shared

    // MARK: - Environment

    @Environment(\.colorScheme) private var colorScheme

    private var isSystemDarkMode: Bool {
        colorScheme == .dark
    }

    // MARK: - Computed Properties

    private var recommendations: [RecommendedSubscription] {
        // 如果未选择日历（选择"无"），返回空数组
        guard let calendar = selectedCalendar else {
            return []
        }
        // 引导流程中获取推荐时，传入空地区参数强制显示所有适用该日历的推荐（不过滤地区）
        return recommendationService.getRecommendations(
            for: calendar,
            region: "",  // 空字符串表示跳过地区过滤
            excludeDismissed: false,
            limit: 5
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // 顶部进度指示器
            progressIndicator
                .padding(.top, 20)
                .padding(.bottom, 16)  // 添加底部间距，确保与滚动内容有分隔

            // 内容区域
            ScrollView {
                VStack(spacing: 24) {
                    switch currentStep {
                    case .welcome:
                        welcomeStep
                    case .selectTheme:
                        selectThemeStep
                    case .selectCalendarAndRecommendations:
                        selectCalendarAndRecommendationsStep
                    case .complete:
                        completeStep
                    }
                }
                .padding(32)
                .padding(.top, 8)  // 顶部额外间距，防止被指示器遮挡
            }

            // 底部按钮
            Divider()  // 添加分隔线，明确区分滚动区域和按钮区域

            bottomButtons
                .padding(.horizontal, 32)
                .padding(.vertical, 16)  // 上下对称的间距
        }
        .frame(width: 660, height: 580)  // 减小 15% (原 700x650)
        .background(Color(nsColor: .windowBackgroundColor))
        .alert("recommendation.security_alert.title".localized(), isPresented: $showingSecurityAlert) {
            securityAlertButtons
        } message: {
            securityAlertMessage
        }
        .onAppear {
            // 每次显示时重置到第一页
            currentStep = .welcome
            selectedRecommendations.removeAll()
            // 初始化主题模式
            localThemeMode = settingsManager.currentSettings.themeMode
            // 同步系统设置中的副历类型（初始显示值应与系统设置一致）
            selectedCalendar = settingsManager.currentSettings.secondaryCalendarType
            // 加载现有订阅列表
            loadExistingSubscriptions()
        }
    }

    // MARK: - Subviews

    /// 进度指示器
    private var progressIndicator: some View {
        HStack(spacing: 12) {
            ForEach(OnboardingStep.allCases, id: \.self) { step in
                Circle()
                    .fill(step.rawValue <= currentStep.rawValue ? Color.accentColor : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.accentColor, lineWidth: step == currentStep ? 2 : 0)
                            .frame(width: 12, height: 12)
                    )
            }
        }
    }

    /// 欢迎步骤
    private var welcomeStep: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.circle.fill")
                .font(.system(size: 80))
                .foregroundColor(.accentColor)

            Text("onboarding.welcome.title".localized(with: AppBrand.displayName))
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("onboarding.welcome.subtitle".localized())
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Divider()
                .padding(.vertical, 20)

            VStack(alignment: .leading, spacing: 12) {
                featureRow(icon: "globe", title: "onboarding.feature.multicultural".localized())
                featureRow(icon: "arrow.triangle.2.circlepath", title: "onboarding.feature.sync".localized())
                featureRow(icon: "paintpalette.fill", title: "onboarding.feature.themes".localized())
            }
        }
    }

    /// 功能行
    private func featureRow(icon: String, title: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundColor(.accentColor)
                .frame(width: 24)

            Text(title)
                .font(.body)

            Spacer()
        }
    }

    /// 主题选择步骤
    private var selectThemeStep: some View {
        VStack(spacing: 12) {
            Text("onboarding.theme.title".localized())
                .font(.title)
                .fontWeight(.bold)

            Text("onboarding.theme.subtitle".localized())
                .font(.callout)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)

            Divider()
                .padding(.vertical, 4)

            // 主题模式选择
            HStack(spacing: 8) {
                ForEach(ThemeMode.allCases, id: \.self) { mode in
                    ThemeModeButton(
                        mode: mode,
                        isSelected: localThemeMode == mode,
                        action: {
                            localThemeMode = mode
                            themeManager.setThemeMode(mode)
                        }
                    )
                }
            }

            // 主题网格 - 根据模式和系统外观动态显示（引导页面使用 4 列横向铺满布局）
            if localThemeMode == .light {
                // 浅色模式：仅显示浅色主题
                OnboardingThemeGrid(
                    themes: themeManager.lightThemes,
                    selectedThemeId: themeManager.currentLightTheme.id,
                    onThemeSelect: { theme in
                        handleThemeSelection(theme)
                    }
                )
            } else if localThemeMode == .dark {
                // 深色模式：仅显示深色主题
                OnboardingThemeGrid(
                    themes: themeManager.darkThemes,
                    selectedThemeId: themeManager.currentDarkTheme.id,
                    onThemeSelect: { theme in
                        handleThemeSelection(theme)
                    }
                )
            } else {
                // 自动模式：根据当前系统外观显示对应主题
                if isSystemDarkMode {
                    OnboardingThemeGrid(
                        themes: themeManager.darkThemes,
                        selectedThemeId: themeManager.currentDarkTheme.id,
                        onThemeSelect: { theme in
                            handleThemeSelection(theme)
                        }
                    )
                } else {
                    OnboardingThemeGrid(
                        themes: themeManager.lightThemes,
                        selectedThemeId: themeManager.currentLightTheme.id,
                        onThemeSelect: { theme in
                            handleThemeSelection(theme)
                        }
                    )
                }

                // 自动模式提示
                Text("settings.theme_auto_switch".localized())
                    .font(.caption)
                    .foregroundColor(.blue)
                    .padding(.top, 4)
            }
        }
    }

    /// 选择日历和推荐步骤（合并）
    private var selectCalendarAndRecommendationsStep: some View {
        VStack(spacing: 16) {
            // 日历选择部分
            VStack(spacing: 8) {
                Text("onboarding.select_local_calendar.title".localized())
                    .font(.title2)
                    .fontWeight(.bold)

                // 下拉选择器（添加"无"选项）
                Picker("", selection: $selectedCalendar) {
                    // "无"选项
                    Text("calendar.none".localized()).tag(nil as CalendarType?)

                    // 其他日历类型（排除公历）
                    ForEach(CalendarType.allCases.filter { $0 != .gregorian }, id: \.self) { calendar in
                        Text(calendar.displayName).tag(calendar as CalendarType?)
                    }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: 300)
                .padding(.vertical, 6)

                Text("onboarding.select_local_calendar.description".localized())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Divider()
                .padding(.vertical, 8)

            // 推荐订阅部分
            VStack(spacing: 12) {
                if recommendations.isEmpty {
                    // 无推荐时显示提示
                    VStack(spacing: 12) {
                        Image(systemName: "tray")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary)

                        Text("onboarding.recommendations.empty".localized())
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                } else {
                    // 有推荐时显示标题和列表
                    Text("onboarding.recommendations.title".localized())
                        .font(.headline)

                    Text("onboarding.recommendations.subtitle".localized())
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 12) {
                        ForEach(recommendations.prefix(5)) { recommendation in
                            RecommendationSourceCell(
                                recommendation: recommendation,
                                isSelected: selectedRecommendations.contains(recommendation.id),
                                isSubscribed: isRecommendationSubscribed(recommendation),
                                onSelect: {
                                    handleRecommendationSelect(recommendation)
                                },
                                onDismiss: {
                                    recommendationService.dismissRecommendationPermanently(recommendation.id)
                                }
                            )
                        }
                    }
                }
            }
        }
    }

    /// 完成步骤
    private var completeStep: some View {
        VStack(spacing: 24) {
            // 表头：图标和标题横向排列（整体居中）
            HStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.green)
                    .symbolRenderingMode(.hierarchical)

                VStack(alignment: .leading, spacing: 6) {
                    Text("onboarding.complete.title".localized())
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)

                    Text("onboarding.complete.subtitle".localized(with: AppBrand.displayName))
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.horizontal, 8)
            .padding(.vertical, 8)

            // 优化建议卡片
            optimizationTipCard
                .padding(.top, 8)
        }
    }

    /// 优化建议卡片（纵向布局，步骤横向排列）
    private var optimizationTipCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            optimizationTitleSection
            optimizationBenefitsSection
            optimizationStepsDivider
            optimizationStepsSection
            optimizationSettingsButton
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }

    // MARK: - Optimization Card Sections

    /// 优化建议标题区域
    private var optimizationTitleSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("onboarding.optimize.title".localized())
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)

            Text("onboarding.optimize.intro".localized(with: AppBrand.displayName))
                .font(.system(size: 12))
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1)
        }
    }

    /// 优化建议优势列表
    private var optimizationBenefitsSection: some View {
        HStack(alignment: .top, spacing: 12) {
            benefitRow(icon: "square.stack.3d.up", text: "onboarding.optimize.benefit_1".localized())
                .frame(maxWidth: .infinity, alignment: .leading)

            benefitRow(icon: "hand.tap.fill", text: "onboarding.optimize.benefit_2".localized())
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.accentColor.opacity(0.06))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.accentColor.opacity(0.15), lineWidth: 1)
        )
    }

    /// 步骤说明分隔线
    private var optimizationStepsDivider: some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
            Text("设置步骤")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.secondary)
            Rectangle()
                .fill(Color.secondary.opacity(0.3))
                .frame(height: 1)
        }
        .padding(.top, 4)
    }

    /// 步骤卡片区域（固定等高）
    private var optimizationStepsSection: some View {
        HStack(alignment: .top, spacing: 16) {
            // 步骤 1
            VStack(alignment: .leading, spacing: 12) {
                // 步骤编号和标题
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                        Text("1")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)

                    Text("onboarding.optimize.step1_title".localized())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 步骤详情
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("onboarding.optimize.step1_detail1".localized())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("onboarding.optimize.step1_detail2".localized())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
                .padding(.leading, 4)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )

            // 步骤 2
            VStack(alignment: .leading, spacing: 12) {
                // 步骤编号和标题
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.accentColor)
                        Text("2")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(width: 28, height: 28)

                    Text("onboarding.optimize.step2_title".localized(with: AppBrand.displayName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                // 步骤详情
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("onboarding.optimize.step2_detail1".localized())
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text("onboarding.optimize.step2_detail2".localized(with: AppBrand.displayName))
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
                .padding(.leading, 4)

                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 120, maxHeight: 120, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
            )
        }
    }

    /// 跳转系统设置按钮
    private var optimizationSettingsButton: some View {
        Button(action: openSystemSettings) {
            HStack(spacing: 6) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 12))
                Text("onboarding.optimize.open_settings".localized())
                    .font(.system(size: 13, weight: .medium))
            }
            .foregroundColor(.accentColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.1))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(Color.accentColor.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, -6)
    }

    /// 优势行
    private func benefitRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.accentColor)
                .frame(width: 18, alignment: .center)
                .symbolRenderingMode(.hierarchical)

            Text(text)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .lineSpacing(1)
        }
    }

    /// 步骤卡片（单个步骤的卡片样式）
    private func stepCard(number: String, title: String, details: [String]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // 步骤编号和标题
            HStack(spacing: 10) {
                // 圆形数字徽章
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                    Text(number)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
                .frame(width: 28, height: 28)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // 步骤详情
            VStack(alignment: .leading, spacing: 6) {
                ForEach(details, id: \.self) { detail in
                    HStack(alignment: .top, spacing: 6) {
                        Text("•")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                        Text(detail)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .lineSpacing(2)
                    }
                }
            }
            .padding(.leading, 4)

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(nsColor: .controlBackgroundColor).opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .strokeBorder(Color.primary.opacity(0.12), lineWidth: 1)
        )
    }

    /// 打开系统设置（兼容不同 macOS 版本）
    private func openSystemSettings() {
        // macOS 13+ 使用新的 Settings.app
        // macOS 12 及以下使用旧的 System Preferences.app

        if #available(macOS 13.0, *) {
            // macOS 13 Ventura 及以后：打开设置 App 的控制中心面板
            // 注意：macOS 13+ 改用 com.apple.Settings 而非 com.apple.systempreferences
            if let url = URL(string: "x-apple.systempreferences:com.apple.ControlCenter-Settings.extension") {
                NSWorkspace.shared.open(url)
                Logger.info("Opening System Settings (macOS 13+): Control Center", category: Logger.app)
            } else {
                // Fallback: 打开设置 App 主页面
                openSettingsAppFallback()
            }
        } else {
            // macOS 12 Monterey 及以下：使用旧的 URL scheme
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.dock") {
                NSWorkspace.shared.open(url)
                Logger.info("Opening System Preferences (macOS 12-): Dock & Menu Bar", category: Logger.app)
            } else {
                // Fallback: 打开系统偏好设置主页面
                openSystemPreferencesFallback()
            }
        }
    }

    /// Fallback: 打开设置 App 主页面（macOS 13+）
    private func openSettingsAppFallback() {
        if let url = URL(string: "x-apple.systempreferences:") {
            NSWorkspace.shared.open(url)
            Logger.info("Fallback: Opening System Settings main page", category: Logger.app)
        } else {
            // 最终 Fallback: 使用 Bundle Identifier 直接打开（使用新 API）
            if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
                let configuration = NSWorkspace.OpenConfiguration()
                NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
                    if let error = error {
                        Logger.error("Failed to open Settings app: \(error)", category: Logger.app)
                    } else {
                        Logger.info("Opened Settings app via bundle identifier", category: Logger.app)
                    }
                }
            } else {
                Logger.error("Could not find Settings app", category: Logger.app)
            }
        }
    }

    /// Fallback: 打开系统偏好设置主页面（macOS 12-）
    private func openSystemPreferencesFallback() {
        if let appURL = NSWorkspace.shared.urlForApplication(withBundleIdentifier: "com.apple.systempreferences") {
            let configuration = NSWorkspace.OpenConfiguration()
            NSWorkspace.shared.openApplication(at: appURL, configuration: configuration) { app, error in
                if let error = error {
                    Logger.error("Failed to open System Preferences: \(error)", category: Logger.app)
                } else {
                    Logger.info("Opened System Preferences via bundle identifier", category: Logger.app)
                }
            }
        } else {
            Logger.error("Could not find System Preferences app", category: Logger.app)
        }
    }

    /// 底部按钮
    private var bottomButtons: some View {
        HStack {
            // 跳过按钮（仅非完成页显示）
            if currentStep != .complete {
                Button("onboarding.skip".localized()) {
                    skipOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            // 稍后设置按钮（仅完成页显示）
            if currentStep == .complete {
                Button("onboarding.optimize.later".localized()) {
                    completeOnboarding()
                }
                .buttonStyle(.plain)
                .foregroundColor(.secondary)
            }

            Spacer()

            // 返回按钮（完成页不显示）
            if currentStep != .welcome && currentStep != .complete {
                Button("onboarding.back".localized()) {
                    previousStep()
                }
            }

            // 下一步/开始使用按钮
            Button(nextButtonTitle) {
                nextStep()
            }
            .buttonStyle(.borderedProminent)
            .disabled(!canProceed)
        }
    }

    /// 安全提示按钮
    @ViewBuilder
    private var securityAlertButtons: some View {
        Button("recommendation.security_alert.cancel".localized(), role: .cancel) {
            pendingSubscription = nil
        }

        Button("recommendation.security_alert.confirm".localized()) {
            if let subscription = pendingSubscription {
                confirmSubscription(subscription)
            }
        }
    }

    /// 安全提示消息
    @ViewBuilder
    private var securityAlertMessage: some View {
        if let subscription = pendingSubscription {
            VStack(alignment: .leading, spacing: 8) {
                Text("recommendation.security_alert.message".localized(with: AppBrand.displayName))

                Text("URL: \(subscription.url)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    // MARK: - Computed Properties

    /// 下一步按钮标题
    private var nextButtonTitle: String {
        switch currentStep {
        case .welcome, .selectTheme:
            return "onboarding.next".localized()
        case .selectCalendarAndRecommendations:
            // 无推荐时显示"下一步"，有推荐时根据是否选择显示不同文本
            if recommendations.isEmpty {
                return "onboarding.next".localized()
            } else {
                return selectedRecommendations.isEmpty ? "onboarding.skip_recommendations".localized() : "onboarding.next".localized()
            }
        case .complete:
            return "onboarding.get_started".localized()
        }
    }

    /// 是否可以继续
    private var canProceed: Bool {
        switch currentStep {
        case .welcome, .complete, .selectTheme, .selectCalendarAndRecommendations:
            return true // 所有步骤都可以继续
        }
    }

    // MARK: - Methods

    /// 加载现有订阅列表
    private func loadExistingSubscriptions() {
        let subscriptionService = CalendarSubscriptionService()
        existingSubscriptions = subscriptionService.subscriptions
    }

    /// 检查推荐是否已订阅
    private func isRecommendationSubscribed(_ recommendation: RecommendedSubscription) -> Bool {
        return existingSubscriptions.contains { subscription in
            subscription.url?.absoluteString == recommendation.url
        }
    }

    /// 下一步
    private func nextStep() {
        switch currentStep {
        case .welcome:
            currentStep = .selectTheme
        case .selectTheme:
            currentStep = .selectCalendarAndRecommendations
        case .selectCalendarAndRecommendations:
            currentStep = .complete
        case .complete:
            completeOnboarding()
        }
    }

    /// 上一步
    private func previousStep() {
        switch currentStep {
        case .welcome:
            break
        case .selectTheme:
            currentStep = .welcome
        case .selectCalendarAndRecommendations:
            currentStep = .selectTheme
        case .complete:
            currentStep = .selectCalendarAndRecommendations
        }
    }

    /// 跳过引导
    private func skipOnboarding() {
        recommendationService.completeOnboarding()
        dismiss()
    }

    /// 完成引导
    private func completeOnboarding() {
        // 保存用户在引导中选择的副历设置
        var updated = settingsManager.currentSettings
        updated.secondaryCalendarType = selectedCalendar
        updated.lastUpdated = Date()
        settingsManager.saveSettings(updated)

        // 标记引导完成
        recommendationService.completeOnboarding()
        dismiss()
    }

    /// 处理推荐选择
    /// 处理主题选择
    private func handleThemeSelection(_ theme: ThemeConfiguration) {
        // 根据主题类别调用不同的设置方法
        if theme.category == .light {
            themeManager.setLightTheme(theme)
        } else {
            themeManager.setDarkTheme(theme)
        }

        // 更新本地设置
        var updated = settingsManager.currentSettings
        if theme.category == .light {
            updated.lightThemeId = theme.id
        } else {
            updated.darkThemeId = theme.id
        }
        updated.lastUpdated = Date()
        settingsManager.saveSettings(updated)

        // 发送主题预览请求通知，触发日历浮窗显示
        NotificationCenter.default.post(name: .themePreviewRequested, object: nil)
    }

    private func handleRecommendationSelect(_ recommendation: RecommendedSubscription) {
        // 如果已选择，取消选择
        if selectedRecommendations.contains(recommendation.id) {
            selectedRecommendations.remove(recommendation.id)
            return
        }

        // 非官方验证源（community 和 unverified）需要安全确认
        if recommendation.trustLevel != .verified {
            pendingSubscription = recommendation
            showingSecurityAlert = true
        } else {
            // 官方验证源直接订阅（引导流程中不标记已显示，避免冷却期过滤）
            selectedRecommendations.insert(recommendation.id)
            Task {
                try? await recommendationService.subscribe(recommendation, userConfirmed: false, markAsShown: false)
            }
        }
    }

    /// 确认订阅
    private func confirmSubscription(_ recommendation: RecommendedSubscription) {
        selectedRecommendations.insert(recommendation.id)
        Task {
            // 引导流程中不标记已显示，避免冷却期过滤
            try? await recommendationService.subscribe(recommendation, userConfirmed: true, markAsShown: false)
        }
        pendingSubscription = nil
    }
}

// MARK: - Onboarding Step

enum OnboardingStep: Int, CaseIterable {
    case welcome = 0
    case selectTheme = 1
    case selectCalendarAndRecommendations = 2
    case complete = 3
}

// MARK: - Onboarding Theme Grid

/// 引导页面专用主题网格（4 列横向铺满布局）
struct OnboardingThemeGrid: View {
    let themes: [ThemeConfiguration]
    let selectedThemeId: String
    let onThemeSelect: (ThemeConfiguration) -> Void

    var body: some View {
        // 4 列自适应布局，横向铺满
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 4),
            spacing: 12
        ) {
            ForEach(themes, id: \.id) { theme in
                ThemeCard(
                    theme: theme,
                    isSelected: theme.id == selectedThemeId,
                    onTap: { onThemeSelect(theme) }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingWizardView()
}
