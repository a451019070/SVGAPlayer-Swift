//
//  SVGAVideoSpriteEntity.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

final class SVGAVideoSpriteEntity {
    
    let imageKey: String
    let matteKey: String
    let frames: [SVGAVideoSpriteFrameEntity]
    
    init(protoObject: SVGAProtoSpriteEntity) {
        imageKey = protoObject.imageKey
        matteKey = protoObject.matteKey
        frames = protoObject.frames.map { SVGAVideoSpriteFrameEntity(protoObject: $0) }
    }
    
    /// 创建该 sprite 对应的图层;bitmap 不为空时会带上位图图层。
    func requestLayer(with bitmap: UIImage?) -> SVGAContentLayer {
        let layer = SVGAContentLayer(frames: frames)
        if let bitmap {
            let bitmapLayer = SVGABitmapLayer(frames: frames)
            bitmapLayer.contents = bitmap.cgImage
            layer.bitmapLayer = bitmapLayer
        }
        layer.vectorLayer = SVGAVectorLayer(frames: frames)
        return layer
    }
    
}
