//
//  SkoogLabel.swift
//  PlaygroundContent
//
//  Created by David Skulina on 03/05/2017.
//  Copyright © 2017 Skoogmusic Ltd. All rights reserved.
//

import Foundation
import SpriteKit



public class SkoogLabel: SKShapeNode {
    
    public let image = SKSpriteNode(imageNamed: "musical_notes")
    public var label = SKLabelNode(fontNamed: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.light).fontName)
    public var value = SKLabelNode(fontNamed: UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.semibold).fontName)
    public var imagePadding : CGFloat = 8.0
    public var valuePadding : CGFloat = 8.0
    public var showImage : Bool = true
    public var needsUpdate: Bool = false
    public var labelUpdate: String? = nil
    public var valueUpdate: String? = nil
    public var alphaUpdate: CGFloat? = nil
    public var colorUpdate: UIColor? = nil
    public var alignMode = 0
    //public var positionUpdate = CGPoint? = nil
    
    public override var accessibilityLabel : String? {
        set { }
        get {
            return String(format: "%@ %@", self.label.text!, self.value.text!)
        }
    }

    public func setLabel(text : String){
        self.label.text = text
        self.value.position = CGPoint(x:self.label.position.x + self.label.frame.width, y: self.label.position.y)
    }
    
    public func setValue(text : String){
        self.value.text = text
    }
    
    public func setImageColor(color : UIColor){
        self.image.color = color
    }
    
    public func setLabelUpdate(text : String){
        labelUpdate = text
        needsUpdate = true
    }
    
    public func setValueUpdate(text : String){
        valueUpdate = text
        needsUpdate = true
    }

    public func setAlphaUpdate(alpha : CGFloat){
        alphaUpdate = alpha
        needsUpdate = true
    }
    
    public func setColorUpdate(color : UIColor){
        colorUpdate = color
        needsUpdate = true
    }
    
    public func setFontColor(color : UIColor){
        self.label.fontColor = color
        self.value.fontColor = color
    }
    
    public func centerX(){
        self.position = CGPoint(x: -0.5 * (self.image.frame.width + self.label.frame.width + self.value.frame.width), y: self.position.y)
    }
    
    public func alignCenter(){
        if showImage {
            self.position = CGPoint(x: -(self.image.frame.width + self.label.frame.width) + valuePadding, y: self.position.y)
        }
        else {
            self.position = CGPoint(x: -self.label.frame.width + valuePadding, y: self.position.y)
        }
    }
    
    public func getSize() -> CGSize {
    
        return CGSize(width: self.image.frame.width + self.label.frame.width + self.value.frame.width,
                                  height: self.image.frame.height + self.label.frame.height + self.value.frame.height)
    }
    
    
    public func update(){
        if labelUpdate != nil {
            label.text = labelUpdate!
            value.position = CGPoint(x:label.position.x + label.frame.width + valuePadding, y: label.position.y)
            labelUpdate = nil
        }
        if valueUpdate != nil {
            value.text = valueUpdate!
            valueUpdate = nil
        }
        if alphaUpdate != nil {
            self.alpha = alphaUpdate!
            alphaUpdate = nil
        }
        if colorUpdate != nil {
            label.fontColor = colorUpdate!
            value.fontColor = colorUpdate!
            colorUpdate = nil
        }
        switch(alignMode){
        case 0:
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            centerX()
        case 1:
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            alignCenter()
        default:
            label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            centerX()
        }
        needsUpdate = false
    }
    
    static func label(showImage: Bool = true, fontColor: UIColor = .black, imageColor: UIColor = .white) -> SkoogLabel {
        let skoogLabel = SkoogLabel(rectOf: CGSize(width: 200, height: 60))
        
        skoogLabel.lineWidth = 1.0
        if showImage {
            skoogLabel.image.position = CGPoint(x:0,y:0)
            skoogLabel.image.color = imageColor
            skoogLabel.image.colorBlendFactor = 1.0
            skoogLabel.addChild(skoogLabel.image)
            
            skoogLabel.label.text = "LABEL"
            skoogLabel.label.fontSize = 30
            skoogLabel.label.fontColor = fontColor
            skoogLabel.label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.baseline
            skoogLabel.label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            skoogLabel.addChild(skoogLabel.label)
            
            skoogLabel.value.text = "XX(YY)"
            skoogLabel.value.fontSize = 30
            skoogLabel.value.fontColor = fontColor
            skoogLabel.value.verticalAlignmentMode = SKLabelVerticalAlignmentMode.baseline
            skoogLabel.value.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            skoogLabel.addChild(skoogLabel.value)
            skoogLabel.name = "skoog_label"
            
            skoogLabel.label.position = CGPoint(x:skoogLabel.imagePadding + skoogLabel.image.frame.width / 2, y: 4 - skoogLabel.image.frame.height / 2 )
            skoogLabel.value.position = CGPoint(x:skoogLabel.label.position.x + skoogLabel.label.frame.width, y: 4 - skoogLabel.image.frame.height / 2)
        }
        else {
            skoogLabel.label.text = "LABEL"
            skoogLabel.label.fontSize = 30
            skoogLabel.label.fontColor = fontColor
            skoogLabel.label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
            skoogLabel.label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            skoogLabel.addChild(skoogLabel.label)
            
            skoogLabel.value.text = "XX(YY)"
            skoogLabel.value.fontSize = 30
            skoogLabel.value.fontColor = fontColor
            skoogLabel.value.verticalAlignmentMode = SKLabelVerticalAlignmentMode.top
            skoogLabel.value.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
            skoogLabel.addChild(skoogLabel.value)
            skoogLabel.name = "skoog_label"
            
            skoogLabel.label.position = CGPoint(x:0, y:0)
            skoogLabel.value.position = CGPoint(x:skoogLabel.label.frame.width, y: 0)
        }
        skoogLabel.centerX()
        
        skoogLabel.strokeColor = .clear
        
        skoogLabel.isUserInteractionEnabled = true
        skoogLabel.isAccessibilityElement = true
        skoogLabel.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently
        skoogLabel.label.isUserInteractionEnabled = true
        skoogLabel.label.isAccessibilityElement = true
        skoogLabel.label.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently
        skoogLabel.value.isUserInteractionEnabled = true
        skoogLabel.value.isAccessibilityElement = true
        skoogLabel.value.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently
        
        return skoogLabel
    }
}
