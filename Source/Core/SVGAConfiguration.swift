//
//  SVGAConfiguration.swift
//  SVGAPlayer-Swift
//
//  播放器的全部"状态类"配置。新增属性只需要改这里和 SVGAPlayerCore.apply,
//  SVGAPlayer / SVGAView 两个外壳不用动。
//

import UIKit

/// 动态内容(文本、图片、隐藏、自绘),按 imageKey 索引。
struct SVGADynamicContent {
    /// 动态文本。删除已有的 key 会触发图层树重建。
    var texts: [String: NSAttributedString] = [:]
    /// 替换图片。key 在写入时会去掉扩展名("banner.png" 与 "banner" 等价),与原版一致。
    /// 只更新对应图层内容,不重建图层树。请通过 `setImage(_:forKey:)` 写入。
    private(set) var images: [String: UIImage] = [:]
    var hiddens: [String: Bool] = [:]
    var drawings: [String: SVGAPlayerDynamicDrawingBlock] = [:]
    
    /// 设置或移除(传 nil)替换图片。
    mutating func setImage(_ image: UIImage?, forKey key: String) {
        images[(key as NSString).deletingPathExtension] = image
    }
}

/// `clearsAfterStop == false` 时,停止或播放结束后停留的帧。
/// 同时作用于 stopAnimation 和播放完成。
enum SVGAFillMode {
    /// 停在最后一帧。
    case forward
    /// 跳到第一帧。
    case backward
    /// 停在当前帧(播放完成时即最后一帧)。
    case current
}

/// contentMode 不在这里:以宿主 UIView 自身的 contentMode 为准。
struct SVGAConfiguration {
    typealias FinishBlock = () -> Void
    typealias FrameBlock = (_ frame: Int, _ percentage: CGFloat) -> Void

    /// 播放次数。0 表示无限循环。
    var loopCount = 0
    /// 播放结束 / 停止时是否清空画面(与原版一致,默认 true)。
    var clearsAfterStop = true
    /// `clearsAfterStop == false` 时,停止 / 播放结束后停留的帧。默认停在当前帧。
    var fillMode: SVGAFillMode = .current
    var dynamic = SVGADynamicContent()
    /// 播放完指定次数后回调(主线程)。闭包无法比较,每次 apply 都会直接覆盖。
    var onFinish: FinishBlock?
    /// 每播放一帧回调(主线程)。percentage = (frame + 1) / 总帧数。
    var onFrame: FrameBlock?
}
