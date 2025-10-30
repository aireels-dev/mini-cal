//
//  MenuBarController.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Cocoa
import SwiftUI
import Combine

class MenuBarController: NSObject {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var menuBarViewModel: MenuBarViewModel!
    private var menuBarHostingView: NSHostingController<MenuBarView>?
    private var settingsWindow: NSWindow?
    private var settingsManager = SettingsManager.shared
    private var hoverTimer: Timer?
    private var mouseMonitor: Any?
    private var localMouseMonitor: Any?
    private var isMouseInside = false
    private var contextMenu: NSMenu!
    private var cancellables = Set<AnyCancellable>()

    override init() {
        super.init()
        setupViewModel()
        setupMenuBar()
        setupPopover()
        setupContextMenu()
        observeSettingsChanges()
    }

    private func setupViewModel() {
        menuBarViewModel = MenuBarViewModel()
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
        var calendarView = CalendarView()
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
                showPopover()
            }
        }
    }

    func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    func closePopover() {
        popover.close()
    }

    // MARK: - Settings Window

    @objc func openSettings() {
        if let window = settingsWindow {
            // 如果窗口已存在，激活并前置
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        } else {
            // 创建新的设置窗口
            let settingsView = SettingsView()
            let hostingController = NSHostingController(rootView: settingsView)

            let window = NSWindow(contentViewController: hostingController)
            window.title = "MiniCal 设置"
            window.styleMask = [.titled, .closable, .miniaturizable]
            window.center()
            window.setFrameAutosaveName("SettingsWindow")
            window.isReleasedWhenClosed = false

            // 添加快捷键支持
            window.makeFirstResponder(hostingController.view)

            settingsWindow = window
            window.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
        }

        // 关闭弹窗
        closePopover()
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
            self?.showPopover()
        }
    }

    @objc func handleMouseExited() {
        // 取消定时器，防止鼠标离开后仍然显示
        hoverTimer?.invalidate()
        hoverTimer = nil
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

        Logger.debug("MenuBarController deinitialized", category: Logger.app)
    }
}
