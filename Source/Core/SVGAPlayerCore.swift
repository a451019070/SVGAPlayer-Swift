//
//  SVGAPlayerCore.swift
//  SVGAPlayer-Swift
//
//  与 UI 框架无关的播放核心:只依赖 CALayer,宿主 layer 由外部注入。
//

import UIKit
internal import AVFAudio

final class SVGAPlayerCore {
    
    // MARK: - Public State
    
    /// 动画图层挂载的宿主 layer。
    weak var hostLayer: CALayer? {
        didSet {
            guard let drawLayer, hostLayer !== oldValue else { return }
            hostLayer?.addSublayer(drawLayer)
        }
    }
    
    /// 当前生效的配置。修改请通过 `apply(_:)`。
    private(set) var configuration = SVGAConfiguration()
    
    var isPlaying: Bool { displayLink != nil }
    
    // MARK: - Private State
    
    private var videoItem: SVGAVideoEntity?
    private var drawLayer: CALayer?
    private var audioLayers: [SVGAAudioLayer] = []
    private var contentLayers: [SVGAContentLayer] = []
    private var currentFrame = 0
    private var playedLoops = 0
    /// 已达到播放次数(由 playedLoops 推导,不单独存状态)。
    private var isFinished: Bool {
        configuration.loopCount > 0 && playedLoops >= configuration.loopCount
    }
    private var displayLink: CADisplayLink?
    private var viewSize: CGSize = .zero
    /// 与 UIView 默认值一致;实际值由宿主通过 layout(size:contentMode:) 传入。
    private var contentMode: UIView.ContentMode = .scaleToFill
    
    deinit {
        displayLink?.invalidate()
    }
    
    // MARK: - Entity
    
    /// 设置资源。相同实例重复设置会被忽略。
    /// 播放中:不中断,从新资源第 0 帧接着播(帧率换成新资源的);未播放:只显示第 0 帧。
    /// 传 nil 时清空画面并停止。
    func setVideoEntity(_ entity: SVGAVideoEntity?) {
        guard entity !== videoItem else { return }
        clear()
        currentFrame = 0
        playedLoops = 0
        videoItem = entity
        if let fps = entity?.fps, fps > 0 {
            displayLink?.preferredFramesPerSecond = fps
        } else {
            // 没有可播内容时 displayLink 空跑会误触发播完回调,需要停掉
            pauseAnimation()
        }
        draw()
    }
    
    // MARK: - Playback
    
    /// 从第 0 帧重新播放。
    func startAnimation() {
        pauseAnimation()
        currentFrame = 0
        playedLoops = 0
        resumeAnimation()
    }
    
    /// 从当前帧继续播放;已播完(达到 loopCount)时从头开始;正在播放时无效果。
    func resumeAnimation() {
        guard displayLink == nil, let videoItem else { return }
        guard videoItem.fps > 0 else {
            print("videoItem fps could not be 0!")
            return
        }
        if isFinished {
            currentFrame = 0
            playedLoops = 0
        }
        if drawLayer == nil {
            draw()
        }
        let link = CADisplayLink(target: DisplayLinkProxy(self),
                                 selector: #selector(DisplayLinkProxy.tick))
        link.preferredFramesPerSecond = videoItem.fps
        link.add(to: .main, forMode: .common)
        displayLink = link
    }
    
    /// 暂停,保留当前帧。
    func pauseAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        clearAudios()
    }
    
    /// 停止(与原版一致):不改变帧位置,也不受 fillMode 影响。
    /// clearAfterStop 为 false 时画面停在当前帧;为 true 时清空画面。
    func stopAnimation(clearAfterStop: Bool = true) {
        pauseAnimation()
        if clearAfterStop {
            clear()
        }
    }
    
    /// 与原版一致:先 stop,再按 fillMode 跳帧。
    private func finish(totalFrames: Int) {
        stopAnimation(clearAfterStop: configuration.clearsAfterStop)
        switch configuration.fillMode {
        case .forward: currentFrame = max(totalFrames - 1, 0)
        case .backward: currentFrame = 0
        }
        if !configuration.clearsAfterStop {
            update()
        }
        configuration.onFinish?()
    }
    
    // MARK: - Draw
    
    /// 移除并释放图层树(不停止播放,不丢失 videoItem)。
    func clear() {
        clearAudios()
        audioLayers = []
        contentLayers = []
        drawLayer?.removeFromSuperlayer()
        drawLayer = nil
    }
    
    private func clearAudios() {
        for audioLayer in audioLayers where audioLayer.audioPlaying {
            audioLayer.audioPlayer?.stop()
            audioLayer.audioPlaying = false
        }
    }
}

extension SVGAPlayerCore {
    fileprivate func nextFrame() {
        let totalFrames = videoItem?.frames ?? 0
        currentFrame += 1
        if currentFrame >= totalFrames {
            playedLoops += 1
            clearAudios()
            let loopCount = configuration.loopCount
            if loopCount > 0 && playedLoops >= loopCount {
                finish(totalFrames: totalFrames)
                return
            }
            currentFrame = 0
        }
        update()
        if totalFrames > 0 {
            configuration.onFrame?(currentFrame, CGFloat(currentFrame + 1) / CGFloat(totalFrames))
        }
    }
}

extension SVGAPlayerCore {
    private func draw() {
        guard let videoItem else { return }
        let dynamic = configuration.dynamic
        
        let drawLayer = CALayer()
        drawLayer.frame = CGRect(origin: .zero, size: videoItem.videoSize)
        drawLayer.masksToBounds = true
        self.drawLayer = drawLayer
        
        var tempHostLayers: [String: CALayer] = [:]
        var tempContentLayers: [SVGAContentLayer] = []
        
        for (idx, sprite) in videoItem.sprites.enumerated() {
            let imageKey = sprite.imageKey
            let bitmap = sprite.bitmapKey.flatMap { dynamic.images[$0] ?? videoItem.images[$0] }
            
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
            
            if let text = dynamic.texts[imageKey] {
                contentLayer.setText(text, constrainedTo: textConstrainedSize(forKey: imageKey))
            }
            if dynamic.hiddens[imageKey] == true {
                contentLayer.dynamicHidden = true
            }
            if let drawingBlock = dynamic.drawings[imageKey] {
                contentLayer.dynamicDrawingBlock = drawingBlock
            }
        }
        contentLayers = tempContentLayers
        
        hostLayer?.addSublayer(drawLayer)
        audioLayers = videoItem.audios.map { SVGAAudioLayer(audioItem: $0, videoItem: videoItem) }
        update()
        applyLayout()
    }
    
    private func update() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        for contentLayer in contentLayers {
            contentLayer.stepToFrame(currentFrame)
        }
        CATransaction.commit()
        
        guard isPlaying, !audioLayers.isEmpty else { return }
        for audioLayer in audioLayers {
            let item = audioLayer.audioItem
            if !audioLayer.audioPlaying && item.startFrame <= currentFrame && currentFrame <= item.endFrame {
                // 按当前帧相对音频起始帧的偏移定位,暂停后继续播放时音画保持同步
                let fps = Double(videoItem?.fps ?? 0)
                let frameOffset = fps > 0 ? Double(currentFrame - item.startFrame) / fps : 0
                audioLayer.audioPlayer?.currentTime = TimeInterval(item.startTime) / 1000 + frameOffset
                audioLayer.audioPlayer?.play()
                audioLayer.audioPlaying = true
            }
            if audioLayer.audioPlaying && item.endFrame <= currentFrame {
                audioLayer.audioPlayer?.stop()
                audioLayer.audioPlaying = false
            }
        }
    }
}

// MARK: - Configuration
extension SVGAPlayerCore{
    /// 应用配置。内部按差异更新,可在 SwiftUI 的 updateUIView 中频繁调用。
    func apply(_ newConfiguration: SVGAConfiguration) {
        let old = configuration
        configuration = newConfiguration
        applyDynamic(newConfiguration.dynamic, old: old.dynamic)
    }
    
    private func applyDynamic(_ new: SVGADynamicContent, old: SVGADynamicContent) {
        guard drawLayer != nil else { return }
        
        // 图片变化、或有文本被移除(已挂载的文字图层无法单独摘除)时,重建图层树
        let textRemoved = old.texts.keys.contains { new.texts[$0] == nil }
        if new.images != old.images || textRemoved {
            clear()
            draw()
            return
        }
        
        for (key, text) in new.texts where old.texts[key] != text {
            setText(text, forKey: key)
        }
        
        for contentLayer in contentLayers {
            guard let key = contentLayer.imageKey else { continue }
            let hidden = new.hiddens[key] ?? false
            if contentLayer.dynamicHidden != hidden {
                contentLayer.dynamicHidden = hidden
            }
            contentLayer.dynamicDrawingBlock = new.drawings[key]
        }
    }
}

// MARK: - Dynamic Text
extension SVGAPlayerCore {
    private func setText(_ text: NSAttributedString, forKey key: String) {
        guard !contentLayers.isEmpty else { return }
        let constrainedSize = textConstrainedSize(forKey: key)
        for contentLayer in contentLayers where contentLayer.imageKey == key {
            contentLayer.setText(text, constrainedTo: constrainedSize)
        }
    }
    
    /// 文字排版约束尺寸:取原图的像素尺寸。
    private func textConstrainedSize(forKey key: String) -> CGSize {
        guard let image = videoItem?.images[key] else { return .zero }
        return CGSize(width: image.size.width * image.scale,
                      height: image.size.height * image.scale)
    }
}

// MARK: - Layout
extension SVGAPlayerCore{
    /// 宿主尺寸或 contentMode 变化时调用。contentMode 由宿主 UIView 提供。
    func layout(size: CGSize, contentMode: UIView.ContentMode) {
        guard size != viewSize || contentMode != self.contentMode else { return }
        viewSize = size
        self.contentMode = contentMode
        applyLayout()
    }
    
    private func applyLayout() {
        guard let videoItem, let drawLayer else { return }
        guard viewSize.width > 0, viewSize.height > 0,
              videoItem.videoSize.width > 0, videoItem.videoSize.height > 0 else { return }
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        drawLayer.transform = Self.transform(videoSize: videoItem.videoSize,
                                             viewSize: viewSize,
                                             contentMode: contentMode)
        CATransaction.commit()
    }
}

extension SVGAPlayerCore {
    /// 计算 drawLayer 需要的变换。纯函数,不依赖任何视图。
    static func transform(videoSize: CGSize, viewSize: CGSize, contentMode: UIView.ContentMode) -> CATransform3D {
        
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
            return makeAspectTransform(fitWidth: videoRatio > layerRatio)
        case .scaleAspectFill:
            return makeAspectTransform(fitWidth: videoRatio < layerRatio)
        case .top:
            let scale = viewSize.width / videoSize.width
            return makeTransform(scaleX: scale, scaleY: scale)
        case .bottom:
            let scale = viewSize.width / videoSize.width
            return makeTransform(scaleX: scale, scaleY: scale,
                                 translateY: viewSize.height - videoSize.height * scale)
        case .left:
            let scale = viewSize.height / videoSize.height
            return makeTransform(scaleX: scale, scaleY: scale)
        case .right:
            let scale = viewSize.height / videoSize.height
            return makeTransform(scaleX: scale, scaleY: scale,
                                 translateX: viewSize.width - videoSize.width * scale)
        default:
            return makeTransform(scaleX: viewSize.width / videoSize.width,
                                 scaleY: viewSize.height / videoSize.height)
        }
    }
}

extension SVGAPlayerCore {
    
}

/// CADisplayLink 会强引用 target,用弱引用代理避免循环引用。
private final class DisplayLinkProxy {
    private weak var core: SVGAPlayerCore?
    
    init(_ core: SVGAPlayerCore) {
        self.core = core
    }
    
    @objc func tick() {
        core?.nextFrame()
    }
}
