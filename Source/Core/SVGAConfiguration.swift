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
    /// 替换图片。变化会触发图层树重建。
    var images: [String: UIImage] = [:]
    var hiddens: [String: Bool] = [:]
    var drawings: [String: SVGAPlayerDynamicDrawingBlock] = [:]
}

/// 播放结束(达到 loopCount)且 `clearsAfterStop == false` 时停留的帧。
enum SVGAFillMode {
    /// 停在最后一帧。
    case forward
    /// 回到第一帧。
    case backward
}

struct SVGAConfiguration {
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// 播放次数。0 表示无限循环。
    var loopCount = 0
    /// 播放结束 / 停止时是否清空画面(与原版一致,默认 true)。
    var clearsAfterStop = true
    /// `clearsAfterStop == false` 时,播放结束后停留的帧。
    var fillMode: SVGAFillMode = .forward
    var dynamic = SVGADynamicContent()
    /// 播放完指定次数后回调(主线程)。闭包无法比较,每次 apply 都会直接覆盖。
    var onFinish: (() -> Void)?
    /// 每播放一帧回调(主线程)。percentage = (frame + 1) / 总帧数。
    var onFrame: ((_ frame: Int, _ percentage: CGFloat) -> Void)?
}
