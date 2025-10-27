//
//  MiniCalError.swift
//  MiniCal
//
//  Created on 2025/10/27.
//

import Foundation

enum MiniCalError: LocalizedError {
    case fileNotFound(String)
    case invalidJSON(String)
    case authorizationDenied
    case dataCorrupted
    case networkUnavailable
    case unknown(Error)

    var errorDescription: String? {
        switch self {
        case .fileNotFound(let path):
            return "文件未找到: \(path)"
        case .invalidJSON(let reason):
            return "JSON解析失败: \(reason)"
        case .authorizationDenied:
            return "日历访问权限被拒绝"
        case .dataCorrupted:
            return "数据损坏,请重新安装应用"
        case .networkUnavailable:
            return "网络不可用"
        case .unknown(let error):
            return "未知错误: \(error.localizedDescription)"
        }
    }
}
