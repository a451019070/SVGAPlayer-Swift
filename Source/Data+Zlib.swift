//
//  Data+Zlib.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import Foundation
import zlib

extension Data {
    
    /// 使用系统 zlib 解压 zlib 格式的数据。
    /// - Returns: 解压后的数据；数据为空时原样返回；数据损坏、被截断或不是 zlib 格式时返回 nil。
    func zlibInflate() -> Data? {
        guard !isEmpty else { return self }

        var stream = z_stream()
        let initStatus = inflateInit_(&stream, ZLIB_VERSION, Int32(MemoryLayout<z_stream>.size))
        guard initStatus == Z_OK else { return nil }

        let chunkSize = 64 * 1024
        var buffer = [UInt8](repeating: 0, count: chunkSize)
        var output = Data()
        var status: Int32 = Z_OK

        withUnsafeBytes { (raw: UnsafeRawBufferPointer) in
            guard let base = raw.bindMemory(to: Bytef.self).baseAddress else { return }
            stream.next_in = UnsafeMutablePointer(mutating: base)
            stream.avail_in = uInt(raw.count)

            repeat {
                let produced: Int = buffer.withUnsafeMutableBufferPointer { out in
                    stream.next_out = out.baseAddress
                    stream.avail_out = uInt(chunkSize)
                    status = inflate(&stream, Z_SYNC_FLUSH)
                    return chunkSize - Int(stream.avail_out)
                }
                output.append(contentsOf: buffer[0..<produced])
            } while status == Z_OK
        }

        let endStatus = inflateEnd(&stream)
        guard status == Z_STREAM_END, endStatus == Z_OK else { return nil }
        return output
    }
}
