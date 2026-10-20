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
                let image = videoItem.images[imageKey]
                let bitmapSize = CGSize(
                    width: (image?.size.width ?? 0) * (image?.scale ?? 0),
                    height: (image?.size.height ?? 0) * (image?.scale ?? 0)
                )
                let size = text.boundingRect(with: bitmapSize,
                                             options: .usesLineFragmentOrigin,
                                             context: nil).size
                let textLayer = CATextLayer()
                textLayer.contentsScale = UIScreen.main.scale
                textLayer.string = text
                textLayer.frame = CGRect(origin: .zero, size: size)
                contentLayer.addSublayer(textLayer)
                contentLayer.textLayer = textLayer
                contentLayer.resetTextLayerProperties(text)
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
    
}
