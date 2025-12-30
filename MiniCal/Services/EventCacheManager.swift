import Foundation
import Combine

class EventCacheManager: ObservableObject {
    private let memoryCache = NSCache<NSString, CachedEventArray>()
    private let storageManager: LocalStorageManager
    private var cancellables = Set<AnyCancellable>()

    @Published var cacheStatistics = CacheStatistics()
    @Published var isLoading = false

    // 缓存配置
    private let maxMemoryItems = 1000
    private let maxMemorySize = 50 * 1024 * 1024 // 50MB
    private let cacheExpirationInterval: TimeInterval = 24 * 60 * 60 // 24小时

    init(storageManager: LocalStorageManager = LocalStorageManager()) {
        self.storageManager = storageManager
        setupMemoryCache()
        loadCacheStatistics()
    }

    // MARK: - Cache Setup
    private func setupMemoryCache() {
        memoryCache.countLimit = maxMemoryItems
        memoryCache.totalCostLimit = maxMemorySize

        // 设置缓存清理策略
        // delegate 设置在macOS中需要特殊处理
    }

    private func loadCacheStatistics() {
        if let data = UserDefaults.standard.data(forKey: "EventCacheStatistics"),
           let stats = try? JSONDecoder().decode(CacheStatistics.self, from: data) {
            cacheStatistics = stats
        }
    }

    private func saveCacheStatistics() {
        if let data = try? JSONEncoder().encode(cacheStatistics) {
            UserDefaults.standard.set(data, forKey: "EventCacheStatistics")
        }
    }

    // MARK: - Event Caching
    func cacheEvents(_ events: [CalendarEvent], for date: Date, subscriptionId: UUID) {
        let cacheKey = generateCacheKey(for: date, subscriptionId: subscriptionId)
        let cachedEvents = CachedEventArray(
            events: events,
            cacheDate: Date(),
            subscriptionId: subscriptionId
        )

        // 计算缓存大小
        let cacheSize = calculateCacheSize(for: events)

        // 存储到内存缓存
        memoryCache.setObject(cachedEvents, forKey: cacheKey as NSString, cost: cacheSize)

        // 异步存储到磁盘
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.persistEventsToDisk(cachedEvents, key: cacheKey)
        }

        // 更新统计信息
        updateCacheStatistics(eventsAdded: events.count)
    }

    func getCachedEvents(for date: Date, subscriptionId: UUID) -> [CalendarEvent]? {
        let cacheKey = generateCacheKey(for: date, subscriptionId: subscriptionId)

        // 首先尝试从内存缓存获取
        if let cachedEvents = memoryCache.object(forKey: cacheKey as NSString) {
            // 检查缓存是否过期
            if !isCacheExpired(cachedEvents) {
                updateCacheStatistics(hits: 1)
                return cachedEvents.events
            } else {
                // 缓存过期，移除
                memoryCache.removeObject(forKey: cacheKey as NSString)
            }
        }

        // 从磁盘缓存获取
        if let cachedEvents = loadEventsFromDisk(key: cacheKey) {
            if !isCacheExpired(cachedEvents) {
                // 重新加载到内存缓存
                let cacheSize = calculateCacheSize(for: cachedEvents.events)
                memoryCache.setObject(cachedEvents, forKey: cacheKey as NSString, cost: cacheSize)

                updateCacheStatistics(hits: 1)
                return cachedEvents.events
            } else {
                // 缓存过期，清理磁盘缓存
                removeEventsFromDisk(key: cacheKey)
            }
        }

        updateCacheStatistics(misses: 1)
        return nil
    }

    func getCachedEvents(in dateRange: DateRange, subscriptionId: UUID) -> [CalendarEvent] {
        var allEvents: [CalendarEvent] = []
        let calendar = Calendar.current
        var currentDate = dateRange.startDate

        while currentDate <= dateRange.endDate {
            if let events = getCachedEvents(for: currentDate, subscriptionId: subscriptionId) {
                allEvents.append(contentsOf: events)
            }

            guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = nextDate
        }

        return allEvents.filter { event in
            dateRange.contains(event.startDate)
        }
    }

    // MARK: - Cache Management
    func clearCache(for subscriptionId: UUID? = nil) {
        if let subscriptionId = subscriptionId {
            // 清理特定订阅源的缓存
            clearCacheForSubscription(subscriptionId)
        } else {
            // 清理所有缓存
            memoryCache.removeAllObjects()
            clearAllDiskCache()
            resetCacheStatistics()
        }
    }

    func clearExpiredCache() {
        let expirationDate = Date().addingTimeInterval(-cacheExpirationInterval)

        // 清理内存中的过期缓存
        // 由于NSCache没有直接的遍历方法，我们通过重新初始化来清理
        setupMemoryCache()

        // 清理磁盘中的过期缓存
        DispatchQueue.global(qos: .utility).async { [weak self] in
            self?.clearExpiredDiskCache(before: expirationDate)
        }
    }

    func warmCache(for subscriptionIds: [UUID], dateRange: DateRange) {
        isLoading = true

        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }

            for subscriptionId in subscriptionIds {
                var currentDate = dateRange.startDate
                let calendar = Calendar.current

                while currentDate <= dateRange.endDate {
                    // 检查缓存是否已存在
                    if self.getCachedEvents(for: currentDate, subscriptionId: subscriptionId) == nil {
                        // 缓存不存在，可以从EventKit预加载
                        // 这里可以调用EventKitService来预加载数据
                    }

                    guard let nextDate = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
                    currentDate = nextDate
                }
            }

            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }

    // MARK: - Helper Methods
    private func generateCacheKey(for date: Date, subscriptionId: UUID) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        return "events_\(subscriptionId.uuidString)_\(dateString)"
    }

    private func isCacheExpired(_ cachedEvents: CachedEventArray) -> Bool {
        return Date().timeIntervalSince(cachedEvents.cacheDate) > cacheExpirationInterval
    }

    private func calculateCacheSize(for events: [CalendarEvent]) -> Int {
        // 简化的大小计算，实际实现中可以使用更精确的方法
        return events.count * 1024 // 假设每个事件约1KB
    }

    private func updateCacheStatistics(eventsAdded: Int = 0, hits: Int = 0, misses: Int = 0) {
        cacheStatistics.totalEvents += eventsAdded
        cacheStatistics.cacheHits += hits
        cacheStatistics.cacheMisses += misses
        cacheStatistics.lastUpdated = Date()

        saveCacheStatistics()
    }

    private func resetCacheStatistics() {
        cacheStatistics = CacheStatistics()
        saveCacheStatistics()
    }

    // MARK: - Disk Cache Operations
    private func persistEventsToDisk(_ cachedEvents: CachedEventArray, key: String) {
        guard let data = try? JSONEncoder().encode(cachedEvents) else { return }

        let cacheDirectory = getCacheDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        do {
            try data.write(to: fileURL)
        } catch {
            print("Failed to persist events to disk: \(error)")
        }
    }

    private func loadEventsFromDisk(key: String) -> CachedEventArray? {
        let cacheDirectory = getCacheDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        do {
            let data = try Data(contentsOf: fileURL)
            return try JSONDecoder().decode(CachedEventArray.self, from: data)
        } catch {
            return nil
        }
    }

    private func removeEventsFromDisk(key: String) {
        let cacheDirectory = getCacheDirectory()
        let fileURL = cacheDirectory.appendingPathComponent("\(key).json")

        do {
            try FileManager.default.removeItem(at: fileURL)
        } catch {
            // 忽略删除失败
        }
    }

    private func clearAllDiskCache() {
        let cacheDirectory = getCacheDirectory()

        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: nil)
            for file in files {
                try FileManager.default.removeItem(at: file)
            }
        } catch {
            print("Failed to clear disk cache: \(error)")
        }
    }

    private func clearExpiredDiskCache(before date: Date) {
        let cacheDirectory = getCacheDirectory()

        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.contentModificationDateKey])

            for file in files {
                if let attributes = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                   let modificationDate = attributes.contentModificationDate,
                   modificationDate < date {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to clear expired disk cache: \(error)")
        }
    }

    private func clearCacheForSubscription(_ subscriptionId: UUID) {
        // 清理内存缓存
        // 这里需要实现更复杂的逻辑来查找和移除特定订阅源的缓存项

        // 清理磁盘缓存
        let cacheDirectory = getCacheDirectory()

        do {
            let files = try FileManager.default.contentsOfDirectory(at: cacheDirectory, includingPropertiesForKeys: [.nameKey])

            for file in files {
                let filename = file.lastPathComponent
                if filename.contains(subscriptionId.uuidString) {
                    try FileManager.default.removeItem(at: file)
                }
            }
        } catch {
            print("Failed to clear cache for subscription: \(error)")
        }
    }

    private func getCacheDirectory() -> URL {
        let cacheDirectory = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
        return cacheDirectory.appendingPathComponent("EventCache", isDirectory: true)
    }
}

// MARK: - Supporting Types
class CachedEventArray: Codable {
    let events: [CalendarEvent]
    let cacheDate: Date
    let subscriptionId: UUID

    init(events: [CalendarEvent], cacheDate: Date, subscriptionId: UUID) {
        self.events = events
        self.cacheDate = cacheDate
        self.subscriptionId = subscriptionId
    }
}

struct CacheStatistics: Codable {
    var totalEvents: Int = 0
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var lastUpdated: Date = Date()

    var hitRate: Double {
        let total = cacheHits + cacheMisses
        return total > 0 ? Double(cacheHits) / Double(total) : 0.0
    }

    var cacheSizeDescription: String {
        return "\(totalEvents) 个事件"
    }
}

// MARK: - Cache Delegate Handler
extension EventCacheManager {
    func handleCacheEviction(for cachedArray: CachedEventArray) {
        // 处理缓存被驱逐的情况
        print("Evicting cache for subscription: \(cachedArray.subscriptionId)")
    }
}