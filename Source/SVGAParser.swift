//
//  SVGAParser.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import Foundation
import SwiftProtobuf

class SVGAParser {
    
    func parse(with urlStr: String?) async throws -> SVGAVideoEntity {
        guard let urlStr = urlStr, !urlStr.isEmpty else { throw SVGAError.invalidURL }
        // 先直接构造；失败时对非法字符（如中文、空格）做 percent-encoding 兜底
        guard let url = URL(string: urlStr)
                ?? urlStr.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed).flatMap(URL.init(string:))
        else { throw SVGAError.invalidURL }
        return try await parse(with: url)
    }
    
    func parse(with url: URL) async throws -> SVGAVideoEntity {
        try await parse(with: URLRequest(url: url))
    }
    
    func parse(with request: URLRequest) async throws -> SVGAVideoEntity {
        guard request.url != nil else { throw SVGAError.invalidURL }
        
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw SVGAError.network(error)
        }
        
        guard let http = response as? HTTPURLResponse else {
            throw SVGAError.network(URLError(.badServerResponse))
        }
        guard (200..<300).contains(http.statusCode) else {
            throw SVGAError.httpStatus(http.statusCode)
        }
        
        return try await parseWithData(data)
    }
    
    func parseWithData(_ data: Data) async throws -> SVGAVideoEntity {
        guard !data.isEmpty else { throw SVGAError.emptyData }
        guard let inflateData = data.zlibInflate() else { throw SVGAError.unzipFailed }
        
        let protoObject: SVGAProtoMovieEntity
        do {
            protoObject = try SVGAProtoMovieEntity(serializedBytes: inflateData)
        } catch {
            throw SVGAError.decodeFailed(error)
        }
        
        let entity = SVGAVideoEntity(protoObject: protoObject)
        entity.resetImages(with: protoObject)
        entity.resetSprites(with: protoObject)
        entity.resetAudios(with: protoObject)
        return entity
    }
}
