//
//  ViewController.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/15.
//

import UIKit

class ViewController: UIViewController {
    
    
    @IBOutlet weak var player: SVGAPlayer!
    let parser = SVGAParser()
    
    @IBOutlet weak var colorStackView: UIStackView!
    
    let items = [
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
    private var svgaIndex = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.play()
    }
    
    @IBAction func playLast(_ sender: Any) {
        svgaIndex -= 1
        if svgaIndex < 0{
            svgaIndex = items.count - 1
        }
        play()
    }
    
    @IBAction func playNext(_ sender: UIButton) {
        svgaIndex += 1
        play()
    }
    
    
    private func play() {
        guard let url = URL(string: items[svgaIndex % items.count]) else { return }
        Task { [weak self] in
            guard let self else { return }
            do {
                let videoItem = try await self.parser.parse(with: url)
                self.player.setVideoEntity(videoItem)
                self.player.starAnimation()
            } catch { error
                print("SVGA 加载失败: \(url)")
            }
        }
    }
    
    

    @IBAction func changeToWhite(_ sender: UIButton) {
        player.backgroundColor = sender.backgroundColor
        colorStackView.backgroundColor = sender.backgroundColor
    }
    
    @IBAction func changToBlue(_ sender: UIButton) {
        player.backgroundColor = sender.backgroundColor
        colorStackView.backgroundColor = sender.backgroundColor
    }
    
    
    @IBAction func changeToBlack(_ sender: UIButton) {
        player.backgroundColor = sender.backgroundColor
        colorStackView.backgroundColor = sender.backgroundColor
    }
    
    
    @IBAction func changeToGreen(_ sender: UIButton) {
        player.backgroundColor = sender.backgroundColor
        colorStackView.backgroundColor = sender.backgroundColor
    }
    
    
    @IBAction func changeToRed(_ sender: UIButton) {
        player.backgroundColor = sender.backgroundColor
        colorStackView.backgroundColor = sender.backgroundColor
    }
}

extension ViewController{
    
}

