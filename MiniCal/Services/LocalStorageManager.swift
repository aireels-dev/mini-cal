import Foundation
import Combine

class LocalStorageManager: ObservableObject {
    private let userDefaults = UserDefaults.standard
    private let subscriptionsKey = "CalendarSubscriptions"
    private let colorSchemesKey = "ColorSchemes"

    @Published var subscriptions: [CalendarSubscription] = []
    @Published var colorSchemes: [ColorScheme] = []

    init() {
        loadData()
    }

    // MARK: - Subscription Management
    func saveSubscriptions(_ subscriptions: [CalendarSubscription]) {
        do {
            let data = try JSONEncoder().encode(subscriptions)
            userDefaults.set(data, forKey: subscriptionsKey)
            self.subscriptions = subscriptions
        } catch {
            print("保存订阅源失败: \(error)")
        }
    }

    func loadSubscriptions() -> [CalendarSubscription] {
        guard let data = userDefaults.data(forKey: subscriptionsKey) else {
            return []
        }

        do {
            let subscriptions = try JSONDecoder().decode([CalendarSubscription].self, from: data)
            self.subscriptions = subscriptions
            return subscriptions
        } catch {
            print("加载订阅源失败: \(error)")
            return []
        }
    }

    func addSubscription(_ subscription: CalendarSubscription) {
        var updatedSubscriptions = subscriptions
        updatedSubscriptions.append(subscription)
        saveSubscriptions(updatedSubscriptions)
    }

    func updateSubscription(_ subscription: CalendarSubscription) {
        var updatedSubscriptions = subscriptions
        if let index = updatedSubscriptions.firstIndex(where: { $0.id == subscription.id }) {
            updatedSubscriptions[index] = subscription
            saveSubscriptions(updatedSubscriptions)
        }
    }

    func deleteSubscription(id: UUID) {
        var updatedSubscriptions = subscriptions
        updatedSubscriptions.removeAll { $0.id == id }
        saveSubscriptions(updatedSubscriptions)
    }

    // MARK: - Color Scheme Management
    func saveColorSchemes(_ schemes: [ColorScheme]) {
        do {
            let data = try JSONEncoder().encode(schemes)
            userDefaults.set(data, forKey: colorSchemesKey)
            self.colorSchemes = schemes
        } catch {
            print("保存颜色方案失败: \(error)")
        }
    }

    func loadColorSchemes() -> [ColorScheme] {
        guard let data = userDefaults.data(forKey: colorSchemesKey) else {
            return ColorScheme.builtInSchemes
        }

        do {
            let schemes = try JSONDecoder().decode([ColorScheme].self, from: data)
            self.colorSchemes = schemes
            return schemes
        } catch {
            print("加载颜色方案失败: \(error)")
            return ColorScheme.builtInSchemes
        }
    }

    // MARK: - General Data Management
    private func loadData() {
        subscriptions = loadSubscriptions()
        colorSchemes = loadColorSchemes()
    }

    func clearAllData() {
        userDefaults.removeObject(forKey: subscriptionsKey)
        userDefaults.removeObject(forKey: colorSchemesKey)
        subscriptions = []
        colorSchemes = ColorScheme.builtInSchemes
    }
}