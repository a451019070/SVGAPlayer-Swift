//
//  SVGAContentLayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

/// 动态绘制回调:每次 stepToFrame 完成后调用。
typealias SVGAPlayerDynamicDrawingBlock = (_ contentLayer: CALayer, _ frameIndex: Int) -> Void

final class SVGAContentLayer: CALayer {
    
    var imageKey: String?
    var dynamicDrawingBlock: SVGAPlayerDynamicDrawingBlock?
    var textLayer: CATextLayer?
    
    var dynamicHidden = false {
        didSet { isHidden = dynamicHidden }
    }
    
    private(set) var bitmapLayer: SVGABitmapLayer?
    private(set) var vectorLayer: SVGAVectorLayer?
    
    override var frame: CGRect {
        didSet { layoutSubContent() }
    }
    
    private var frames: [SVGAVideoSpriteFrameEntity] = []
    private var textLayerAlignment: NSTextAlignment = .center
    
    init(frames: [SVGAVideoSpriteFrameEntity], bitmap: UIImage? = nil) {
        self.frames = frames
        super.init()
        backgroundColor = UIColor.clear.cgColor
        masksToBounds = false
        if let bitmap {
            let bitmapLayer = SVGABitmapLayer(frames: frames)
            bitmapLayer.contents = bitmap.cgImage
            addSublayer(bitmapLayer)
            self.bitmapLayer = bitmapLayer
        }
        let vectorLayer = SVGAVectorLayer(frames: frames)
        addSublayer(vectorLayer)
        self.vectorLayer = vectorLayer
        stepToFrame(0)
    }
    
//    init(frames: [SVGAVideoSpriteFrameEntity]) {
//        self.frames = frames
//        super.init()
//        backgroundColor = UIColor.clear.cgColor
//        masksToBounds = false
//        stepToFrame(0)
//    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? SVGAContentLayer {
            imageKey = other.imageKey
            frames = other.frames
            textLayerAlignment = other.textLayerAlignment
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    // MARK: - Step
    
    func stepToFrame(_ frame: Int) {
        if dynamicHidden {
            return
        }
        guard frame >= 0 && frame < frames.count else { return }
        
        let frameItem = frames[frame]
        if frameItem.alpha > 0.0 {
            isHidden = false
            opacity = Float(frameItem.alpha)
            let nx = frameItem.nx
            let ny = frameItem.ny
            position = .zero
            transform = CATransform3DIdentity
            self.frame = frameItem.layout
            transform = CATransform3DMakeAffineTransform(frameItem.transform)
            let offsetX = self.frame.origin.x - nx
            let offsetY = self.frame.origin.y - ny
            position = CGPoint(x: position.x - offsetX, y: position.y - offsetY)
            
            if let sourceMask = frameItem.maskLayer {
                if let sourceShape = sourceMask as? CAShapeLayer {
                    let cloneShape = CAShapeLayer()
                    cloneShape.path = sourceShape.path
                    cloneShape.fillColor = sourceShape.fillColor
                    mask = cloneShape
                }
            } else {
                mask = nil
            }
            bitmapLayer?.stepToFrame(frame)
            vectorLayer?.stepToFrame(frame)
        } else {
            isHidden = true
        }
        dynamicDrawingBlock?(self, frame)
    }
    
    // MARK: - Layout
    
    private func layoutSubContent() {
        bitmapLayer?.frame = bounds
        vectorLayer?.frame = bounds
        for sublayer in sublayers ?? [] where sublayer is CATextLayer {
            var subFrame = sublayer.frame
            switch textLayerAlignment {
            case .left:
                subFrame.origin.x = 0.0
            case .right:
                subFrame.origin.x = frame.size.width - sublayer.frame.size.width
            default:
                subFrame.origin.x = (frame.size.width - sublayer.frame.size.width) / 2.0
            }
            subFrame.origin.y = (frame.size.height - sublayer.frame.size.height) / 2.0
            sublayer.frame = subFrame
        }
    }
    
    // MARK: - Text
    
    func resetTextLayerProperties(_ attributedString: NSAttributedString) {
        guard attributedString.length > 0,
              let paragraphStyle = attributedString.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle
        else { return }
        
        switch paragraphStyle.lineBreakMode {
        case .byTruncatingTail:
            textLayer?.truncationMode = .end
            textLayer?.isWrapped = false
        case .byTruncatingMiddle:
            textLayer?.truncationMode = .middle
            textLayer?.isWrapped = false
        case .byTruncatingHead:
            textLayer?.truncationMode = .start
            textLayer?.isWrapped = false
        default:
            textLayer?.truncationMode = .none
            textLayer?.isWrapped = true
        }
        
        textLayerAlignment = paragraphStyle.alignment == .natural ? .center : paragraphStyle.alignment
    }
    
}
