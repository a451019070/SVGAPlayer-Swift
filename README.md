# SVGAPlayer-Swift

使用 Swift 重写的 [SVGAPlayer-iOS](https://github.com/svga/SVGAPlayer-iOS),同时支持 **UIKit** 与 **SwiftUI**。

- 纯 Swift 实现,Protobuf 解析基于 [swift-protobuf](https://github.com/apple/swift-protobuf)
- 最低支持 iOS 15.0,Swift 5.9
- 解析使用 `async/await`,错误类型明确(`SVGAError`)
- 播放逻辑统一在 `SVGAPlayerCore`,UIKit(`SVGAPlayer`)与 SwiftUI(`SVGAView`)只是薄封装

## 安装

### Swift Package Manager

```swift
.package(url: "https://github.com/a451019070/SVGAPlayer-Swift.git", from: "1.0.1")
```

### CocoaPods

```ruby
pod 'SVGAPlayer-Swift'
```

## 快速使用

### UIKit

```swift
let player = SVGAPlayer(frame: view.bounds)
player.contentMode = .scaleAspectFit   // 缩放方式直接用 UIView.contentMode
player.loops = 0                       // 0 = 无限循环
view.addSubview(player)

Task {
    let entity = try await SVGAParser().parse(with: URL(string: "https://xxx/demo.svga")!)
    player.setVideoEntity(entity)
    player.startAnimation()
}
```

回调(闭包或 delegate 均可):

```swift
player.onFinish = { print("播放完成") }
player.onFrame = { frame, percentage in print(frame, percentage) }
```

### SwiftUI

```swift
struct DemoView: View {
    @State private var entity: SVGAVideoEntity?
    @State private var state: SVGAPlayState = .playing

    var body: some View {
        SVGAView(entity: entity, state: $state)
            .contentMode(.scaleAspectFit)
            .loopCount(1)
            .clearsAfterStop(false)
            .fillMode(.forward)
            .onFinish { print("done") }
            .task {
                entity = try? await SVGAParser().parse(with: URL(string: "https://xxx/demo.svga")!)
            }
    }
}
```

`SVGAPlayState`:`.playing`(播放 / 暂停后继续 / 播完后重播)、`.paused`、`.stopped`。播放完成后 `state` 会自动回写为 `.paused`。

### 动态替换内容

```swift
player.setImage(UIImage(named: "avatar"), forKey: "banner")        // key 的扩展名会被忽略
player.setImage(withURL: url, forKey: "banner")
player.setAttributedText(NSAttributedString(string: "Hello"), forKey: "title")
player.setHidden(true, forKey: "logo")
player.setDrawingBlock({ layer, frameIndex in /* 自绘 */ }, forKey: "custom")
player.clearDynamicObjects()
```

SwiftUI 对应 `.image(_:forKey:)`、`.attributedText(_:forKey:)`、`.hidden(_:forKey:)`、`.drawingBlock(_:forKey:)`。

## 新版与原版使用方法的差异

| 项目 | 原版 (Objective-C) | 新版 (Swift) |
| --- | --- | --- |
| 语言 / 依赖 | Objective-C,SSZipArchive、Protobuf-ObjC 等 | Swift,仅依赖 swift-protobuf |
| 解析 | `[parser parseWithURL:completionBlock:failureBlock:]` 回调 | `try await parser.parse(with: url)`,抛出 `SVGAError` |
| 本地文件 | `parseWithNamed:inBundle:` | 传入 `file://` URL,或 `parseWithData(_:)` |
| 缩放方式 | `SVGAPlayer.contentMode` | 同样使用 `contentMode`,代码创建默认 `.scaleAspectFit` |
| 播放配置 | 散落的属性 | 统一收敛到 `SVGAConfiguration`(`player.configuration`),`loops` 等为快捷属性 |
| 播放结束回调 | delegate | delegate 或 `onFinish` 闭包 |
| 帧回调 | delegate | delegate 或 `onFrame` 闭包 |
| 开始播放 | `startAnimation` | `startAnimation()`(旧拼写 `starAnimation()` 已标记 deprecated) |
| 停止后画面 | `clearsAfterStop` + `fillMode`(字符串常量) | `clearsAfterStop` + `SVGAFillMode` 枚举(`.forward` / `.backward` / `.current`) |
| 动态图片 key | `setImage:forKey:` | 相同,并统一去掉扩展名 |
| SwiftUI | 不支持 | 原生 `SVGAView`,声明式修饰符 + `state` 绑定控制播放 |
| 缓存 | 内置内存缓存 | 不内置缓存,由调用方管理 `SVGAVideoEntity` |

迁移示例:

```objc
// 原版
SVGAParser *parser = [SVGAParser new];
[parser parseWithURL:url completionBlock:^(SVGAVideoEntity *item) {
    player.videoItem = item;
    [player startAnimation];
} failureBlock:nil];
```

```swift
// 新版
let entity = try await SVGAParser().parse(with: url)
player.setVideoEntity(entity)   // 原版是 player.videoItem = item
player.startAnimation()
```

## 新版优化内容

- **纯 Swift + async/await**:去除回调嵌套,错误分类清晰(无效 URL、网络、HTTP 状态码、空数据、解压失败、解析失败)。
- **统一播放核心**:UIKit 与 SwiftUI 共用 `SVGAPlayerCore`,行为一致;新增配置只需改 `SVGAConfiguration`,外壳无需改动。
- **配置按差异更新**:修改替换图片只更新对应图层内容,不重建整个图层树,动态换图更高效。
- **SwiftUI 支持**:`SVGAView` 原生封装,避免重复刷新造成的重播,播完自动回写状态。
- **CADisplayLink 弱代理**:通过 `DisplayLinkProxy` 避免循环引用,`deinit` 时自动释放。
- **按资源帧率驱动**:`preferredFramesPerSecond` 使用 SVGA 自身 fps;帧率为 0 时安全处理,避免空跑误触发完成回调。
- **更完整的播放控制**:`resumeAnimation` 播完后自动从头开始;`stepToFrame` / `stepToPercentage` 支持 `andPlay`,越界忽略;热切换资源不中断播放。
- **停止行为更灵活**:`SVGAFillMode` 枚举,停留在首帧 / 末帧 / 当前帧。
- **生命周期安全**:从父视图移除时自动停止并清理,音频同步暂停。
- **减少依赖、包体更小**:自行实现 zlib 解压(`Data+Zlib`),只依赖 swift-protobuf。

## 联系方式

- 作者:ZX
- 邮箱:895843633@qq.com

## License

MIT
