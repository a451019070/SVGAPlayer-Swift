//
//  SVGAAudioEntity.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import Foundation

final class SVGAAudioEntity {
    
    let audioKey: String
    let startFrame: Int
    let endFrame: Int
    let startTime: Int
    
    init(protoObject: SVGAProtoAudioEntity) {
        audioKey = protoObject.audioKey
        startFrame = Int(protoObject.startFrame)
        endFrame = Int(protoObject.endFrame)
        startTime = Int(protoObject.startTime)
    }
    
}
