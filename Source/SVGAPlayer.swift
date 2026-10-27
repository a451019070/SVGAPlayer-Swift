//
//  SVGAPlayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/19.
//

import UIKit
internal import AVFAudio


class SVGAPlayer: UIView {
    
    var videoItem: SVGAVideoEntity?
    
    private var drawLayer: CALayer?
    private var audioLayers: [SVGAAudioLayer] = []
    private var contentLayers: [SVGAContentLayer] = []
    private var currentFrame = 0
    private var forwardAnimating = false
    
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
    
    private func update() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for contentLayer in contentLayers {
            contentLayer.stepToFrame(currentFrame)
        }
        CATransaction.commit()
        
        guard forwardAnimating, !audioLayers.isEmpty else { return }
        for audioLayer in audioLayers {
            let item = audioLayer.audioItem
            if !audioLayer.audioPlaying && item.startFrame <= currentFrame && currentFrame <= item.endFrame {
                audioLayer.audioPlayer?.currentTime = TimeInterval(item.startTime / 1000)
                audioLayer.audioPlayer?.play()
                audioLayer.audioPlaying = true
            }
            if audioLayer.audioPlaying && item.endFrame <= currentFrame {
                audioLayer.audioPlayer?.stop()
                audioLayer.audioPlaying = false
            }
        }
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        resize()
    }
    
    private func resize() {
        guard let videoItem, let drawLayer else { return }
        let videoSize = videoItem.videoSize
        let viewSize = bounds.size
        let frameSize = frame.size
        
        /// 以图层中心为锚点缩放,再叠加额外平移。
        func makeTransform(scaleX: CGFloat, scaleY: CGFloat,
                           translateX: CGFloat = 0, translateY: CGFloat = 0) -> CATransform3D {
            let offsetX = (1 - scaleX) / 2 * videoSize.width
            let offsetY = (1 - scaleY) / 2 * videoSize.height
            return CATransform3DMakeAffineTransform(
                CGAffineTransform(a: scaleX, b: 0, c: 0, d: scaleY,
                                  tx: -offsetX + translateX, ty: -offsetY + translateY)
            )
        }
        
        /// 等比缩放并在另一轴居中。fitWidth 为 true 时按宽度缩放,否则按高度缩放。
        func makeAspectTransform(fitWidth: Bool) -> CATransform3D {
            if fitWidth {
                let ratio = viewSize.width / videoSize.width
                return makeTransform(scaleX: ratio, scaleY: ratio,
                                     translateY: (viewSize.height - videoSize.height * ratio) / 2)
            } else {
                let ratio = viewSize.height / videoSize.height
                return makeTransform(scaleX: ratio, scaleY: ratio,
                                     translateX: (viewSize.width - videoSize.width * ratio) / 2)
            }
        }
        
        let videoRatio = videoSize.width / videoSize.height
        let layerRatio = viewSize.width / viewSize.height
        
        switch contentMode {
        case .scaleAspectFit:
            drawLayer.transform = makeAspectTransform(fitWidth: videoRatio > layerRatio)
        case .scaleAspectFill:
            drawLayer.transform = makeAspectTransform(fitWidth: videoRatio < layerRatio)
        case .top:
            let scale = frameSize.width / videoSize.width
            drawLayer.transform = makeTransform(scaleX: scale, scaleY: scale)
        case .bottom:
            let scale = frameSize.width / videoSize.width
            drawLayer.transform = makeTransform(scaleX: scale, scaleY: scale,
                                                translateY: frameSize.height - videoSize.height * scale)
        case .left:
            let scale = frameSize.height / videoSize.height
            drawLayer.transform = makeTransform(scaleX: scale, scaleY: scale)
        case .right:
            let scale = frameSize.height / videoSize.height
            drawLayer.transform = makeTransform(scaleX: scale, scaleY: scale,
                                                translateX: frameSize.width - videoSize.width * scale)
        default:
            drawLayer.transform = makeTransform(scaleX: frameSize.width / videoSize.width,
                                                scaleY: frameSize.height / videoSize.height)
        }
    }
    
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
