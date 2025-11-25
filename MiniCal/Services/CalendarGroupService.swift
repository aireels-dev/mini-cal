//
//  CalendarGroupService.swift
//  MiniCal
//
//  日历组服务 - 统一管理所有日历组（系统/外部/本地）
//  提供组属性查询，包括颜色、标题等
//

import Foundation
import SwiftUI
import Combine
import EventKit

/// 日历组服务 - 单例模式
class CalendarGroupService: ObservableObject {
    static let shared = CalendarGroupService()

    // MARK: - Published Properties

    @Published private(set) var systemCalendarGroups: [UUID: EventColor] = [:]
    @Published private(set) var externalSubscriptionGroups: [UUID: EventColor] = [:]

    // MARK: - Dependencies

    private let permissionManager = PermissionManager.shared
    private let subscriptionService: CalendarSubscriptionService
    private let localEventGroupService = LocalEventGroupService.shared
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    private init() {
        self.subscriptionService = CalendarSubscriptionService()
        setupObservers()
        loadAllGroups()
    }

    // MARK: - Public Methods

    /// 根据事件获取其所属组的颜色
    func getColor(for event: CalendarEvent) -> Color {
        // 1. 优先使用subscriptionId查询
        if let subscriptionId = event.subscriptionId {
            // 检查本地事件组
            if let group = localEventGroupService.getGroup(by: subscriptionId) {
                return group.color.swiftUIColor
            }

            // 检查外部订阅组
            if let color = externalSubscriptionGroups[subscriptionId] {
                return color.swiftUIColor
            }

            // 检查系统日历组
            if let color = systemCalendarGroups[subscriptionId] {
                return color.swiftUIColor
            }
        }

        // 2. 如果没有subscriptionId
        // 本地事件使用默认类别的颜色
        if event.source == .user {
            let defaultGroup = localEventGroupService.getDefaultGroup()
            return defaultGroup.color.swiftUIColor
        }

        // 其他来源使用source的默认颜色
        return event.source.defaultColor
    }

    /// 根据subscriptionId获取颜色
    func getColor(for subscriptionId: UUID) -> EventColor? {
        // 检查本地事件组
        if let group = localEventGroupService.getGroup(by: subscriptionId) {
            return group.color
        }

        // 检查外部订阅组
        if let color = externalSubscriptionGroups[subscriptionId] {
            return color
        }

        // 检查系统日历组
        if let color = systemCalendarGroups[subscriptionId] {
            return color
        }

        return nil
    }

    /// 获取默认本地事件组ID
    var defaultLocalGroupId: UUID {
        localEventGroupService.defaultGroupId
    }

    /// 获取默认本地事件组配置
    var defaultLocalGroupConfig: LocalEventGroupConfig {
        localEventGroupService.getDefaultGroup()
    }

    /// 获取所有本地事件组
    func getAllLocalGroups() -> [LocalEventGroupConfig] {
        return localEventGroupService.getAllGroups()
    }

    /// 重新加载所有组
    func reloadAllGroups() {
        loadAllGroups()
    }

    // MARK: - Private Methods

    private func setupObservers() {
        // 监听外部订阅变化
        NotificationCenter.default.publisher(for: .subscriptionDidUpdate)
            .sink { [weak self] _ in
                self?.loadExternalSubscriptions()
            }
            .store(in: &cancellables)

        // 监听系统日历权限变化
        permissionManager.$isAuthorized
            .sink { [weak self] isAuthorized in
                if isAuthorized {
                    self?.loadSystemCalendars()
                }
            }
            .store(in: &cancellables)
    }

    private func loadAllGroups() {
        loadSystemCalendars()
        loadExternalSubscriptions()
    }

    private func loadSystemCalendars() {
        Task { @MainActor in
            // 从PermissionManager获取系统日历颜色映射
            var colorMap: [UUID: EventColor] = [:]

            for calendar in permissionManager.systemCalendars {
                // 生成UUID（使用calendarIdentifier的hash）
                let calendarId = UUID(uuidString: calendar.calendarIdentifier) ?? UUID()
                let displayColor = permissionManager.getDisplayColor(for: calendar)

                // 转换为EventColor
                if let eventColor = EventColor(from: Color(displayColor)) {
                    colorMap[calendarId] = eventColor
                } else {
                    colorMap[calendarId] = .blue  // 默认蓝色
                }
            }

            systemCalendarGroups = colorMap
            Logger.debug("Loaded \(colorMap.count) system calendar groups", category: Logger.calendar)
        }
    }

    private func loadExternalSubscriptions() {
        Task {
            do {
                let subscriptions = try await subscriptionService.getAllSubscriptions()
                let externalSubs = subscriptions.filter { $0.subscriptionType == .external }

                await MainActor.run {
                    var colorMap: [UUID: EventColor] = [:]
                    for sub in externalSubs {
                        colorMap[sub.id] = sub.color
                    }
                    externalSubscriptionGroups = colorMap
                    Logger.debug("Loaded \(colorMap.count) external subscription groups", category: Logger.calendar)
                }
            } catch {
                Logger.error("Failed to load external subscriptions: \(error)", category: Logger.calendar)
            }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let subscriptionDidUpdate = Notification.Name("subscriptionDidUpdate")
}
