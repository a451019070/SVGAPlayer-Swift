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
    
    private var svgaIndex = 0
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        
        
        
//        player.contentMode = .scaleAspectFit
//        view.addSubview(player)
//        player.frame = .init(origin: .zero, size: .init(width: view.bounds.size.width, height: view.bounds.size.width))
//        player.center = view.center
    }
    
    
    @IBAction func changSvga(_ sender: UIButton) {
        
        let items = [
//            Bundle.main.url(forResource: "haveVoice", withExtension: ".svga")!.absoluteString,
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
        guard let url = URL(string: items[svgaIndex % items.count]) else { return }
        svgaIndex += 1

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

