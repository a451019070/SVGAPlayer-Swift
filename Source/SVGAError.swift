//
//  SVGAError.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import Foundation

enum SVGAError: Error {
    case invalidURL
    case network(Error)
    case httpStatus(Int)
    case emptyData
    case unzipFailed
    case decodeFailed(Error)
}

extension SVGAError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "无效的 URL"
        case .network(let error):
            return "网络请求失败: \(error.localizedDescription)"
        case .httpStatus(let code):
            return "HTTP 状态码异常: \(code)"
        case .emptyData:
            return "数据为空"
        case .unzipFailed:
            return "解压失败"
        case .decodeFailed(let error):
            return "解析失败: \(error.localizedDescription)"
        }
    }
}
