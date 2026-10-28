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
    var texts: [String: NSAttributedString] = [:]
    /// 替换图片。变化会触发图层树重建。
    var images: [String: UIImage] = [:]
    var hiddens: [String: Bool] = [:]
    var drawings: [String: SVGAPlayerDynamicDrawingBlock] = [:]
}

struct SVGAConfiguration {
    var contentMode: UIView.ContentMode = .scaleAspectFit
    /// 播放次数。0 表示无限循环。
    var loopCount = 0
    var dynamic = SVGADynamicContent()
    /// 播放完指定次数后回调(主线程)。闭包无法比较,每次 apply 都会直接覆盖。
    var onFinish: (() -> Void)?
}
