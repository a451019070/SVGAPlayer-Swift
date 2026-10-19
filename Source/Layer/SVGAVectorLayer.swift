//
//  SVGAVectorLayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

final class SVGAVectorLayer: CALayer {
    
    private var frames: [SVGAVideoSpriteFrameEntity] = []
    private var drawedFrame: Int = 0
    /// key: keep 帧的下标;value: 该 keep 帧所沿用的最近一个非 keep 帧的下标。
    private var keepFrameCache: [Int: Int] = [:]
    
    init(frames: [SVGAVideoSpriteFrameEntity]) {
        self.frames = frames
        super.init()
        backgroundColor = UIColor.clear.cgColor
        masksToBounds = false
        resetKeepFrameCache()
        stepToFrame(0)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? SVGAVectorLayer {
            frames = other.frames
            drawedFrame = other.drawedFrame
            keepFrameCache = other.keepFrameCache
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func stepToFrame(_ frame: Int) {
        if frame >= 0 && frame < frames.count {
            drawFrame(frame)
        }
    }
    
    // MARK: - Keep frame
    
    private func resetKeepFrameCache() {
        var lastKeep = 0
        var cache: [Int: Int] = [:]
        for (index, frameItem) in frames.enumerated() {
            if isKeepFrame(frameItem) {
                cache[index] = lastKeep
            } else {
                lastKeep = index
            }
        }
        keepFrameCache = cache
    }
    
    private func isKeepFrame(_ frameItem: SVGAVideoSpriteFrameEntity) -> Bool {
        frameItem.shapes.first?.type == .keep
    }
    
    // MARK: - Draw
    
    private func drawFrame(_ frame: Int) {
        let frameItem = frames[frame]
        if isKeepFrame(frameItem), drawedFrame == keepFrameCache[frame] {
            return
        }
        
        sublayers?.forEach { $0.removeFromSuperlayer() }
        for shape in frameItem.shapes {
            switch shape.type {
            case .shape:
                addSublayer(createCurveLayer(shape))
            case .ellipse:
                addSublayer(createEllipseLayer(shape))
            case .rect:
                addSublayer(createRectLayer(shape))
            default:
                break
            }
        }
        drawedFrame = frame
    }
    
    private func createCurveLayer(_ shape: SVGAProtoShapeEntity) -> CALayer {
        let bezierPath = SVGABezierPath()
        if case .shape(let args)? = shape.args, !args.d.isEmpty {
            bezierPath.setValues(args.d)
        }
        let shapeLayer = bezierPath.createLayer()
        resetStyles(shapeLayer, shape: shape)
        resetTransform(shapeLayer, shape: shape)
        return shapeLayer
    }
    
    private func createEllipseLayer(_ shape: SVGAProtoShapeEntity) -> CALayer {
        guard case .ellipse(let args)? = shape.args else { return CALayer() }
        let rect = CGRect(x: CGFloat(args.x - args.radiusX),
                          y: CGFloat(args.y - args.radiusY),
                          width: CGFloat(args.radiusX * 2),
                          height: CGFloat(args.radiusY * 2))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(ovalIn: rect).cgPath
        resetStyles(shapeLayer, shape: shape)
        resetTransform(shapeLayer, shape: shape)
        return shapeLayer
    }
    
    private func createRectLayer(_ shape: SVGAProtoShapeEntity) -> CALayer {
        guard case .rect(let args)? = shape.args else { return CALayer() }
        let rect = CGRect(x: CGFloat(args.x), y: CGFloat(args.y),
                          width: CGFloat(args.width), height: CGFloat(args.height))
        let shapeLayer = CAShapeLayer()
        shapeLayer.path = UIBezierPath(roundedRect: rect, cornerRadius: CGFloat(args.cornerRadius)).cgPath
        resetStyles(shapeLayer, shape: shape)
        resetTransform(shapeLayer, shape: shape)
        return shapeLayer
    }
    
    // MARK: - Styles
    
    private func resetStyles(_ shapeLayer: CAShapeLayer, shape: SVGAProtoShapeEntity) {
        shapeLayer.masksToBounds = false
        shapeLayer.backgroundColor = UIColor.clear.cgColor
        guard shape.hasStyles else { return }
        
        let styles = shape.styles
        if styles.hasFill {
            shapeLayer.fillColor = Self.color(styles.fill)
        } else {
            shapeLayer.fillColor = UIColor.clear.cgColor
        }
        if styles.hasStroke {
            shapeLayer.strokeColor = Self.color(styles.stroke)
        }
        shapeLayer.lineWidth = CGFloat(styles.strokeWidth)
        
        switch styles.lineCap {
        case .butt: shapeLayer.lineCap = .butt
        case .round: shapeLayer.lineCap = .round
        case .square: shapeLayer.lineCap = .square
        default: break
        }
        switch styles.lineJoin {
        case .round: shapeLayer.lineJoin = .round
        case .miter: shapeLayer.lineJoin = .miter
        case .bevel: shapeLayer.lineJoin = .bevel
        default: break
        }
        
        shapeLayer.lineDashPhase = CGFloat(styles.lineDashIii)
        if styles.lineDashI > 0 || styles.lineDashIi > 0 {
            shapeLayer.lineDashPattern = [
                NSNumber(value: styles.lineDashI < 1.0 ? 1.0 : styles.lineDashI),
                NSNumber(value: styles.lineDashIi < 0.1 ? 0.1 : styles.lineDashIi)
            ]
        }
        shapeLayer.miterLimit = CGFloat(styles.miterLimit)
    }
    
    private func resetTransform(_ shapeLayer: CAShapeLayer, shape: SVGAProtoShapeEntity) {
        guard shape.hasTransform else { return }
        let t = shape.transform
        let affine = CGAffineTransform(a: CGFloat(t.a), b: CGFloat(t.b),
                                       c: CGFloat(t.c), d: CGFloat(t.d),
                                       tx: CGFloat(t.tx), ty: CGFloat(t.ty))
        shapeLayer.transform = CATransform3DMakeAffineTransform(affine)
    }
    
    private static func color(_ rgba: SVGAProtoShapeEntity.ShapeStyle.RGBAColor) -> CGColor {
        UIColor(red: CGFloat(rgba.r), green: CGFloat(rgba.g), blue: CGFloat(rgba.b), alpha: CGFloat(rgba.a)).cgColor
    }
    
}
