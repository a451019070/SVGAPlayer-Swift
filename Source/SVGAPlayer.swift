//
//  SVGAPlayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/19.
//

import UIKit

protocol SVGAPlayerDelegate: AnyObject {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer)
    func svgaPlayer(_ player: SVGAPlayer, didAnimatedToFrame frame: Int)
    func svgaPlayer(_ player: SVGAPlayer, didAnimatedToPercentage percentage: CGFloat)
}

extension SVGAPlayerDelegate {
    func svgaPlayerDidFinishedAnimation(_ player: SVGAPlayer) {}
    func svgaPlayer(_ player: SVGAPlayer, didAnimatedToFrame frame: Int) {}
    func svgaPlayer(_ player: SVGAPlayer, didAnimatedToPercentage percentage: CGFloat) {}
}

/// UIKit 封装:所有播放逻辑都在 SVGAPlayerCore。
/// 状态类属性(loopCount、替换图片、动态文本、回调等)统一通过 `configuration` 设置,
/// 缩放方式用 UIView 自身的 `contentMode`。
/// 新增配置项时这里不需要改动。
class SVGAPlayer: UIView {
    
    private let core = SVGAPlayerCore()
    
    weak var delegate: SVGAPlayerDelegate?
    
    /// 播放配置。修改后立即同步给 core(内部按差异更新)。
    /// 例:`player.configuration.loopCount = 3`
    var configuration = SVGAConfiguration() {
        didSet { syncConfiguration() }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        core.hostLayer = layer
        syncConfiguration()
        core.layout(size: bounds.size, contentMode: contentMode)
    }
    
    /// 在用户配置的回调之外追加 delegate 通知,再交给 core。
    private func syncConfiguration() {
        var config = configuration
        let userOnFinish = config.onFinish
        let userOnFrame = config.onFrame
        config.onFinish = { [weak self] in
            userOnFinish?()
            guard let self else { return }
            self.delegate?.svgaPlayerDidFinishedAnimation(self)
        }
        config.onFrame = { [weak self] frame, percentage in
            userOnFrame?(frame, percentage)
            guard let self, let delegate = self.delegate else { return }
            delegate.svgaPlayer(self, didAnimatedToFrame: frame)
            delegate.svgaPlayer(self, didAnimatedToPercentage: percentage)
        }
        core.apply(config)
    }
    
    // MARK: - Layout
    
    /// 动画的缩放方式直接使用 UIView 自身的 contentMode,默认与系统一致(.scaleToFill)。
    override var contentMode: UIView.ContentMode {
        didSet { core.layout(size: bounds.size, contentMode: contentMode) }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        core.layout(size: bounds.size, contentMode: contentMode)
    }
    
    /// 与原版一致:从父视图移除时停止并清空(不受 clearsAfterStop 影响)。
    /// 重新加入父视图后不会自动播放,需要再次调用 startAnimation()。
    override func willMove(toSuperview newSuperview: UIView?) {
        super.willMove(toSuperview: newSuperview)
        if newSuperview == nil {
            stopAnimation(clearAfterStop: true)
        }
    }
    
    // MARK: - Commands(命令类:只转发,新增时在这里加一行)
    
    func setVideoEntity(_ videoItem: SVGAVideoEntity) {
        core.setVideoEntity(videoItem)
    }
    
    func clear() {
        core.clear()
    }
    
    /// 从第 0 帧开始播放。
    func startAnimation() {
        core.startAnimation()
    }
    
    @available(*, deprecated, renamed: "startAnimation")
    func starAnimation() {
        startAnimation()
    }
    
    /// 从当前帧继续播放(音频同步定位)。
    /// 从当前帧继续播放;已播完(达到 loops)时从头播放;正在播放时无效果。
    func resumeAnimation() {
        core.resumeAnimation()
    }
    
    func pauseAnimation() {
        core.pauseAnimation()
    }
    
    /// 停止(与原版一致),是否清空由 `clearsAfterStop` 决定。不清空时画面停在当前帧,不受 fillMode 影响。
    func stopAnimation() {
        core.stopAnimation(clearAfterStop: clearsAfterStop)
    }
    
    func stopAnimation(clearAfterStop: Bool) {
        core.stopAnimation(clearAfterStop: clearAfterStop)
    }
}

// MARK: - Dynamic Object
extension SVGAPlayer {
    func setAttributedText(_ attributedText: NSAttributedString, forKey key: String) {
        configuration.dynamic.texts[key] = attributedText
    }
    
    /// 替换图片。传 nil 移除替换,恢复原图。
    func setImage(_ image: UIImage?, forKey key: String) {
        configuration.dynamic.images[key] = image
    }
    
    /// 下载图片后替换。失败时静默忽略。
    func setImage(withURL url: URL, forKey key: String) {
        Task { [weak self] in
            guard let (data, _) = try? await URLSession.shared.data(from: url),
                  let image = UIImage(data: data) else { return }
            self?.setImage(image, forKey: key)
        }
    }
    
    func setHidden(_ hidden: Bool, forKey key: String) {
        configuration.dynamic.hiddens[key] = hidden
    }
    
    /// 传 nil 移除自绘。
    func setDrawingBlock(_ drawingBlock: SVGAPlayerDynamicDrawingBlock?, forKey key: String) {
        configuration.dynamic.drawings[key] = drawingBlock
    }
    
    /// 清除所有动态图片、文本、隐藏、自绘设置。
    func clearDynamicObjects() {
        configuration.dynamic = SVGADynamicContent()
    }
}

// MARK: - Configuration Shortcuts
extension SVGAPlayer {
    /// 播放次数。0 表示无限循环。
    var loops: Int {
        get { configuration.loopCount }
        set { configuration.loopCount = newValue }
    }
    
    /// 播放结束 / `stopAnimation()` 时是否清空画面。默认 true。
    var clearsAfterStop: Bool {
        get { configuration.clearsAfterStop }
        set { configuration.clearsAfterStop = newValue }
    }
    
    /// `clearsAfterStop == false` 时播放结束停留的帧。
    var fillMode: SVGAFillMode {
        get { configuration.fillMode }
        set { configuration.fillMode = newValue }
    }
}

// MARK: - 旧实现(已迁移到 SVGAPlayerCore)

/*
import UIKit
internal import AVFAudio


class SVGAPlayer: UIView {
    
    private var videoItem: SVGAVideoEntity?
    
    private var drawLayer: CALayer?
    private var audioLayers: [SVGAAudioLayer] = []
    private var contentLayers: [SVGAContentLayer] = []
    private var currentFrame = 0
    private var forwardAnimating = false
    private var displayLink: CADisplayLink?
    
    private var dynamicObjects: [String: UIImage] = [:]
    private var dynamicTexts: [String: NSAttributedString] = [:]
    private var dynamicDrawings: [String: SVGAPlayerDynamicDrawingBlock] = [:]
    private var dynamicHiddens: [String: Bool] = [:]
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        resize()
    }
    
    func setVideoEntity(_ videoItem :SVGAVideoEntity) {
        self.videoItem = videoItem
        DispatchQueue.main.async {
            self.clear()
            self.draw()
        }
    }
    
    func clear() {
        self.contentLayers = []
        self.drawLayer?.removeFromSuperlayer()
        self.drawLayer = nil
    }
    
    func starAnimation() {
        guard let videoItem else {
            print("videoItem could not be nil!")
            return
        }
        if drawLayer == nil {
            setVideoEntity(videoItem)
        }
        stopAnimation(clearAfterStop: false)
        currentFrame = 0
        guard videoItem.fps > 0 else {
            print("videoItem fps could not be 0!")
            return
        }
        let displayLink = CADisplayLink(target: self, selector: #selector(nextFrame))
        
        displayLink.preferredFramesPerSecond = videoItem.fps
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
        forwardAnimating = true
    }
    func stopAnimation(clearAfterStop: Bool = true) {
        forwardAnimating = false
        displayLink?.invalidate()
        displayLink = nil
        clearAudios()
        if clearAfterStop {
            clear()
        }
    }

    private func clearAudios() {
        for audioLayer in audioLayers where audioLayer.audioPlaying {
            audioLayer.audioPlayer?.stop()
            audioLayer.audioPlaying = false
        }
    }

    @objc private func nextFrame() {
        currentFrame += 1
        if currentFrame >= (videoItem?.frames ?? 0) {
            currentFrame = 0
            clearAudios()
        }
        update()
    }
}

extension SVGAPlayer {
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


extension SVGAPlayer {
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
}
*/
