//
//  SVGAAudioLayer.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/19.
//

import AVFoundation

final class SVGAAudioLayer {
    
    let audioItem: SVGAAudioEntity
    private(set) var audioPlayer: AVAudioPlayer?
    var audioPlaying = false
    
    init(audioItem: SVGAAudioEntity, videoItem: SVGAVideoEntity) {
        self.audioItem = audioItem
        if let data = videoItem.audiosData[audioItem.audioKey] {
            audioPlayer = try? AVAudioPlayer(data: data, fileTypeHint: "mp3")
            audioPlayer?.prepareToPlay()
        }
    }
    
}
