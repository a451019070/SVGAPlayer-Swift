//
//  SVGAPlayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/19.
//

import UIKit


class SVGAPlayer: UIView {
    
    var videoItem: SVGAVideoEntity?
    
    private var drawLayer: CALayer?
    private var audioLayers: [SVGAAudioLayer] = []
    private var contentLayers: [SVGAContentLayer] = []
    private var currentFrame = 0
    
    private var dynamicObjects: [String: UIImage] = [:]
    private var dynamicTexts: [String: NSAttributedString] = [:]
    private var dynamicDrawings: [String: SVGAPlayerDynamicDrawingBlock] = [:]
    private var dynamicHiddens: [String: Bool] = [:]
    
    // MARK: - Draw
    
    private func draw() {
        guard let videoItem else { return }
        
        let drawLayer = CALayer()
        drawLayer.frame = CGRect(origin: .zero, size: videoItem.videoSize)
        drawLayer.masksToBounds = true
        self.drawLayer = drawLayer
        
        var tempHostLayers: [String: CALayer] = [:]
        var tempContentLayers: [SVGAContentLayer] = []
        
        for (idx, sprite) in videoItem.sprites.enumerated() {
            let imageKey = sprite.imageKey
            let bitmap = sprite.bitmapKey.flatMap { dynamicObjects[$0] ?? videoItem.images[$0] }

            let contentLayer = SVGAContentLayer(frames: sprite.frames, bitmap: bitmap)
            contentLayer.imageKey = !imageKey.isEmpty ? imageKey : nil
            
            tempContentLayers.append(contentLayer)
            
            if imageKey.hasSuffix(".matte") {
                let hostLayer = CALayer()
                hostLayer.mask = contentLayer
                tempHostLayers[imageKey] = hostLayer
            } else if !sprite.matteKey.isEmpty {
                if let hostLayer = tempHostLayers[sprite.matteKey] {
                    hostLayer.addSublayer(contentLayer)
                    let previousMatteKey = idx > 0 ? videoItem.sprites[idx - 1].matteKey : nil
                    if sprite.matteKey != previousMatteKey {
                        drawLayer.addSublayer(hostLayer)
                    }
                }
            } else {
                drawLayer.addSublayer(contentLayer)
            }
            
            guard !imageKey.isEmpty else { continue }
            
            if let text = dynamicTexts[imageKey] {
                contentLayer.setText(text, constrainedTo: textConstrainedSize(forKey: imageKey))
            }
            if dynamicHiddens[imageKey] == true {
                contentLayer.dynamicHidden = true
            }
            if let drawingBlock = dynamicDrawings[imageKey] {
                contentLayer.dynamicDrawingBlock = drawingBlock
            }
        }
        contentLayers = tempContentLayers
        
        layer.addSublayer(drawLayer)
        audioLayers = videoItem.audios.map { SVGAAudioLayer(audioItem: $0, videoItem: videoItem) }
        update()
        resize()
    }
    
    // TODO: 待移植
    private func update() {}
    
    // TODO: 待移植
    private func resize() {}
    
    // MARK: - Dynamic Text
    
    func setAttributedText(_ attributedText: NSAttributedString, forKey key: String) {
        dynamicTexts[key] = attributedText
        guard !contentLayers.isEmpty else { return }
        let constrainedSize = textConstrainedSize(forKey: key)
        for contentLayer in contentLayers where contentLayer.imageKey == key {
            contentLayer.setText(attributedText, constrainedTo: constrainedSize)
        }
    }
    
    /// 文字排版约束尺寸:取原图的像素尺寸。
    private func textConstrainedSize(forKey key: String) -> CGSize {
        guard let image = videoItem?.images[key] else { return .zero }
        return CGSize(width: image.size.width * image.scale,
                      height: image.size.height * image.scale)
    }
    
}
