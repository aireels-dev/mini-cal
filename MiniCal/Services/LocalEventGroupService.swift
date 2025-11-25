//
//  LocalEventGroupService.swift
//  MiniCal
//
//  本地事件组配置管理服务
//  支持多个本地事件组的配置管理
//

import Foundation
import Combine

/// 本地事件组配置
struct LocalEventGroupConfig: Codable, Identifiable, Equatable {
    var id: UUID
    var title: String
    var color: EventColor
    var isEnabled: Bool
    var isDefault: Bool  // 是否为默认组

    static var `default`: LocalEventGroupConfig {
        LocalEventGroupConfig(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,  // 固定UUID
            title: "默认",
            color: .purple,
            isEnabled: true,
            isDefault: true
        )
    }
}

/// 本地事件组服务（支持多组）
class LocalEventGroupService: ObservableObject {
    static let shared = LocalEventGroupService()

    private let userDefaults = UserDefaults.standard
    private let configsKey = "LocalEventGroupConfigs"

    @Published private(set) var groups: [LocalEventGroupConfig] = []

    private init() {
        loadGroups()
    }

    // MARK: - Public Methods

    /// 获取所有组
    func getAllGroups() -> [LocalEventGroupConfig] {
        return groups
    }

    /// 获取默认组
    func getDefaultGroup() -> LocalEventGroupConfig {
        return groups.first(where: { $0.isDefault }) ?? .default
    }

    /// 根据ID获取组
    func getGroup(by id: UUID) -> LocalEventGroupConfig? {
        return groups.first(where: { $0.id == id })
    }

    /// 添加新组
    func addGroup(title: String, color: EventColor) {
        let newGroup = LocalEventGroupConfig(
            id: UUID(),
            title: title,
            color: color,
            isEnabled: true,
            isDefault: false
        )
        groups.append(newGroup)
        saveGroups()
        Logger.info("Added local event group: \(title)", category: Logger.calendar)

        // 通知组配置已更新
        NotificationCenter.default.post(name: .localEventGroupsDidUpdate, object: nil)
    }

    /// 更新组配置
    func updateGroup(_ config: LocalEventGroupConfig) {
        if let index = groups.firstIndex(where: { $0.id == config.id }) {
            groups[index] = config
            saveGroups()
            Logger.info("Updated local event group: \(config.title)", category: Logger.calendar)

            // 通知组配置已更新
            NotificationCenter.default.post(name: .localEventGroupsDidUpdate, object: nil)
        }
    }

    /// 删除组（非默认组）
    /// 返回是否成功删除
    func deleteGroup(id: UUID) -> Bool {
        guard let index = groups.firstIndex(where: { $0.id == id }) else {
            return false
        }

        // 不能删除默认组
        if groups[index].isDefault {
            Logger.warning("Cannot delete default group", category: Logger.calendar)
            return false
        }

        groups.remove(at: index)
        saveGroups()
        Logger.info("Deleted local event group: \(id)", category: Logger.calendar)

        // 通知组配置已更新
        NotificationCenter.default.post(name: .localEventGroupsDidUpdate, object: nil)

        return true
    }

    /// 获取默认组ID
    var defaultGroupId: UUID {
        getDefaultGroup().id
    }

    // MARK: - Private Methods

    private func loadGroups() {
        if let data = userDefaults.data(forKey: configsKey),
           let configs = try? JSONDecoder().decode([LocalEventGroupConfig].self, from: data) {
            self.groups = configs

            // 确保有默认组
            if !groups.contains(where: { $0.isDefault }) {
                groups.insert(.default, at: 0)
                saveGroups()
            }
        } else {
            // 初始化，只有默认组
            self.groups = [.default]
            saveGroups()
        }

        Logger.debug("Loaded \(groups.count) local event groups", category: Logger.calendar)
    }

    private func saveGroups() {
        do {
            let data = try JSONEncoder().encode(groups)
            userDefaults.set(data, forKey: configsKey)
            Logger.debug("Saved \(groups.count) local event groups", category: Logger.calendar)
        } catch {
            Logger.error("Failed to save local event groups: \(error)", category: Logger.calendar)
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let localEventGroupsDidUpdate = Notification.Name("localEventGroupsDidUpdate")
}
