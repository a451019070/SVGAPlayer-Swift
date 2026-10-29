//
//  SVGAView.swift
//  SVGAPlayer-Swift
//
//  SwiftUI 封装:空 UIView 只提供 layer,播放逻辑全部在 SVGAPlayerCore。
//

import SwiftUI
import UIKit

struct SVGAView: UIViewRepresentable {
    
    var entity: SVGAVideoEntity?
    @Binding var isPlaying: Bool
    var configuration = SVGAConfiguration()
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SVGAHostView {
        let view = SVGAHostView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let core = context.coordinator.core
        core.hostLayer = view.layer
        view.onLayout = { [weak core] size in
            core?.layout(size: size)
        }
        return view
    }
    
    func updateUIView(_ uiView: SVGAHostView, context: Context) {
        let core = context.coordinator.core
        
        // 播放完成后把 isPlaying 置回 false,避免下一次刷新又自动重播。
        var config = configuration
        let userOnFinish = config.onFinish
        let isPlayingBinding = $isPlaying
        config.onFinish = {
            isPlayingBinding.wrappedValue = false
            userOnFinish?()
        }
        
        core.apply(config)
        core.setVideoEntity(entity)
        
        if isPlaying {
            core.resumeAnimation()
        } else {
            core.pauseAnimation()
        }
    }
    
    static func dismantleUIView(_ uiView: SVGAHostView, coordinator: Coordinator) {
        uiView.onLayout = nil
        coordinator.core.stopAnimation()
    }
    
    final class Coordinator {
        let core = SVGAPlayerCore()
    }
}

// MARK: - Modifiers

extension SVGAView {
    /// 通用入口:新增配置项时无需再给 SVGAView 加参数。
    func configure(_ transform: (inout SVGAConfiguration) -> Void) -> SVGAView {
        var copy = self
        transform(&copy.configuration)
        return copy
    }
    
    func contentMode(_ mode: UIView.ContentMode) -> SVGAView {
        configure { $0.contentMode = mode }
    }
    
    func loopCount(_ count: Int) -> SVGAView {
        configure { $0.loopCount = count }
    }
    
    func onFinish(_ action: @escaping () -> Void) -> SVGAView {
        configure { $0.onFinish = action }
    }
    
    func onFrame(_ action: @escaping (_ frame: Int, _ percentage: CGFloat) -> Void) -> SVGAView {
        configure { $0.onFrame = action }
    }
    
    func clearsAfterStop(_ clears: Bool) -> SVGAView {
        configure { $0.clearsAfterStop = clears }
    }
    
    func fillMode(_ mode: SVGAFillMode) -> SVGAView {
        configure { $0.fillMode = mode }
    }
}

/// 只负责提供 layer,并在布局变化时回调尺寸。
final class SVGAHostView: UIView {
    
    var onLayout: ((CGSize) -> Void)?
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size)
    }
}
