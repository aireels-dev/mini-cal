import Foundation
import EventKit
import Combine
import AppKit

class PermissionManager: ObservableObject {
    static let shared = PermissionManager()

    private let eventStore = EventStoreManager.shared.eventStore

    @Published var isAuthorized = false
    @Published var authorizationStatus: EKAuthorizationStatus = .notDetermined
    @Published var systemCalendars: [EKCalendar] = []

    // 权限请求历史记录键
    private let lastPermissionRequestDateKey = "LastCalendarPermissionRequestDate"
    private let permissionRequestCountKey = "CalendarPermissionRequestCount"
    private let permissionRequestIntervalDays = 30 // 30天后可以再次请求

    // 系统日历颜色覆盖
    private let calendarColorOverridesKey = "SystemCalendarColorOverrides"
    @Published var colorOverrides: [String: EventColor] = [:]  // calendarIdentifier -> EventColor

    // 系统日历启用/禁用状态
    private let calendarEnabledStateKey = "SystemCalendarEnabledState"
    @Published var calendarEnabledState: [String: Bool] = [:]  // calendarIdentifier -> isEnabled

    init() {
        authorizationStatus = EKEventStore.authorizationStatus(for: .event)
        isAuthorized = (authorizationStatus == .authorized)

        // 加载颜色覆盖
        loadColorOverrides()

        // 加载日历启用状态
        loadCalendarEnabledState()

        // 监听权限状态变化
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(checkAuthorizationStatus),
            name: .EKEventStoreChanged,
            object: eventStore
        )

        // 如果已授权，加载系统日历
        if isAuthorized {
            loadSystemCalendars()
        }
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    func requestCalendarAccess() -> Bool {
        guard authorizationStatus == .notDetermined else {
            return isAuthorized
        }

        let semaphore = DispatchSemaphore(value: 0)
        var granted = false

        // macOS 14 (Sonoma) 及以上必须使用新的 API
        if #available(macOS 14.0, *) {
            eventStore.requestFullAccessToEvents { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = success
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    granted = success
                    semaphore.signal()
                }
            }
        } else {
            // macOS 13 及更早版本使用旧 API
            eventStore.requestAccess(to: .event) { [weak self] success, error in
                DispatchQueue.main.async {
                    self?.isAuthorized = success
                    self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
                    granted = success
                    semaphore.signal()
                }
            }
        }

        semaphore.wait()
        return granted
    }

    func requestEventKitAccess() async -> Bool {
        print("🔐 [Permission] requestEventKitAccess called, current status: \(authorizationStatus.rawValue)")
        Logger.info("requestEventKitAccess called, current status: \(authorizationStatus.rawValue)", category: Logger.app)

        // 如果已授权,直接返回
        if isAuthorized {
            print("✅ [Permission] Already authorized, returning true")
            Logger.info("Already authorized, returning true", category: Logger.app)
            return true
        }

        // 如果权限被拒绝,需要引导用户去系统设置
        if authorizationStatus == .denied {
            print("⚠️ [Permission] Permission denied, opening System Preferences")
            Logger.info("Permission denied, opening System Preferences", category: Logger.app)

            // 记录请求尝试
            recordPermissionRequest()

            // 打开系统偏好设置
            if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Calendars") {
                print("🌐 [Permission] Opening URL: \(url)")
                Logger.info("Opening URL: \(url)", category: Logger.app)
                NSWorkspace.shared.open(url)
            } else {
                print("❌ [Permission] Failed to create System Preferences URL")
                Logger.error("Failed to create System Preferences URL", category: Logger.app)
            }

            return false
        }

        // 只有在未询问状态下才记录请求并弹出系统对话框
        guard authorizationStatus == .notDetermined else {
            print("⚠️ [Permission] Cannot request permission, status is not .notDetermined: \(authorizationStatus.rawValue)")
            Logger.warning("Cannot request permission, status is not .notDetermined: \(authorizationStatus.rawValue)", category: Logger.app)
            return false
        }

        print("📝 [Permission] Requesting EventKit access...")
        Logger.info("Requesting EventKit access...", category: Logger.app)

        // 记录本次权限请求
        recordPermissionRequest()

        return await withCheckedContinuation { continuation in
            // macOS 14 (Sonoma) 及以上必须使用新的 API
            if #available(macOS 14.0, *) {
                print("📞 [Permission] Calling eventStore.requestFullAccessToEvents (macOS 14+)...")
                eventStore.requestFullAccessToEvents { [weak self] granted, error in
                    DispatchQueue.main.async {
                        print("📥 [Permission] Full access result: granted=\(granted), error=\(error?.localizedDescription ?? "none")")
                        Logger.info("Full access result: granted=\(granted), error=\(error?.localizedDescription ?? "none")", category: Logger.app)

                        self?.isAuthorized = granted
                        self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)

                        // 如果授权成功，加载系统日历
                        if granted {
                            print("✅ [Permission] Permission granted, loading system calendars")
                            Logger.info("Permission granted, loading system calendars", category: Logger.app)
                            self?.loadSystemCalendars()
                        }

                        continuation.resume(returning: granted)
                    }
                }
            } else {
                // macOS 13 及更早版本使用旧 API
                print("📞 [Permission] Calling eventStore.requestAccess (macOS 13 and earlier)...")
                eventStore.requestAccess(to: .event) { [weak self] success, error in
                    DispatchQueue.main.async {
                        print("📥 [Permission] EventKit access result: success=\(success), error=\(error?.localizedDescription ?? "none")")
                        Logger.info("EventKit access result: success=\(success), error=\(error?.localizedDescription ?? "none")", category: Logger.app)

                        self?.isAuthorized = success
                        self?.authorizationStatus = EKEventStore.authorizationStatus(for: .event)

                        // 如果授权成功，加载系统日历
                        if success {
                            print("✅ [Permission] Permission granted, loading system calendars")
                            Logger.info("Permission granted, loading system calendars", category: Logger.app)
                            self?.loadSystemCalendars()
                        }

                        continuation.resume(returning: success)
                    }
                }
            }
        }
    }

    @objc private func checkAuthorizationStatus() {
        DispatchQueue.main.async {
            self.authorizationStatus = EKEventStore.authorizationStatus(for: .event)
            self.isAuthorized = (self.authorizationStatus == .authorized)

            // 如果授权状态改变，重新加载日历
            if self.isAuthorized {
                self.loadSystemCalendars()
            } else {
                self.systemCalendars = []
            }
        }
    }

    /// 加载系统日历列表
    private func loadSystemCalendars() {
        guard isAuthorized else {
            systemCalendars = []
            return
        }

        systemCalendars = eventStore.calendars(for: .event)
    }

    func getAuthorizationDescription() -> String {
        switch authorizationStatus {
        case .authorized:
            return "已授权访问日历"
        case .denied:
            return "日历访问被拒绝，请在系统偏好设置中授权"
        case .restricted:
            return "日历访问受限制"
        case .notDetermined:
            return "尚未请求日历访问权限"
        @unknown default:
            return "未知的授权状态"
        }
    }

    // MARK: - Smart Permission Request

    /// 检查是否应该请求权限(首次或距离上次请求超过30天)
    func shouldRequestPermission() -> Bool {
        // 如果已授权,不需要再次请求
        if isAuthorized {
            return false
        }

        // 如果状态是未询问,应该请求
        if authorizationStatus == .notDetermined {
            return true
        }

        // 如果被拒绝,检查距离上次请求是否超过30天
        if authorizationStatus == .denied {
            guard let lastRequestDate = UserDefaults.standard.object(forKey: lastPermissionRequestDateKey) as? Date else {
                return true // 没有记录,可以请求
            }

            let daysSinceLastRequest = Calendar.current.dateComponents([.day], from: lastRequestDate, to: Date()).day ?? 0
            return daysSinceLastRequest >= permissionRequestIntervalDays
        }

        return false
    }

    /// 记录权限请求
    private func recordPermissionRequest() {
        UserDefaults.standard.set(Date(), forKey: lastPermissionRequestDateKey)
        let currentCount = UserDefaults.standard.integer(forKey: permissionRequestCountKey)
        UserDefaults.standard.set(currentCount + 1, forKey: permissionRequestCountKey)
    }

    /// 获取上次权限请求的时间
    func getLastPermissionRequestDate() -> Date? {
        return UserDefaults.standard.object(forKey: lastPermissionRequestDateKey) as? Date
    }

    /// 获取权限请求次数
    func getPermissionRequestCount() -> Int {
        return UserDefaults.standard.integer(forKey: permissionRequestCountKey)
    }

    // MARK: - Calendar Color Overrides

    /// 加载颜色覆盖
    private func loadColorOverrides() {
        guard let data = UserDefaults.standard.data(forKey: calendarColorOverridesKey),
              let dict = try? JSONDecoder().decode([String: String].self, from: data) else {
            colorOverrides = [:]
            return
        }

        // 将字符串转换为 EventColor
        colorOverrides = dict.compactMapValues { EventColor(rawValue: $0) }
    }

    /// 保存颜色覆盖
    private func saveColorOverrides() {
        // 将 EventColor 转换为字符串
        let dict = colorOverrides.mapValues { $0.rawValue }

        if let data = try? JSONEncoder().encode(dict) {
            UserDefaults.standard.set(data, forKey: calendarColorOverridesKey)
        }
    }

    /// 更新日历颜色覆盖
    func updateCalendarColor(calendarIdentifier: String, color: EventColor) {
        colorOverrides[calendarIdentifier] = color
        saveColorOverrides()
        Logger.info("Updated calendar color override: \(calendarIdentifier) -> \(color.rawValue)", category: Logger.calendar)
    }

    /// 获取日历的显示颜色（优先使用覆盖颜色）
    func getDisplayColor(for calendar: EKCalendar) -> NSColor {
        if let overrideColor = colorOverrides[calendar.calendarIdentifier] {
            return overrideColor.nsColor
        }
        return calendar.color
    }

    /// 移除日历颜色覆盖
    func removeCalendarColorOverride(calendarIdentifier: String) {
        colorOverrides.removeValue(forKey: calendarIdentifier)
        saveColorOverrides()
        Logger.info("Removed calendar color override: \(calendarIdentifier)", category: Logger.calendar)
    }

    // MARK: - Calendar Enabled State Management

    /// 加载日历启用状态
    private func loadCalendarEnabledState() {
        guard let data = UserDefaults.standard.data(forKey: calendarEnabledStateKey),
              let dict = try? JSONDecoder().decode([String: Bool].self, from: data) else {
            calendarEnabledState = [:]
            return
        }

        calendarEnabledState = dict
    }

    /// 保存日历启用状态
    private func saveCalendarEnabledState() {
        if let data = try? JSONEncoder().encode(calendarEnabledState) {
            UserDefaults.standard.set(data, forKey: calendarEnabledStateKey)
        }
    }

    /// 切换日历启用状态
    func toggleCalendarEnabled(calendarIdentifier: String) {
        let currentState = isCalendarEnabled(calendarIdentifier: calendarIdentifier)
        calendarEnabledState[calendarIdentifier] = !currentState
        saveCalendarEnabledState()
        Logger.info("Toggled calendar enabled state: \(calendarIdentifier) -> \(!currentState)", category: Logger.calendar)
    }

    /// 设置日历启用状态
    func setCalendarEnabled(calendarIdentifier: String, enabled: Bool) {
        calendarEnabledState[calendarIdentifier] = enabled
        saveCalendarEnabledState()
        Logger.info("Set calendar enabled state: \(calendarIdentifier) -> \(enabled)", category: Logger.calendar)
    }

    /// 获取日历启用状态（默认为 true）
    func isCalendarEnabled(calendarIdentifier: String) -> Bool {
        return calendarEnabledState[calendarIdentifier] ?? true
    }

    /// 获取所有启用的日历标识符
    func getEnabledCalendarIdentifiers() -> Set<String> {
        let allCalendarIds = Set(systemCalendars.map { $0.calendarIdentifier })
        return allCalendarIds.filter { isCalendarEnabled(calendarIdentifier: $0) }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let calendarEnabledStateChanged = Notification.Name("CalendarEnabledStateChanged")
}