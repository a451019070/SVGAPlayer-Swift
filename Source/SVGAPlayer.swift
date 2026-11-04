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
    
    /// 代码创建时默认 `.scaleAspectFit`(完整显示、居中);storyboard / xib 创建时沿用 IB 里的值。
    override init(frame: CGRect) {
        super.init(frame: frame)
        contentMode = .scaleAspectFit
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
}

// MARK: - Configuration Sync
extension SVGAPlayer {
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
}

// MARK: - Layout & Lifecycle
extension SVGAPlayer {
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
}

// MARK: - Playback Control(命令类:只转发,新增时在这里加一行)
extension SVGAPlayer {
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
    
    /// 跳到指定帧并暂停在那里;`andPlay` 为 true 时从该帧继续播放。帧号越界时忽略。
    func stepToFrame(_ frame: Int, andPlay: Bool = false) {
        core.stepToFrame(frame, andPlay: andPlay)
    }
    
    /// 跳到指定百分比(0~1)并暂停在那里;`andPlay` 为 true 时从该处继续播放。
    func stepToPercentage(_ percentage: CGFloat, andPlay: Bool = false) {
        core.stepToPercentage(percentage, andPlay: andPlay)
    }
    
    /// 停止(与原版一致),是否清空由 `clearsAfterStop` 决定。不清空时画面停在当前帧,不受 fillMode 影响。
    func stopAnimation() {
        core.stopAnimation(clearAfterStop: clearsAfterStop)
    }
    
    func stopAnimation(clearAfterStop: Bool) {
        core.stopAnimation(clearAfterStop: clearAfterStop)
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
    
    var onFinish: SVGAConfiguration.FinishBlock?{
        get{ configuration.onFinish }
        set{ configuration.onFinish = newValue }
    }
    
    var onFrame: SVGAConfiguration.FrameBlock?{
        get{ configuration.onFrame }
        set{ configuration.onFrame = newValue }
    }
}

// MARK: - Dynamic Object
extension SVGAPlayer {
    func setAttributedText(_ attributedText: NSAttributedString, forKey key: String) {
        configuration.dynamic.texts[key] = attributedText
    }
    
    /// 替换图片。传 nil 移除替换,恢复原图。
    func setImage(_ image: UIImage?, forKey key: String) {
        configuration.dynamic.setImage(image, forKey: key)
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
