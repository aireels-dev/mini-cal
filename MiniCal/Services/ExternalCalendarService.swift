import Foundation
import Combine

class ExternalCalendarService: NSObject, ObservableObject {

    // MARK: - Service Errors

    enum ServiceError: Error, LocalizedError {
        case invalidURL
        case networkError(Error)
        case invalidResponse
        case permissionDenied
        case subscriptionNotFound
        case parseError(Error)
        case quotaExceeded
        case rateLimited

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的URL"
            case .networkError(let error):
                return "网络错误: \(error.localizedDescription)"
            case .invalidResponse:
                return "服务器响应无效"
            case .permissionDenied:
                return "权限被拒绝"
            case .subscriptionNotFound:
                return "找不到指定的订阅源"
            case .parseError(let error):
                return "解析错误: \(error.localizedDescription)"
            case .quotaExceeded:
                return "超出配额限制"
            case .rateLimited:
                return "请求过于频繁，请稍后再试"
            }
        }
    }

    // MARK: - Dependencies

    private let validationService: SubscriptionValidationService
    private let iCalParser: ICalParser
    private let urlSession: URLSession
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Configuration

    private let requestTimeout: TimeInterval = 30.0
    private let maxRetryAttempts = 3
    private let retryDelay: TimeInterval = 1.0

    // MARK: - Published Properties

    @Published var isLoading = false
    @Published var downloadProgress: Double = 0.0
    @Published var lastError: ServiceError?

    init(validationService: SubscriptionValidationService = SubscriptionValidationService(),
         iCalParser: ICalParser = ICalParser()) {
        self.validationService = validationService
        self.iCalParser = iCalParser

        // 配置URLSession
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = requestTimeout
        config.timeoutIntervalForResource = requestTimeout * 2
        config.waitsForConnectivity = true

        // 配置缓存策略
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = URLCache(memoryCapacity: 10 * 1024 * 1024, diskCapacity: 100 * 1024 * 1024)

        self.urlSession = URLSession(configuration: config)
    }

    // MARK: - Public Methods

    /// 添加外部日历订阅
    func addSubscription(urlString: String) async throws -> CalendarSubscription {
        print("🚀 [ExternalCalendar] Starting addSubscription for: \(urlString)")
        isLoading = true
        lastError = nil

        defer {
            isLoading = false
            print("🏁 [ExternalCalendar] addSubscription completed, isLoading set to false")
        }

        do {
            // 验证URL
            print("🔍 [ExternalCalendar] Step 1: Validating URL...")
            let validatedURL = try validationService.validateURL(urlString)
            print("✅ [ExternalCalendar] URL validated: \(validatedURL)")

            // 测试可访问性
            print("🌐 [ExternalCalendar] Step 2: Testing accessibility...")
            _ = try await validationService.testCalendarAccessibility(validatedURL)
            print("✅ [ExternalCalendar] Accessibility test passed")

            // 下载并解析日历数据
            print("📥 [ExternalCalendar] Step 3: Downloading calendar data...")
            let (data, _) = try await downloadCalendarData(from: validatedURL)
            print("✅ [ExternalCalendar] Downloaded \(data.count) bytes")

            print("📊 [ExternalCalendar] Step 4: Parsing calendar data...")
            let events = try iCalParser.parse(data: data, subscriptionId: UUID())
            print("✅ [ExternalCalendar] Parsed \(events.count) events")

            // 提取订阅信息
            print("📝 [ExternalCalendar] Step 5: Extracting subscription info...")
            guard let subscriptionInfo = validationService.extractSubscriptionInfo(from: validatedURL, data: data) else {
                print("❌ [ExternalCalendar] Failed to extract subscription info")
                throw ServiceError.invalidResponse
            }
            print("✅ [ExternalCalendar] Subscription info: title=\(subscriptionInfo.title), color=\(subscriptionInfo.color)")

            // 创建订阅对象
            print("🆕 [ExternalCalendar] Step 6: Creating subscription object...")
            var subscription = CalendarSubscription(
                title: subscriptionInfo.title,
                color: subscriptionInfo.color,
                subscriptionType: .external
            )
            subscription.url = validatedURL
            subscription.lastSyncDate = Date()
            subscription.syncStatus.state = .success
            print("✅ [ExternalCalendar] Subscription created successfully: \(subscription.id)")

            return subscription

        } catch let error as SubscriptionValidationService.ValidationError {
            print("❌ [ExternalCalendar] ValidationError: \(error.localizedDescription)")
            throw ServiceError.networkError(error)
        } catch let error as ICalParser.ParseError {
            print("❌ [ExternalCalendar] ParseError: \(error.localizedDescription)")
            throw ServiceError.parseError(error)
        } catch {
            print("❌ [ExternalCalendar] Unexpected error: \(error.localizedDescription)")
            throw ServiceError.networkError(error)
        }
    }

    /// 同步外部日历订阅
    func syncSubscription(_ subscription: CalendarSubscription) async throws -> [CalendarEvent] {
        isLoading = true
        lastError = nil
        downloadProgress = 0.0

        defer {
            isLoading = false
            downloadProgress = 0.0
        }

        do {
            guard let url = subscription.url else {
                throw ServiceError.invalidURL
            }

            // 下载数据
            let (data, _) = try await downloadCalendarData(from: url)

            // 解析事件
            let events = try iCalParser.parse(data: data, subscriptionId: subscription.id)

            Logger.info("Successfully synced \(events.count) events from \(subscription.title)", category: Logger.calendar)

            return events

        } catch let error as SubscriptionValidationService.ValidationError {
            throw ServiceError.networkError(error)
        } catch let error as ICalParser.ParseError {
            throw ServiceError.parseError(error)
        } catch {
            throw ServiceError.networkError(error)
        }
    }

    /// 检查订阅源是否可访问
    func checkSubscriptionAvailability(_ subscription: CalendarSubscription) async throws -> Bool {
        guard let url = subscription.url else {
            return false
        }

        do {
            try await validationService.testCalendarAccessibility(url)
            return true
        } catch {
            Logger.error("Subscription availability check failed: \(error)", category: Logger.calendar)
            return false
        }
    }

    /// 获取订阅源信息（不下载完整数据）
    func getSubscriptionInfo(for urlString: String) async throws -> SubscriptionInfo {
        isLoading = true
        lastError = nil

        defer {
            isLoading = false
        }

        do {
            let validatedURL = try validationService.validateURL(urlString)

            // 只下载头部信息来获取基本信息
            var request = URLRequest(url: validatedURL)
            request.httpMethod = "HEAD"

            let (_, response) = try await urlSession.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                throw ServiceError.permissionDenied
            }

            // 尝试获取少量内容来提取信息
            request.httpMethod = "GET"
            if let rangeRequest = createRangeRequest(url: validatedURL, range: 0..<4096) {
                let (data, _) = try await urlSession.data(for: rangeRequest)

                if let info = validationService.extractSubscriptionInfo(from: validatedURL, data: data) {
                    return info
                }
            }

            // 如果无法提取信息，返回基本信息
            var info = SubscriptionInfo(url: validatedURL)
            info.title = validatedURL.host ?? "未知日历"

            return info

        } catch let error as SubscriptionValidationService.ValidationError {
            throw ServiceError.networkError(error)
        } catch {
            throw ServiceError.networkError(error)
        }
    }

    // MARK: - Private Methods

    private func downloadCalendarData(from url: URL) async throws -> (Data, URLResponse) {
        var attempt = 0

        while attempt < maxRetryAttempts {
            do {
                let request = createURLRequest(for: url)
                let (data, response) = try await urlSession.data(for: request)

                guard let httpResponse = response as? HTTPURLResponse else {
                    throw ServiceError.invalidResponse
                }

                // 检查HTTP状态码
                switch httpResponse.statusCode {
                case 200...299:
                    return (data, response)
                case 401, 403:
                    throw ServiceError.permissionDenied
                case 404:
                    throw ServiceError.subscriptionNotFound
                case 429:
                    attempt += 1
                    if attempt < maxRetryAttempts {
                        // 等待后重试
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * pow(2.0, Double(attempt)) * 1_000_000_000))
                        continue
                    } else {
                        throw ServiceError.rateLimited
                    }
                case 500...599:
                    attempt += 1
                    if attempt < maxRetryAttempts {
                        try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                        continue
                    } else {
                        throw ServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil))
                    }
                default:
                    throw ServiceError.networkError(NSError(domain: "HTTPError", code: httpResponse.statusCode, userInfo: nil))
                }

            } catch {
                attempt += 1
                if attempt < maxRetryAttempts {
                    Logger.warning("Download attempt \(attempt) failed, retrying: \(error)", category: Logger.calendar)
                    try await Task.sleep(nanoseconds: UInt64(retryDelay * 1_000_000_000))
                    continue
                } else {
                    throw error
                }
            }
        }

        throw ServiceError.networkError(NSError(domain: "MaxRetriesExceeded", code: -1, userInfo: nil))
    }

    private func createURLRequest(for url: URL) -> URLRequest {
        var request = URLRequest(url: url)

        // 设置User-Agent
        request.setValue("MiniCal/\(AppVersion.version) (+https://github.com/aireels-dev/mini-cal)", forHTTPHeaderField: "User-Agent")

        // 设置Accept头
        request.setValue("text/calendar, application/octet-stream, */*", forHTTPHeaderField: "Accept")

        // 设置缓存策略
        request.cachePolicy = .reloadIgnoringLocalCacheData

        // 设置超时
        request.timeoutInterval = requestTimeout

        return request
    }

    private func createRangeRequest(url: URL, range: Range<Int>) -> URLRequest? {
        var request = createURLRequest(for: url)
        request.setValue("bytes=\(range.lowerBound)-\(range.upperBound)", forHTTPHeaderField: "Range")
        return request
    }

    // MARK: - Batch Operations

    /// 批量同步多个订阅
    func syncMultipleSubscriptions(_ subscriptions: [CalendarSubscription]) async -> [UUID: Result<[CalendarEvent], ServiceError>] {
        var results: [UUID: Result<[CalendarEvent], ServiceError>] = [:]

        await withTaskGroup(of: (UUID, Result<[CalendarEvent], ServiceError>).self) { group in
            for subscription in subscriptions {
                group.addTask {
                    do {
                        let events = try await self.syncSubscription(subscription)
                        return (subscription.id, .success(events))
                    } catch {
                        let serviceError = error as? ServiceError ?? ServiceError.networkError(error)
                        return (subscription.id, .failure(serviceError))
                    }
                }
            }

            for await (subscriptionId, result) in group {
                results[subscriptionId] = result
            }
        }

        return results
    }

    // MARK: - Cache Management

    /// 清理网络缓存
    func clearCache() {
        urlSession.configuration.urlCache?.removeAllCachedResponses()
    }

    /// 获取缓存大小
    func getCacheSize() -> Int64 {
        return Int64(urlSession.configuration.urlCache?.currentDiskUsage ?? 0)
    }
}

// MARK: - URLSessionDelegate

extension ExternalCalendarService: URLSessionDelegate {
    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            Logger.error("URLSession became invalid: \(error)", category: Logger.calendar)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let error = error {
            Logger.error("URLSession task completed with error: \(error)", category: Logger.calendar)
        }
    }
}

// MARK: - URLSessionDownloadDelegate (for progress tracking)

extension ExternalCalendarService: URLSessionDownloadDelegate {
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        // 处理下载完成
        Logger.debug("Download task completed: \(downloadTask.originalRequest?.url?.absoluteString ?? "unknown")", category: Logger.calendar)
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        // 更新下载进度
        if totalBytesExpectedToWrite > 0 {
            DispatchQueue.main.async {
                self.downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
        }
    }
}