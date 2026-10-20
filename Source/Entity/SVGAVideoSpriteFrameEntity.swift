//
//  SVGAVideoSpriteFrameEntity.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

final class SVGAVideoSpriteFrameEntity {
    
    private(set) var alpha: CGFloat = 0
    private(set) var transform: CGAffineTransform = .identity
    private(set) var layout: CGRect = .zero
    private(set) var nx: CGFloat = 0
    private(set) var ny: CGFloat = 0
    private(set) var clipPath: String?
    private(set) var shapes: [SVGAProtoShapeEntity] = []
    
    private(set) lazy var maskLayer: CALayer? = {
        guard let clipPath else { return nil }
        let bezierPath = SVGABezierPath()
        bezierPath.setValues(clipPath)
        return bezierPath.createLayer()
    }()
    
    init(protoObject: SVGAProtoFrameEntity) {
        alpha = CGFloat(protoObject.alpha)
        if protoObject.hasLayout {
            let l = protoObject.layout
            layout = CGRect(x: CGFloat(l.x), y: CGFloat(l.y), width: CGFloat(l.width), height: CGFloat(l.height))
        }
        if protoObject.hasTransform {
            let t = protoObject.transform
            transform = CGAffineTransform(a: CGFloat(t.a), b: CGFloat(t.b),
                                          c: CGFloat(t.c), d: CGFloat(t.d),
                                          tx: CGFloat(t.tx), ty: CGFloat(t.ty))
        }
        if !protoObject.clipPath.isEmpty {
            clipPath = protoObject.clipPath
        }
        shapes = protoObject.shapes
        
//        let x = layout.origin.x
//        let y = layout.origin.y
//        let w = layout.size.width
//        let h = layout.size.height
//        let llx = transform.a * x + transform.c * y + transform.tx
//        let lrx = transform.a * (x + w) + transform.c * y + transform.tx
//        let lbx = transform.a * x + transform.c * (y + h) + transform.tx
//        let rbx = transform.a * (x + w) + transform.c * (y + h) + transform.tx
//        let lly = transform.b * x + transform.d * y + transform.ty
//        let lry = transform.b * (x + w) + transform.d * y + transform.ty
//        let lby = transform.b * x + transform.d * (y + h) + transform.ty
//        let rby = transform.b * (x + w) + transform.d * (y + h) + transform.ty
//        nx = min(min(lbx, rbx), min(llx, lrx))
//        ny = min(min(lby, rby), min(lly, lry))
        let bounds = layout.applying(transform)
        nx = bounds.minX
        ny = bounds.minY
    }
    
}
