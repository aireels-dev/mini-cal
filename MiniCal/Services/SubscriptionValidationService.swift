import Foundation

class SubscriptionValidationService {

    // MARK: - Validation Errors

    enum ValidationError: Error, LocalizedError {
        case invalidURL
        case unsupportedScheme
        case invalidHost
        case resourceNotFound
        case timeout
        case serverError(Int)
        case invalidFormat
        case emptyCalendar

        var errorDescription: String? {
            switch self {
            case .invalidURL:
                return "无效的URL格式"
            case .unsupportedScheme:
                return "不支持的URL协议，仅支持http、https、webcal"
            case .invalidHost:
                return "无效的主机地址"
            case .resourceNotFound:
                return "找不到指定的日历资源"
            case .timeout:
                return "连接超时"
            case .serverError(let code):
                return "服务器错误 (HTTP \(code))"
            case .invalidFormat:
                return "无效的日历格式，仅支持iCalendar格式"
            case .emptyCalendar:
                return "日历文件为空或格式不正确"
            }
        }
    }

    // MARK: - Supported Schemes

    private let supportedSchemes: Set<String> = ["http", "https", "webcal"]

    // MARK: - URL Validation

    func validateURL(_ urlString: String) throws -> URL {
        print("🔍 [Validation] Starting URL validation for: \(urlString)")

        // 检查空字符串
        guard !urlString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            print("❌ [Validation] URL is empty")
            throw ValidationError.invalidURL
        }

        // 创建URL对象
        guard let url = URL(string: urlString.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            print("❌ [Validation] Failed to create URL object")
            throw ValidationError.invalidURL
        }
        print("✅ [Validation] URL object created: \(url)")

        // 检查协议
        guard let scheme = url.scheme?.lowercased(), supportedSchemes.contains(scheme) else {
            print("❌ [Validation] Unsupported scheme: \(url.scheme ?? "nil")")
            throw ValidationError.unsupportedScheme
        }
        print("✅ [Validation] Scheme is valid: \(scheme)")

        // 检查主机地址
        guard let host = url.host, !host.isEmpty else {
            print("❌ [Validation] Invalid host: \(url.host ?? "nil")")
            throw ValidationError.invalidHost
        }
        print("✅ [Validation] Host is valid: \(host)")

        // 处理webcal协议转换
        let finalURL: URL
        if scheme == "webcal" {
            var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            components?.scheme = "https"
            guard let httpsURL = components?.url else {
                print("❌ [Validation] Failed to convert webcal to https")
                throw ValidationError.invalidURL
            }
            finalURL = httpsURL
            print("🔄 [Validation] Converted webcal to https: \(finalURL)")
        } else {
            finalURL = url
        }

        print("✅ [Validation] URL validation complete: \(finalURL)")
        return finalURL
    }

    // MARK: - Calendar Accessibility Test

    func testCalendarAccessibility(_ url: URL) async throws {
        print("🌐 [Validation] Testing calendar accessibility: \(url)")
        let request = URLRequest(url: url, timeoutInterval: 30.0)

        do {
            print("📡 [Validation] Sending network request...")
            let (data, response) = try await URLSession.shared.data(for: request)
            print("📥 [Validation] Received response, data size: \(data.count) bytes")

            guard let httpResponse = response as? HTTPURLResponse else {
                print("❌ [Validation] Invalid HTTP response")
                throw ValidationError.invalidURL
            }

            print("📊 [Validation] HTTP Status Code: \(httpResponse.statusCode)")

            // 检查HTTP状态码
            switch httpResponse.statusCode {
            case 200...299:
                print("✅ [Validation] HTTP status is successful")
                break // 成功
            case 404:
                print("❌ [Validation] Resource not found (404)")
                throw ValidationError.resourceNotFound
            case 408:
                print("❌ [Validation] Request timeout (408)")
                throw ValidationError.timeout
            case 500...599:
                print("❌ [Validation] Server error (\(httpResponse.statusCode))")
                throw ValidationError.serverError(httpResponse.statusCode)
            default:
                print("❌ [Validation] Unexpected status code (\(httpResponse.statusCode))")
                throw ValidationError.serverError(httpResponse.statusCode)
            }

            // 验证内容格式
            print("🔍 [Validation] Validating calendar content format...")
            try validateCalendarContent(data)
            print("✅ [Validation] Calendar accessibility test passed")

        } catch let error as ValidationError {
            print("❌ [Validation] Validation error: \(error.localizedDescription)")
            throw error
        } catch {
            print("❌ [Validation] Unexpected error: \(error.localizedDescription)")
            // 处理网络错误
            if let urlError = error as? URLError {
                print("🌐 [Validation] URLError code: \(urlError.code.rawValue)")
                switch urlError.code {
                case .notConnectedToInternet, .networkConnectionLost:
                    print("❌ [Validation] Network connection issue")
                    throw ValidationError.invalidHost
                case .timedOut:
                    print("❌ [Validation] Request timed out")
                    throw ValidationError.timeout
                case .cannotFindHost:
                    print("❌ [Validation] Cannot find host")
                    throw ValidationError.invalidHost
                default:
                    print("❌ [Validation] Other URL error: \(urlError.localizedDescription)")
                    throw ValidationError.invalidURL
                }
            }
            throw ValidationError.invalidURL
        }
    }

    // MARK: - Content Validation

    private func validateCalendarContent(_ data: Data) throws {
        print("📝 [Validation] Validating calendar content, size: \(data.count) bytes")

        // 检查数据是否为空
        guard !data.isEmpty else {
            print("❌ [Validation] Calendar data is empty")
            throw ValidationError.emptyCalendar
        }

        // 转换为字符串进行基本格式检查
        let content: String
        if let utf8Content = String(data: data, encoding: .utf8) {
            content = utf8Content
            print("✅ [Validation] Successfully decoded as UTF-8")
        } else if let latinContent = String(data: data, encoding: .isoLatin1) {
            content = latinContent
            print("✅ [Validation] Successfully decoded as ISO Latin 1")
        } else {
            print("❌ [Validation] Failed to decode data with any supported encoding")
            throw ValidationError.invalidFormat
        }

        // 检查基本的iCalendar格式标识
        let trimmedContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
        print("📊 [Validation] Content length after trimming: \(trimmedContent.count) characters")

        // 打印前200个字符用于调试
        let preview = String(trimmedContent.prefix(200))
        print("📄 [Validation] Content preview: \(preview)")

        // 检查是否包含必要的iCalendar标识
        let hasBegin = trimmedContent.contains("BEGIN:VCALENDAR")
        let hasEnd = trimmedContent.contains("END:VCALENDAR")
        print("🔍 [Validation] Has BEGIN:VCALENDAR: \(hasBegin)")
        print("🔍 [Validation] Has END:VCALENDAR: \(hasEnd)")

        guard hasBegin && hasEnd else {
            print("❌ [Validation] Missing required iCalendar markers")
            throw ValidationError.invalidFormat
        }

        // 检查版本信息
        let hasVersion = trimmedContent.contains("VERSION:")
        print("🔍 [Validation] Has VERSION: \(hasVersion)")

        guard hasVersion else {
            print("❌ [Validation] Missing VERSION field")
            throw ValidationError.invalidFormat
        }

        // 尝试解析基本的iCalendar结构
        print("🔍 [Validation] Validating iCalendar structure...")
        try validateICalendarStructure(trimmedContent)
        print("✅ [Validation] Calendar content validation passed")
    }

    private func validateICalendarStructure(_ content: String) throws {
        let lines = content.components(separatedBy: .newlines)
        var hasVersion = false

        for line in lines {
            let trimmedLine = line.trimmingCharacters(in: .whitespaces)

            if trimmedLine.hasPrefix("VERSION:") {
                hasVersion = true
            }
        }

        // 验证必要的组件
        guard hasVersion else {
            throw ValidationError.invalidFormat
        }

        // 不强制要求有事件，因为有些日历可能是空的或者只有时区定义
    }

    // MARK: - Subscription Info Extraction

    func extractSubscriptionInfo(from url: URL, data: Data) -> SubscriptionInfo? {
        guard let content = String(data: data, encoding: .utf8) else {
            return nil
        }

        var info = SubscriptionInfo(url: url)

        // 尝试从内容中提取日历名称
        info.title = extractCalendarTitle(from: content) ?? url.host ?? "未知日历"

        // 尝试提取其他信息
        info.description = extractCalendarDescription(from: content)
        info.color = extractCalendarColor(from: url)

        return info
    }

    private func extractCalendarTitle(from content: String) -> String? {
        // 查找 X-WR-CALNAME 属性
        let pattern = "X-WR-CALNAME:(.+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let fullRange = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: fullRange) {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: content) {
                    return String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        // 如果没有找到，查找 PRODID 属性
        let prodidPattern = "PRODID:(.+)"
        if let regex = try? NSRegularExpression(pattern: prodidPattern, options: .caseInsensitive) {
            let fullRange = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: fullRange) {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: content) {
                    let prodid = String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                    // 简化产品ID，去除域名等信息
                    return prodid.components(separatedBy: "//").last?.components(separatedBy: ".").first
                }
            }
        }

        return nil
    }

    private func extractCalendarDescription(from content: String) -> String? {
        // 查找 X-WR-CALDESC 属性
        let pattern = "X-WR-CALDESC:(.+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let fullRange = NSRange(location: 0, length: content.utf16.count)
            if let match = regex.firstMatch(in: content, options: [], range: fullRange) {
                let range = match.range(at: 1)
                if let swiftRange = Range(range, in: content) {
                    return String(content[swiftRange]).trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }

        return nil
    }

    func extractCalendarColor(from url: URL) -> EventColor {
        // 根据URL的域名或路径生成默认颜色
        let host = url.host?.lowercased() ?? ""

        // 为常见的日历服务分配特定颜色
        if host.contains("google") {
            return .blue
        } else if host.contains("apple") || host.contains("icloud") {
            return .orange
        } else if host.contains("outlook") || host.contains("office") {
            return .red
        } else if host.contains("yahoo") {
            return .purple
        } else {
            // 基于URL哈希生成一致性颜色
            let hash = abs(host.hashValue)
            let colors: [EventColor] = [.blue, .red, .green, .orange, .purple, .pink, .brown]
            return colors[hash % colors.count]
        }
    }
}

// MARK: - Subscription Info

struct SubscriptionInfo {
    var url: URL
    var title: String = "未知日历"
    var description: String?
    var color: EventColor = .blue
    var timezone: String?
    var eventCount: Int = 0

    init(url: URL, title: String = "未知日历", description: String? = nil, color: EventColor = .blue, timezone: String? = nil, eventCount: Int = 0) {
        self.url = url
        self.title = title
        self.description = description
        self.color = color
        self.timezone = timezone
        self.eventCount = eventCount
    }
}