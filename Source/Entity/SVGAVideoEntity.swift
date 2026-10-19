//
//  SVGAVideoEntity.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit


class SVGAVideoEntity {
    
    private static let mp3MagicNumber: [UInt8] = Array("ID3".utf8)
    
    private(set) var videoSize: CGSize = CGSize(width: 100, height: 100)
    private(set) var fps: Int = 20
    private(set) var frames: Int = 0
    private(set) var images: [String: UIImage] = [:]
    private(set) var audiosData: [String: Data] = [:]
    private(set) var sprites: [SVGAVideoSpriteEntity] = []
    private(set) var audios: [SVGAAudioEntity] = []
    private(set) var cacheDir: String
    
    init(protoObject: SVGAProtoMovieEntity, cacheDir: String = "") {
        self.cacheDir = cacheDir
        resetMovie(with: protoObject)
    }
    
    private func resetMovie(with protoObject: SVGAProtoMovieEntity) {
        guard protoObject.hasParams else { return }
        let params = protoObject.params
        videoSize = CGSize(width: CGFloat(params.viewBoxWidth), height: CGFloat(params.viewBoxHeight))
        fps = Int(params.fps)
        frames = Int(params.frames)
    }
    
    private static func isMP3Data(_ data: Data) -> Bool {
        data.starts(with: mp3MagicNumber)
    }
    
    // MARK: - Reset
    
    /// 解析 proto 里的 images:value 是文件名则从 cacheDir 读取;否则当作二进制数据,MP3 归入 audiosData,其余当图片。
    func resetImages(with protoObject: SVGAProtoMovieEntity) {
        var images: [String: UIImage] = [:]
        var audiosData: [String: Data] = [:]
        let fileManager = FileManager.default
        
        for (key, data) in protoObject.images {
            if let fileName = String(data: data, encoding: .utf8) {
                var filePath = (cacheDir as NSString).appendingPathComponent("\(fileName).png")
                if !fileManager.fileExists(atPath: filePath) {
                    filePath = (cacheDir as NSString).appendingPathComponent(fileName)
                }
                if fileManager.fileExists(atPath: filePath),
                   let imageData = try? Data(contentsOf: URL(fileURLWithPath: filePath), options: .mappedIfSafe),
                   let image = UIImage(data: imageData, scale: 2.0) {
                    images[key] = image
                }
            } else if Self.isMP3Data(data) {
                audiosData[key] = data
            } else if let image = UIImage(data: data, scale: 2.0) {
                images[key] = image
            }
        }
        
        self.images = images
        self.audiosData = audiosData
    }
    
    /// 解析 proto 里的 sprites(图层及每帧信息)。
    func resetSprites(with protoObject: SVGAProtoMovieEntity) {
        sprites = protoObject.sprites.map { SVGAVideoSpriteEntity(protoObject: $0) }
    }
    
    /// 解析 proto 里的 audios(音频起止帧、时间等信息)。
    func resetAudios(with protoObject: SVGAProtoMovieEntity) {
        audios = protoObject.audios.map { SVGAAudioEntity(protoObject: $0) }
    }
    
}
