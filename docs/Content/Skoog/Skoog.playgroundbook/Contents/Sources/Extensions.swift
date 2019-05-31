//
//  Extensions.swift
//  PlaygroundContent
//
//  Created by Keith Nagle on 25/04/2017.
//  Copyright © 2017 Skoogmusic Ltd. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit

extension ClosedRange {
    func clamp(value : Bound) -> Bound {
        return self.lowerBound > value ? self.lowerBound
            : self.upperBound < value ? self.upperBound
            : value
    }
}

public func >(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left > rightSide
}

public func >(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left > rightSide
}

public func <(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left < rightSide
}

public func <(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left < rightSide
}

public func >=(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left >= rightSide
}

public func >=(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left >= rightSide
}

public func <=(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left <= rightSide
}

public func <=(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left <= rightSide
}

public func ==(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left == rightSide
}

public func ==(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left == rightSide
}

public func !=(left: Double, right: Int)->Bool {
    let rightSide = Double(right)
    return left != rightSide
}

public func !=(left: Int, right: Double)->Bool {
    let rightSide = Int(right)
    return left != rightSide
}

extension String {
    var first: String {
        return String(prefix(1))
    }
    var last: String {
        return String(suffix(1))
    }
    var uppercaseFirst: String {
        return first.uppercased() + String(dropFirst())
    }
}


extension UIColor {
    /**
     Create a ligher color
     */
    func lighter(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: abs(percentage))
    }
    
    /**
     Create a darker color
     */
    func darker(by percentage: CGFloat = 30.0) -> UIColor {
        return self.adjustBrightness(by: -abs(percentage))
    }
    
    /**
     Try to increase brightness or decrease saturation
     */
    func adjustBrightness(by percentage: CGFloat = 30.0) -> UIColor {
        var h: CGFloat = 0, s: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getHue(&h, saturation: &s, brightness: &b, alpha: &a) {
            if b < 1.0 {
                let newB: CGFloat = max(min(b + (percentage/100.0)*b, 1.0), 0,0)
                return UIColor(hue: h, saturation: s, brightness: newB, alpha: a)
            } else {
                let newS: CGFloat = min(max(s - (percentage/100.0)*s, 0.0), 1.0)
                return UIColor(hue: h, saturation: newS, brightness: b, alpha: a)
            }
        }
        return self
    }
    
    /**
     Return the vector4 value
     */
    var vectorFloat4Value : vector_float4{
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        if self.getRed(&r, green: &g, blue: &b, alpha: &a) {
            return vector_float4(Float(r),Float(g),Float(b),Float(a))
        }
        else {
            return vector_float4(Float(r),Float(g),Float(b),Float(a))
        }
    }
    
    func blend(color: UIColor, alpha: CGFloat = 0.5) -> UIColor {

            var (r1, g1, b1, a1): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            var (r2, g2, b2, a2): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
            
            self.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
            color.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
            
            return UIColor(red: 0.5 * (r1 + r2), green: 0.5 * (g1 + g2), blue: 0.5 * (b1 + b2), alpha: (a1 + alpha * a2) / (1.0 + alpha) )
        }
}

extension UIView {
    func startRotating(duration: Double = 1) {
        let kAnimationKey = "rotation"
        
        if self.layer.animation(forKey: kAnimationKey) == nil {
            let animate = CABasicAnimation(keyPath: "transform.rotation")
            animate.duration = duration
            animate.repeatCount = Float.infinity
            animate.fromValue = 0.0
            animate.toValue = .pi * 2.0
            self.layer.add(animate, forKey: kAnimationKey)
        }
    }
    func stopRotating() {
        let kAnimationKey = "rotation"
        
        if self.layer.animation(forKey: kAnimationKey) != nil {
            self.layer.removeAnimation(forKey: kAnimationKey)
        }
    }
}

