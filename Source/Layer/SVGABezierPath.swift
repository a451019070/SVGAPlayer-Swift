//
//  SVGABezierPath.swift
//  SVGAPlayer-Swift
//
//  Created by ZX on 2026/10/16.
//

import UIKit

/// 解析 SVG path 字符串(如 "M0 0 L10 10 Z")的 UIBezierPath。
/// 解析是延迟的:`setValues` 只在 `createLayer` 之后才真正执行,之前仅缓存字符串。
final class SVGABezierPath: UIBezierPath {
    
    private static let validMethods: Set<Character> = Set("MLHVCSQRAZmlhvcsqraz")
    
    private var displaying = false
    private var backValues: String?
    
    func setValues(_ values: String) {
        guard displaying else {
            backValues = values
            return
        }
        var values = values.replacingOccurrences(of: "([a-zA-Z])", with: "|||$1 ", options: .regularExpression)
        values = values.replacingOccurrences(of: ",", with: " ")
        for segment in values.components(separatedBy: "|||") {
            guard let method = segment.first, Self.validMethods.contains(method) else { continue }
            let args = segment.dropFirst()
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .components(separatedBy: " ")
            operate(method, args: args)
        }
    }
    
    func createLayer() -> CAShapeLayer {
        if !displaying {
            displaying = true
            if let backValues {
                setValues(backValues)
            }
        }
        let layer = CAShapeLayer()
        layer.path = cgPath
        layer.fillColor = UIColor.black.cgColor
        return layer
    }
    
    private func operate(_ method: Character, args: [String]) {
        let relative = method.isLowercase
        
        func value(_ index: Int) -> CGFloat {
            CGFloat((args[index] as NSString).floatValue)
        }
        
        switch Character(method.uppercased()) {
        case "M":
            guard args.count == 2 else { return }
            move(to: point(x: value(0), y: value(1), relative: relative))
        case "L":
            guard args.count == 2 else { return }
            addLine(to: point(x: value(0), y: value(1), relative: relative))
        case "C":
            guard args.count == 6 else { return }
            let control1 = point(x: value(0), y: value(1), relative: relative)
            let control2 = point(x: value(2), y: value(3), relative: relative)
            let end = point(x: value(4), y: value(5), relative: relative)
            addCurve(to: end, controlPoint1: control1, controlPoint2: control2)
        case "Q":
            guard args.count == 4 else { return }
            let control = point(x: value(0), y: value(1), relative: relative)
            let end = point(x: value(2), y: value(3), relative: relative)
            addQuadCurve(to: end, controlPoint: control)
        case "H":
            guard args.count == 1 else { return }
            let x = value(0) + (relative ? currentPoint.x : 0)
            addLine(to: CGPoint(x: x, y: currentPoint.y))
        case "V":
            guard args.count == 1 else { return }
            let y = value(0) + (relative ? currentPoint.y : 0)
            addLine(to: CGPoint(x: currentPoint.x, y: y))
        case "Z":
            close()
        default:
            break
        }
    }
    
    private func point(x: CGFloat, y: CGFloat, relative: Bool) -> CGPoint {
        relative ? CGPoint(x: x + currentPoint.x, y: y + currentPoint.y) : CGPoint(x: x, y: y)
    }
    
}
