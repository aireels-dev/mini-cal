//
//  MenuBarController.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Cocoa
import SwiftUI
import Combine

class MenuBarController: NSObject, NSWindowDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarViewModel: MenuBarViewModel!
    private var calendarViewModel: CalendarViewModel!  // 日历视图模型
    private var menuBarHostingView: NSHostingController<MenuBarView>?
    private var settingsWindow: NSWindow?
    private var onboardingWindow: NSWindow?  // 首次启动向导窗口
    private var settingsManager = SettingsManager.shared
    private var hoverTimer: Timer?
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var isMouseInside = false
    private var contextMenu: NSMenu!
    private var cancellables = Set<AnyCancellable>()
    private var autoCloseTimer: Timer?
    private var isThemePreviewMode = false  // 标记是否处于主题预览模式

    // 同步服务
    private let subscriptionService: CalendarSubscriptionService
    private let syncStatusMonitor: SyncStatusMonitor
    private var autoSyncTimer: Timer?

    // 推荐服务
    private let recommendationService = SubscriptionRecommendationService.shared

    override init() {
        self.subscriptionService = CalendarSubscriptionService()
        self.syncStatusMonitor = SyncStatusMonitor()
        super.init()
        setupViewModel()
        setupMenuBar()
        setupPopover()
        setupContextMenu()
        observeSettingsChanges()
        observeThemePreview()
        setupAutoSync()
        observeOnboardingRequest()

        // 检查是否需要显示首次启动向导
        checkOnboardingStatus()
    }

    private func setupViewModel() {
        menuBarViewModel = MenuBarViewModel()
        calendarViewModel = CalendarViewModel()
    }

    private func setupMenuBar() {
        // Create status bar item
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            // Set initial title from ViewModel
            updateMenuBarTitle()

            button.action = #selector(togglePopover)
            button.target = self

            // 支持右键点击
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])

            // 设置鼠标移动监听以支持悬浮
            setupMouseTracking()

            // Observe ViewModel changes to update menu bar title
            observeViewModelChanges()
        }
    }

    private func setupMouseTracking() {
        // 监听鼠标移动事件
        mouseMonitor = NSEvent.addGlobalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkMousePosition()
        }

        // 也监听本地鼠标移动事件（保存返回值以便清理）
        localMouseMonitor = NSEvent.addLocalMonitorForEvents(matching: .mouseMoved) { [weak self] event in
            self?.checkMousePosition()
            return event
        }
    }

    private func checkMousePosition() {
        guard let button = statusItem.button else { return }

        // 获取鼠标位置
        let mouseLocation = NSEvent.mouseLocation
        let buttonFrame = button.window?.convertToScreen(button.convert(button.bounds, to: nil)) ?? .zero

        // 检查鼠标是否在按钮区域内
        let isInside = buttonFrame.contains(mouseLocation)

        if isInside && !isMouseInside {
            // 鼠标进入
            isMouseInside = true
            handleMouseEntered()
        } else if !isInside && isMouseInside {
            // 鼠标离开
            isMouseInside = false
            handleMouseExited()
        }
    }

    // MARK: - Context Menu

    private func setupContextMenu() {
        let menu = NSMenu()

        // 设置菜单项
        let settingsItem = NSMenuItem(
            title: "设置...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        // 检查更新菜单项
        let checkUpdateItem = NSMenuItem(
            title: "检查更新...",
            action: #selector(checkForUpdates),
            keyEquivalent: ""
        )
        checkUpdateItem.target = self
        menu.addItem(checkUpdateItem)

        // 关于菜单项
        let aboutItem = NSMenuItem(
            title: "关于 MiniCal",
            action: #selector(showAbout),
            keyEquivalent: ""
        )
        aboutItem.target = self
        menu.addItem(aboutItem)

        menu.addItem(NSMenuItem.separator())

        // 退出菜单项
        let quitItem = NSMenuItem(
            title: "退出 MiniCal",
            action: #selector(quitApp),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        // 不将菜单附加到 statusItem，而是保存引用供右键点击时使用
        contextMenu = menu
    }

    private func setupPopover() {
        // Create popover with calendar view
        popover = NSPopover()

        // 使用当前设置的日历尺寸
        let calendarSize = settingsManager.currentSettings.calendarSize
        popover.contentSize = NSSize(width: calendarSize.width, height: calendarSize.height)
        popover.behavior = .transient

        // Set calendar view as popover content with settings action
        var calendarView = CalendarView(viewModel: calendarViewModel)
        calendarView.openSettingsAction = { [weak self] in
            self?.openSettings()
        }
        let hostingController = NSHostingController(rootView: calendarView)
        popover.contentViewController = hostingController
    }

    private func observeSettingsChanges() {
        // 监听设置变更，更新 popover 尺寸
        settingsManager.$currentSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                guard let self = self else { return }
                let calendarSize = settings.calendarSize
                self.popover.contentSize = NSSize(width: calendarSize.width, height: calendarSize.height)
            }
            .store(in: &cancellables)
    }

    private func observeThemePreview() {
        // 监听主题预览通知
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleThemePreview),
            name: .themePreviewRequested,
            object: nil
        )
    }

    private func observeOnboardingRequest() {
        // 监听引导显示请求通知（从设置页面触发）
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(showOnboardingWizard),
            name: .showOnboardingRequested,
            object: nil
        )
    }

    private func updateMenuBarTitle() {
        if let button = statusItem.button {
            button.title = menuBarViewModel.displayText
        }
    }

    private func observeViewModelChanges() {
        // Observe displayText changes and update immediately
        menuBarViewModel.$displayText
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newText in
                guard let self = self else { return }
                Logger.debug("MenuBar displayText changed to: \(newText)", category: Logger.ui)
                self.updateMenuBarTitle()
            }
            .store(in: &menuBarViewModel.cancellables)
    }

    @objc func togglePopover(_ sender: Any?) {
        // 检查是否为右键点击
        if let event = NSApp.currentEvent, event.type == .rightMouseUp {
            // 取消悬浮定时器
            hoverTimer?.invalidate()
            hoverTimer = nil

            // 关闭可能已打开的弹窗
            closePopover()

            // 右键点击通过编程方式显示菜单，不附加到 statusItem
            if let button = statusItem.button {
                contextMenu.popUp(positioning: nil, at: NSPoint(x: 0, y: button.bounds.height), in: button)
            }
        } else {
            // 取消悬浮定时器
            hoverTimer?.invalidate()
            hoverTimer = nil

            // 左键点击切换弹窗
            if popover.isShown {
                closePopover()
            } else {
                // 正常显示（非预览模式）
                popover.behavior = .transient
                showPopover()
            }
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }

        // 重置日历视图到今天
        resetCalendarViewToToday()

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // 激活应用并使浮窗获得焦点
        NSApp.activate(ignoringOtherApps: true)

        // 确保 popover 的内容视图成为 first responder
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let contentViewController = self.popover.contentViewController {
                contentViewController.view.window?.makeKey()
            }
        }
    }

    /// 重置日历视图到今天
    private func resetCalendarViewToToday() {
        // 发送通知以重置日历视图到今天
        NotificationCenter.default.post(name: .resetCalendarToToday, object: nil)
    }

    func closePopover() {
        popover.close()
        // 清除自动关闭定时器
        cancelAutoCloseTimer()

        // 退出主题预览模式，恢复默认行为
        if isThemePreviewMode {
            isThemePreviewMode = false
            popover.behavior = .transient
            Logger.debug("Exited preview mode, restored transient behavior", category: Logger.ui)
        }
    }

    // MARK: - Theme Preview

    @objc private func handleThemePreview() {
        // 进入主题预览模式
        isThemePreviewMode = true

        // 收到主题预览请求
        if popover.isShown {
            // 如果浮窗已显示，重置定时器（延长显示时间）
            Logger.debug("Calendar already shown, refreshing timer", category: Logger.ui)
            startAutoCloseTimer()
        } else {
            // 如果浮窗未显示，显示浮窗
            showPopoverForPreview()
            startAutoCloseTimer()
        }
    }

    private func showPopoverForPreview() {
        guard let button = statusItem.button else { return }

        // 设置为 applicationDefined 模式，防止点击其他窗口时自动关闭
        popover.behavior = .applicationDefined

        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)

        // 激活应用并使浮窗获得焦点
        NSApp.activate(ignoringOtherApps: true)

        // 确保 popover 的内容视图成为 first responder
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            if let contentViewController = self.popover.contentViewController {
                contentViewController.view.window?.makeKey()
            }
        }

        Logger.debug("Popover shown in preview mode with applicationDefined behavior", category: Logger.ui)
    }

    private func startAutoCloseTimer() {
        // 取消之前的定时器
        cancelAutoCloseTimer()

        // 创建5秒定时器
        autoCloseTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: false) { [weak self] _ in
            Logger.debug("Auto-closing calendar preview after 5 seconds", category: Logger.ui)
            self?.closePopover()
        }

        Logger.debug("Started 5-second auto-close timer for theme preview", category: Logger.ui)
    }

    private func cancelAutoCloseTimer() {
        autoCloseTimer?.invalidate()
        autoCloseTimer = nil
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        // 确保在主线程执行
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }

            if let window = self.settingsWindow, window.isVisible {
                // 如果窗口已存在且可见，恢复最小化状态并激活前置
                if window.isMiniaturized {
                    window.deminiaturize(nil)
                }

                // 获取鼠标所在屏幕，确保窗口显示在该屏幕
                if let mouseScreen = NSScreen.main {
                    // 如果窗口不在鼠标所在屏幕，移动到该屏幕中央
                    if let windowScreen = window.screen, windowScreen != mouseScreen {
                        let screenFrame = mouseScreen.visibleFrame
                        let windowFrame = window.frame
                        let x = screenFrame.midX - windowFrame.width / 2
                        let y = screenFrame.midY - windowFrame.height / 2
                        window.setFrameOrigin(NSPoint(x: x, y: y))
                    }
                }

                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)

                Logger.info("Settings window activated and brought to front", category: Logger.app)
            } else {
                // 窗口不存在或不可见，创建新窗口
                self.settingsWindow = nil  // 清理旧引用

                Logger.info("Creating new settings window", category: Logger.app)

                let settingsView = SettingsView(calendarViewModel: self.calendarViewModel)
                let hostingController = NSHostingController(rootView: settingsView)

                let window = NSWindow(contentViewController: hostingController)
                window.title = NSLocalizedString("settings.window_title", comment: "")
                window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                window.isReleasedWhenClosed = false

                // 设置窗口最小尺寸，避免尺寸异常
                window.minSize = NSSize(width: 600, height: 400)
                window.setContentSize(NSSize(width: 800, height: 600))

                // 在鼠标所在屏幕居中
                if let mouseScreen = NSScreen.main {
                    let screenFrame = mouseScreen.visibleFrame
                    let windowSize = window.frame.size
                    let x = screenFrame.midX - windowSize.width / 2
                    let y = screenFrame.midY - windowSize.height / 2
                    window.setFrameOrigin(NSPoint(x: x, y: y))
                } else {
                    window.center()
                }

                window.setFrameAutosaveName("SettingsWindow")
                window.delegate = self  // 设置委托，监听窗口关闭事件

                // 添加快捷键支持
                window.makeFirstResponder(hostingController.view)

                self.settingsWindow = window
                window.makeKeyAndOrderFront(nil)
                NSApp.activate(ignoringOtherApps: true)

                Logger.info("New settings window created and displayed", category: Logger.app)
            }

            // 关闭弹窗
            self.closePopover()
        }
    }

    @objc func checkForUpdates() {
        Logger.info("Checking for updates", category: Logger.app)

        AppVersion.checkForUpdates { hasUpdate, latestVersion, error in
            let alert = NSAlert()

            if let error = error {
                alert.messageText = "检查更新失败"
                alert.informativeText = error.localizedDescription
                alert.alertStyle = .warning
            } else if hasUpdate, let version = latestVersion {
                alert.messageText = "发现新版本"
                alert.informativeText = "最新版本 \(version) 已可用。当前版本为 \(AppVersion.version)。"
                alert.addButton(withTitle: "稍后提醒")
                alert.alertStyle = .informational
            } else {
                alert.messageText = "已是最新版本"
                alert.informativeText = "当前版本 \(AppVersion.fullVersion) 已是最新版本。"
                alert.alertStyle = .informational
            }

            alert.addButton(withTitle: "确定")
            alert.runModal()
        }

        closePopover()
    }

    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = AppVersion.appName
        alert.informativeText = """
        版本 \(AppVersion.fullVersion)

        一款简洁优雅的macOS菜单栏日历应用

        © 2025 MiniCal
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "确定")

        Logger.info("Showing about window", category: Logger.app)
        alert.runModal()

        closePopover()
    }

    @objc func quitApp() {
        NSApp.terminate(nil)
    }

    // MARK: - Mouse Tracking

    @objc func handleMouseEntered() {
        // 取消之前的定时器
        hoverTimer?.invalidate()

        // 检查是否启用悬浮显示
        guard settingsManager.currentSettings.hoverToShowEnabled else { return }

        // 如果弹窗已经显示，不需要再次显示
        guard !popover.isShown else { return }

        // 创建新的定时器
        let delay = settingsManager.currentSettings.hoverDelay
        hoverTimer = Timer.scheduledTimer(withTimeInterval: delay, repeats: false) { [weak self] _ in
            guard let self = self else { return }
            // 悬浮显示使用正常模式
            self.popover.behavior = .transient
            self.showPopover()
        }
    }

    @objc func handleMouseExited() {
        // 取消定时器，防止鼠标离开后仍然显示
        hoverTimer?.invalidate()
        hoverTimer = nil
    }

    // MARK: - Auto Sync

    private func setupAutoSync() {
        // 监听应用启动和前后台切换
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillResignActive),
            name: NSApplication.willResignActiveNotification,
            object: nil
        )

        // 设置定期同步
        setupPeriodicSync()

        // 应用启动时执行一次同步
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            Task {
                await self.performInitialSync()
            }
        }
    }

    @objc private func appDidBecomeActive() {
        Logger.info("App became active, checking sync status", category: Logger.app)

        // 应用激活时检查是否需要同步
        Task {
            await performSyncIfNeeded()
        }
    }

    @objc private func appWillResignActive() {
        Logger.info("App will resign active", category: Logger.app)

        // 应用即将失去焦点时停止自动同步定时器
        autoSyncTimer?.invalidate()
        autoSyncTimer = nil
    }

    private func setupPeriodicSync() {
        // 每30分钟自动同步一次
        autoSyncTimer = Timer.scheduledTimer(withTimeInterval: 30 * 60, repeats: true) { [weak self] _ in
            Task {
                await self?.performPeriodicSync()
            }
        }
    }

    private func performInitialSync() async {
        Logger.info("Performing initial sync", category: Logger.app)

        let permissionManager = PermissionManager.shared

        // 使用智能权限请求策略
        if permissionManager.shouldRequestPermission() {
            Logger.info("Requesting calendar permission", category: Logger.app)
            let granted = await permissionManager.requestEventKitAccess()

            if !granted {
                Logger.info("Calendar permission denied or restricted", category: Logger.app)
                Logger.info("Will request again after 30 days", category: Logger.app)
                return
            }

            Logger.info("Calendar permission granted", category: Logger.app)
        } else if !permissionManager.isAuthorized {
            Logger.info("Calendar permission previously denied, waiting for cooldown period", category: Logger.app)
            if let lastRequestDate = permissionManager.getLastPermissionRequestDate() {
                let calendar = Calendar.current
                let daysSinceLastRequest = calendar.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
                let daysRemaining = max(0, 30 - daysSinceLastRequest)
                Logger.info("Will request permission again in \(daysRemaining) days", category: Logger.app)
            }
            return
        }

        // 如果已授权,执行同步
        do {
            try await subscriptionService.refreshAllSubscriptions()
            Logger.info("Initial sync completed", category: Logger.app)
        } catch {
            Logger.error("Initial sync failed: \(error)", category: Logger.app)
        }
    }

    private func performSyncIfNeeded() async {
        // 检查距离上次同步的时间
        let syncInterval: TimeInterval = 5 * 60 // 5分钟

        // 如果距离上次同步超过syncInterval，则执行同步
        if shouldPerformSync(syncInterval: syncInterval) {
            await performPeriodicSync()
        }
    }

    private func performPeriodicSync() async {
        Logger.info("Performing periodic sync", category: Logger.app)

        do {
            try await subscriptionService.refreshAllSubscriptions()
            Logger.info("Periodic sync completed", category: Logger.app)
        } catch {
            Logger.error("Periodic sync failed: \(error)", category: Logger.app)
        }
    }

    private func shouldPerformSync(syncInterval: TimeInterval) -> Bool {
        // 简化实现，实际应该检查上次同步时间
        // 这里可以根据SyncStatusMonitor的指标来决定
        let lastSyncDate = syncStatusMonitor.syncMetrics.lastSyncDate
        let timeSinceLastSync = Date().timeIntervalSince(lastSyncDate)

        return timeSinceLastSync >= syncInterval
    }

    // MARK: - Onboarding

    /// 检查首次启动状态
    private func checkOnboardingStatus() {
        // 延迟检查，确保应用完全启动
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }

            if self.recommendationService.shouldShowOnboarding() {
                Logger.info("First launch detected, showing onboarding wizard", category: Logger.app)
                self.showOnboardingWizard()
            } else {
                // 重置会话拒绝记录（新会话开始）
                self.recommendationService.resetSessionDismissals()
            }
        }
    }

    /// 显示首次启动向导（公开方法，可从设置或菜单调用）
    @objc func showOnboardingWizard() {
        // 如果窗口已经显示，直接激活
        if let window = onboardingWindow, window.isVisible {
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            Logger.info("Onboarding wizard already visible, bringing to front", category: Logger.app)
            return
        }

        // 清理旧窗口引用（不调用 close()，让它自然销毁）
        onboardingWindow = nil

        // 创建向导视图
        let onboardingView = OnboardingWizardView()
        let hostingController = NSHostingController(rootView: onboardingView)

        // 创建窗口
        let window = NSWindow(contentViewController: hostingController)
        window.title = NSLocalizedString("onboarding.window_title", comment: "")
        window.styleMask = [.titled, .closable]
        window.center()
        window.isReleasedWhenClosed = false  // 不自动释放，由我们手动管理
        window.level = .floating  // 确保窗口在最前面
        window.delegate = self  // 设置委托，监听窗口关闭事件

        // 保存窗口引用
        onboardingWindow = window

        // 显示窗口
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)

        Logger.info("Onboarding wizard shown", category: Logger.app)
    }

    // MARK: - NSWindowDelegate

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow else { return }

        // 监听引导窗口关闭事件，清理引用
        if window == onboardingWindow {
            Logger.info("Onboarding wizard window closing, cleaning up reference", category: Logger.app)
            onboardingWindow = nil
        }

        // 监听设置窗口关闭事件，清理引用
        if window == settingsWindow {
            Logger.info("Settings window closing, cleaning up reference", category: Logger.app)
            settingsWindow = nil
        }
    }

    // MARK: - Cleanup

    deinit {
        // 清理鼠标事件监听
        if let monitor = mouseMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localMouseMonitor {
            NSEvent.removeMonitor(monitor)
        }

        // 清理定时器
        hoverTimer?.invalidate()
        autoSyncTimer?.invalidate()

        // 移除通知观察者
        NotificationCenter.default.removeObserver(self)

        Logger.debug("MenuBarController deinitialized", category: Logger.app)
    }
}
