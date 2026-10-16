//
//  SVGAParser.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import Foundation
import SwiftProtobuf

class SVGAParser {
    
    func parseWithURLRequest(_ request: URLRequest) async throws -> SVGAVideoEntity {
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
        _ = protoObject
        
        let entity = SVGAVideoEntity()
        return entity
    }
}
