//
//  SVGABitmapLayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

final class SVGABitmapLayer: CALayer {
    
    private var frames: [SVGAVideoSpriteFrameEntity] = []
    
    init(frames: [SVGAVideoSpriteFrameEntity]) {
        self.frames = frames
        super.init()
        backgroundColor = UIColor.clear.cgColor
        masksToBounds = false
        contentsGravity = .resizeAspect
        stepToFrame(0)
    }
    
    override init(layer: Any) {
        super.init(layer: layer)
        if let other = layer as? SVGABitmapLayer {
            frames = other.frames
        }
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func stepToFrame(_ frame: Int) {
    }
    
}
