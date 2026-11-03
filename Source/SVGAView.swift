//
//  SVGAView.swift
//  SVGAPlayer-Swift
//
//  SwiftUI 封装:空 UIView 只提供 layer,播放逻辑全部在 SVGAPlayerCore。
//

import SwiftUI
import UIKit

/// SwiftUI 侧的播放状态。
enum SVGAPlayState {
    /// 播放(暂停后继续、播完后从头开始)。
    case playing
    /// 暂停,画面停在当前帧。
    case paused
    /// 停止,按 `clearsAfterStop` 决定是否清空画面;再次 `.playing` 从头播放。
    case stopped
}

struct SVGAView: UIViewRepresentable {
    
    var entity: SVGAVideoEntity?
    @Binding var state: SVGAPlayState
    var configuration = SVGAConfiguration()
    /// 为 nil 时不修改宿主 View,使用 UIView 默认的 contentMode。
    var contentMode: UIView.ContentMode?
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    func makeUIView(context: Context) -> SVGAHostView {
        let view = SVGAHostView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false
        
        let core = context.coordinator.core
        core.hostLayer = view.layer
        view.onLayout = { [weak core] size, contentMode in
            core?.layout(size: size, contentMode: contentMode)
        }
        return view
    }
    
    func updateUIView(_ uiView: SVGAHostView, context: Context) {
        let core = context.coordinator.core
        
        if let contentMode, uiView.contentMode != contentMode {
            uiView.contentMode = contentMode
        }
        
        // 播放完成后把 state 置为 .paused,避免下一次刷新又自动重播(保留 fillMode 停留的帧)。
        var config = configuration
        let userOnFinish = config.onFinish
        let stateBinding = $state
        config.onFinish = {
            stateBinding.wrappedValue = .paused
            userOnFinish?()
        }
        
        core.apply(config)
        core.setVideoEntity(entity)
        
        let coordinator = context.coordinator
        let previous = coordinator.lastState
        coordinator.lastState = state
        
        switch state {
        case .playing:
            // 持续处于 .playing 时的刷新不再触碰播放器,避免播完后、状态回写前的刷新把它重新拉起来。
            if previous == .stopped {
                core.startAnimation()
            } else if previous != .playing {
                core.resumeAnimation()
            }
        case .paused:
            core.pauseAnimation()
        case .stopped:
            if previous != .stopped {
                core.stopAnimation(clearAfterStop: config.clearsAfterStop)
            }
        }
    }
    
    static func dismantleUIView(_ uiView: SVGAHostView, coordinator: Coordinator) {
        uiView.onLayout = nil
        coordinator.core.stopAnimation()
    }
    
    final class Coordinator {
        let core = SVGAPlayerCore()
        var lastState: SVGAPlayState?
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
        var copy = self
        copy.contentMode = mode
        return copy
    }
    
    func loopCount(_ count: Int) -> SVGAView {
        configure { $0.loopCount = count }
    }
    
    func onFinish(_ action: @escaping SVGAConfiguration.FinishBlock) -> SVGAView {
        configure { $0.onFinish = action }
    }
    
    func onFrame(_ action: @escaping SVGAConfiguration.FrameBlock) -> SVGAView {
        configure { $0.onFrame = action }
    }
    
    func clearsAfterStop(_ clears: Bool) -> SVGAView {
        configure { $0.clearsAfterStop = clears }
    }
    
    func fillMode(_ mode: SVGAFillMode) -> SVGAView {
        configure { $0.fillMode = mode }
    }
}

// MARK: - Dynamic Object

extension SVGAView {
    func attributedText(_ text: NSAttributedString?, forKey key: String) -> SVGAView {
        configure { $0.dynamic.texts[key] = text }
    }
    
    /// 替换图片。传 nil 移除替换,恢复原图。
    func image(_ image: UIImage?, forKey key: String) -> SVGAView {
        configure { $0.dynamic.images[key] = image }
    }
    
    func hidden(_ hidden: Bool, forKey key: String) -> SVGAView {
        configure { $0.dynamic.hiddens[key] = hidden }
    }
    
    /// 传 nil 移除自绘。
    func drawingBlock(_ block: SVGAPlayerDynamicDrawingBlock?, forKey key: String) -> SVGAView {
        configure { $0.dynamic.drawings[key] = block }
    }
    
    /// 清除所有动态图片、文本、隐藏、自绘设置。
    func clearDynamicObjects() -> SVGAView {
        configure { $0.dynamic = SVGADynamicContent() }
    }
}

/// 只负责提供 layer,并在布局或 contentMode 变化时回调。
final class SVGAHostView: UIView {
    
    var onLayout: ((CGSize, UIView.ContentMode) -> Void)?
    
    /// 默认 `.scaleAspectFit`;SVGAView 设置了 `.contentMode(...)` 时会覆盖。
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        contentMode = .scaleAspectFit
    }
    
    override var contentMode: UIView.ContentMode {
        didSet { onLayout?(bounds.size, contentMode) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        onLayout?(bounds.size, contentMode)
    }
}
