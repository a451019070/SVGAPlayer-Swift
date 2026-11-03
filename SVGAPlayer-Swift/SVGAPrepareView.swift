//
//  SVGAPrepareView.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/11/3.
//

import SwiftUI

struct SVGAPrepareView: View {
    
    private let parser = SVGAParser()
    private let items = [
        "https://raw.giteeusercontent.com/hanchao073/SVGA-Samples/raw/master/heartbeat.svga?metadata=eyJyIjoibWFzdGVyIiwiZnAiOiJoZWFydGJlYXQuc3ZnYSIsInVpZCI6NzM4NDM2LCJwaWQiOjE2NTc3NzQxLCJzdG8iOiJnaXQtc2hhcmRpbmctc3RvLTQydC0wMDYiLCJycCI6InJlcG9zLzJmLzhjLzJmOGM1ZWU3OGU5YTdkMWE0MmQxNzM0ODE5ODY4Y2JkM2QzYzg2MTQxMTIxMzY4N2UxNTRmNzMwOTM3NmJmZTcuZ2l0IiwiaXNwIjp0cnVlLCJleHBpcmVfYXQiOjE3OTMxNzg2MDB9&signature=V8OT9h61VG_8fPf4qhLTDwPqtDfNUZqlum_mXaCZMnE",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/EmptyState.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/HamburgerArrow.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/PinJump.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/TwitterHeart.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/Walkthrough.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/angel.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/halloween.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/kingset.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/posche.svga?raw=true",
        "https://cdn.jsdelivr.net/gh/svga/SVGA-Samples@master/rose.svga?raw=true",
    ]
    
    @State private var entity: SVGAVideoEntity?
    @State private var state: SVGAPlayState = .paused
    @State private var index = 0
    @State private var backgroundColor: Color = .white
    @State private var frameText = "frame: -"
    
    var body: some View {
        VStack(spacing: 16) {
            SVGAView(entity: entity, state: $state)
                .contentMode(.scaleAspectFit)
                .loopCount(1)
                .clearsAfterStop(false)
                .fillMode(.forward)
                .onFrame { frame, _ in
                    frameText = "frame: \(frame)"
                }
                .onFinish {
                    print("SVGA 播放完成")
                }
                .frame(maxWidth: .infinity)
                .frame(height: 300)
                .background(backgroundColor)
            
            Text(frameText)
                .font(.footnote)
                .foregroundStyle(.secondary)
            
            changeView()
            controlView()
        }
        .padding()
        .task { await load() }
    }
}

extension SVGAPrepareView {
    
    /// 切换背景色。
    func changeView() -> some View {
        HStack {
            ForEach([Color.white, .black, .blue, .green, .red], id: \.self) { color in
                Button {
                    backgroundColor = color
                } label: {
                    Circle()
                        .fill(color)
                        .overlay(Circle().stroke(Color.gray))
                        .frame(width: 32, height: 32)
                }
            }
        }
    }
    
    /// 上一个 / 播放暂停 / 下一个。
    func controlView() -> some View {
        HStack(spacing: 24) {
            Button("上一个") {
                index = (index - 1 + items.count) % items.count
                Task { await load() }
            }
            Button(state == .playing ? "暂停" : "播放") {
                if entity == nil {
                    Task { await load() }
                } else {
                    state = state == .playing ? .paused : .playing
                }
            }
            Button("停止") {
                state = .stopped
                frameText = "frame: -"
            }
            Button("下一个") {
                index = (index + 1) % items.count
                Task { await load() }
            }
        }
    }
    
    /// 加载当前 index 对应的 svga,加载完成后自动播放。
    @MainActor
    func load() async {
        guard let url = URL(string: items[index]) else { return }
        do {
            entity = try await parser.parse(with: url)
            state = .playing
        } catch {
            print("SVGA 加载失败: \(url), \(error)")
        }
    }
}

#Preview {
    SVGAPrepareView()
}
