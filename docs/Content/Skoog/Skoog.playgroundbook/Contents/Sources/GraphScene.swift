//
//  SkoogScene.swift
//  SkoogSwitch
//
//  Created by David Skulina on 06/09/2016.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//

import Foundation
import UIKit
import SpriteKit
import GameplayKit
import AudioToolbox

protocol GraphSceneDelegate: class {
    func touchUp()
    func getReadyToPlay() -> Bool
    //    var showCircle: Bool { get }
}
let dataPoints = 492
let dataPointOffset : CGFloat = 1

public class SkoogGraph: SKShapeNode {
    public var announceAX = true
    var size = CGSize(width: 0.0, height: 0.0)
    var location : CGPoint = CGPoint(x:0, y:0)
    public var sceneDescription : String = "Place holder string"
    fileprivate var activating : Bool = false
    
    static func graph(size: CGSize, lineWidth: CGFloat) -> SkoogGraph {
        let skoogGraph = SkoogGraph(rectOf: size)
        
        skoogGraph.isAccessibilityElement = true
        skoogGraph.position = skoogGraph.location
        skoogGraph.name = "rectangle"
        skoogGraph.strokeColor = .white
        skoogGraph.lineWidth = lineWidth
        skoogGraph.glowWidth = 0.0
        skoogGraph.fillColor = .clear
        
        return skoogGraph
    }
    
    public override func accessibilityActivate() -> Bool {
        if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
            if Skoog.sharedInstance.skoogConnected {
                activating = true
            }
            UIAccessibilityPostNotification(UIAccessibilityLayoutChangedNotification, self)
        }
        return super.accessibilityActivate()
    }
    
    public override var accessibilityLabel : String? {
        set { }
        get {
            if activating {
                return NSLocalizedString("Calibrating the Skoog.", comment: "Calibration AX progress label")
            }
            else {
                return NSLocalizedString("Skoog Graph", comment: "Skoog graph AX string")
            }
        }
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            let summary = UIAccessibilityCustomAction(name: NSLocalizedString("Scene description", comment: "AX action name"), target: self, selector: #selector(sceneSummaryAXAction))
            let orientation = UIAccessibilityCustomAction(name: NSLocalizedString("Skoog orientation", comment: "AX orientation name"), target: self, selector: #selector(skoogOrientationAXAction))
            let announcement = UIAccessibilityCustomAction(name: self.announceAX ? NSLocalizedString("deactivate announcements", comment: "AX deactivata announcement name") : NSLocalizedString("activate announcements", comment: "AX activate announcement name"), target: self, selector: #selector(skoogAnnouncementAXAction))
            let orientationReminder = UIAccessibilityCustomAction(name: NSLocalizedString("Orientation reminder", comment: "AX orientation reminder name"), target: self, selector: #selector(skoogOrientationReminderAXAcation))
            return [summary, orientation, announcement, orientationReminder]
        }
    }
    
    @objc func skoogOrientationReminderAXAcation() {
        let orientationReminder = NSLocalizedString("the layout of the sides is as follows: red facing towards you, blue on the left, yellow facing away from you, green on the right, and orange on top.", comment: "AX orientation reminder prose")
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, orientationReminder)
    }
    
    @objc func skoogOrientationAXAction() {
        let orientation = NSLocalizedString("The Skoog has 5 domed playable sides with a different note on each. To help distinguish the notes, each side has a colored ring, red, blue, yellow, green, and orange. There is a tactile orientation marker on the underside of the Skoog, 9 raised dots in a grid pattern, indicating the position of the yellow side. Use this to orient your Skoog with the yellow side facing away from you. In this orientation, the layout of the sides is as follows: red facing towards you, blue on the left, yellow facing away from you, green on the right, and orange on top.", comment: "AX orientation prose")
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, orientation)
    }
    
    @objc func sceneSummaryAXAction() {
        let sceneDescription = self.sceneDescription
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, sceneDescription)
    }
    
    @objc func skoogAnnouncementAXAction() {
        if self.announceAX {
            self.announceAX = false
        }
        else {
            self.announceAX = true
        }
        let announcement = String(format: "%@ %@", NSLocalizedString("announcements ", comment: "Detailed announcements AX string"), self.announceAX ? NSLocalizedString("activated", comment: "activated AX string") : NSLocalizedString("deactivated", comment: "deactivated AX string"))
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement)
    }
}

public class GraphScene: SKScene {
    weak var graphSceneDelegate:GraphSceneDelegate?
    
    public var lastPoint: CGPoint = CGPoint(x: 0.0, y: 0.0)
    public var newPoint: CGPoint = CGPoint(x: 100.0, y: 100.0)
    
    public var x1Buffer = Array(repeating: 0.0, count: dataPoints)
    public var y1Buffer = Array(repeating: 0.0, count: dataPoints)
    public var x2Buffer = Array(repeating: 0.0, count: dataPoints)
    public var y2Buffer = Array(repeating: 0.0, count: dataPoints)
    public var z1Buffer = Array(repeating: 0.0, count: dataPoints)
    
    public var colorBuffer = Array(repeating: -1, count: dataPoints)
    public var lineArray : [SKShapeNode] = []
    public var lineShapeArray : [SKShapeNode] = []
    public var thresholdLineArray : [SKShapeNode] = []
    public var background : SKShapeNode?
    
    public var squeezeLabelText : String = ""
    public var squeezeLabelAlpha : CGFloat = 0.0
    
    public var songArray : [[[Int]]] = [
        [[0, 3], [2, 3], [4, 3], [6, 3], [7, 4]],
        [[0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [7, 0]],
        [[0, 1], [1, 1], [2, 1], [3, 1], [4, 1], [7, 2]],
        [[0, 0], [1, 0], [2, 0], [3, 0], [4, 0]]
    ]
        
    public var skoogSides : [Side] = []
    
    public var redLineArray = Array(repeating: CGPoint(x: 0, y: 0), count: dataPoints)
    public var redLinePath = CGMutablePath()
    
    public var redCounter : CGFloat = 0.0
    public var notRedCounter : CGFloat = 0.0
    public var redCounterList : [CGFloat] = []
    public var redDashedLinePath = CGMutablePath()
    public var lastLinePath = CGMutablePath()
    
    public var blueLineArray = Array(repeating: CGPoint(x: 0, y: 0), count: dataPoints)
    public var blueLinePath = CGMutablePath()
    
    public var yellowLineArray = Array(repeating: CGPoint(x: 0, y: 0), count: dataPoints)
    public var yellowLinePath = CGMutablePath()
    
    public var greenLineArray = Array(repeating: CGPoint(x: 0, y: 0), count: dataPoints)
    public var greenLinePath = CGMutablePath()
    
    public var orangeLineArray = Array(repeating: CGPoint(x: 0, y: 0), count: dataPoints)
    public var orangeLinePath = CGMutablePath()
    
    public var redSplineShapeNode : SKShapeNode = SKShapeNode()
    public var blueSplineShapeNode : SKShapeNode = SKShapeNode()
    public var yellowSplineShapeNode : SKShapeNode = SKShapeNode()
    public var greenSplineShapeNode : SKShapeNode = SKShapeNode()
    public var orangeSplineShapeNode : SKShapeNode = SKShapeNode()
    
    public var circle : SKShapeNode?
    public var circle2 : SKShapeNode?
    public var line : SKShapeNode?
    public var label : SKLabelNode?
    public var squeezeLabel : SKLabelNode?
    public var peakLine : SKShapeNode?

    public var peakLabel : SKLabelNode?
    
    public var rectangle: SkoogGraph?
    public var rectangleInner: SKShapeNode?
    
    public var calibrationCircle : SKShapeNode?
    
    public var thresholdArray = Array(repeating: 0.0, count: 5)
    
    public var xCalib = 0.0
    public var yCalib = 0.0
    public var zCalib = 0.0
    public var x = 0.0
    public var y = 0.0
    public var z = 0.0
    public var dt : TimeInterval = 0.0
    public var deltaX = CGFloat(0.0)
    public var deltaY = CGFloat(0.0)
    public var deltaZ = CGFloat(0.0)
    public var magnitude = CGFloat(0.0)
    public var R = CGFloat(0.0)
    public var zangle = CGFloat(0.0)
    public var angle = CGFloat(0.0)
    public var XZangle = CGFloat(0.0)
    public var YZangle = CGFloat(0.0)
    public var peak : Peak? = Peak.sharedInstance
    public var Mpeak : Double? = 0.0
    public let thresh = 3.0
    public var active = false
    public var durationMultiplier = 1.0
    public var lineWidth : CGFloat = 2.0
    public var graphLineWidth : CGFloat = 1.0
    public var glowAmount : CGFloat = 10.0
    public var drawCircle = true
    public var drawSong = false
    
    let graphHeight = dataPoints
    public var scaleFactor : CGFloat = 1.0
    let centrePoint = 0.0
    
    public let colors : [SKColor] = [   SKColor(red: 218.0/255.0, green: 60.0/255.0, blue: 0.0, alpha: 1.0),         // red
        SKColor(red: 55.0/255.0, green: 127.0/255.0, blue: 178.0/255.0, alpha: 1.0),   // blue
        SKColor(red: 250.0/255.0, green: 217.0/255.0, blue: 0.0, alpha: 1.0),          // yellow
        SKColor(red: 163.0/255.0, green: 203.0/255.0, blue: 0.0, alpha: 1.0),          // green
        SKColor(red: 249.0/255.0, green: 154.0/255.0, blue: 0.0, alpha: 1.0)]          // orange
    
    private var calibTick = 0
    var counter = 0
//    var timer : Timer?
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
        self.backgroundColor = skoogWhite
        
        self.background = SKShapeNode(rectOf: CGSize(width: 1200, height: 1200))
        self.background?.zPosition = -500
        self.background?.lineWidth = 0
        self.background?.alpha = 0.1
        self.background?.fillShader = linearShader(color: .orange, endColor: .purple)
        
        background?.name = "background"
        self.addChild(background!)
        
        self.rectangle = SkoogGraph.graph(size: CGSize(width: CGFloat(dataPoints), height: CGFloat(graphHeight)), lineWidth: self.lineWidth)
        self.rectangle?.zPosition = 50
        let xrange = SKRange(lowerLimit: 0, upperLimit: 0)
        let yrange = SKRange(lowerLimit: 0, upperLimit: 0)
        let lockToCenter = SKConstraint.positionX(xrange, y:yrange)
        self.rectangle?.constraints = [ lockToCenter ]
        self.addChild(self.rectangle!)
        let yoffset = -(graphHeight / 2)
        let xOffset = -(graphHeight / 2)
        
        self.rectangleInner = SKShapeNode(rectOf: CGSize(width: CGFloat(dataPoints), height: CGFloat(graphHeight)))
        self.rectangleInner?.zPosition = 10
        self.rectangleInner?.lineWidth = 0.0
        self.rectangleInner?.fillColor = UIColor.white.withAlphaComponent(0.4)
        self.rectangleInner?.constraints = [ lockToCenter ]
        self.addChild(self.rectangleInner!)
        
        drawThresholds()
        
        for i in 0..<dataPoints {
            redLineArray[i].x = CGFloat(xOffset  + i)
            redLineArray[i].y = CGFloat(yoffset)
            
            blueLineArray[i].x = CGFloat(xOffset + i)
            blueLineArray[i].y = CGFloat(yoffset)
            
            yellowLineArray[i].x = CGFloat(xOffset + i)
            yellowLineArray[i].y = CGFloat(yoffset)
            
            greenLineArray[i].x = CGFloat(xOffset + i)
            greenLineArray[i].y = CGFloat(yoffset)
            
            orangeLineArray[i].x = CGFloat(xOffset + i)
            orangeLineArray[i].y = CGFloat(yoffset)
        }
        
        self.circle	= makeCircle(location:CGPoint(x:0,y:0), radius: 80, color: .darkGray)
        self.circle!.alpha = CGFloat(0.0)
        self.circle!.zPosition = 100
        self.circle!.fillColor = .darkGray
        
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x:0,y:0), radius: 120, startAngle: 0, endAngle: 0, clockwise: true) //
        self.calibrationCircle = SKShapeNode(path: path)
        self.calibrationCircle!.zRotation = CGFloat.pi / 2
        self.calibrationCircle!.zPosition = 50
        
        
        self.calibrationCircle?.lineWidth = 0
        self.calibrationCircle?.fillColor = .white
        self.calibrationCircle?.strokeColor = .clear
        self.calibrationCircle?.glowWidth = 10
        
        self.addChild(self.calibrationCircle!)
        
        self.redLinePath.addLines(between: redLineArray)
        self.redSplineShapeNode = SKShapeNode(path: self.redLinePath)
        self.redSplineShapeNode.strokeColor = colors[0] // .red
        self.redSplineShapeNode.fillColor = colors[0]
        self.redSplineShapeNode.lineWidth = self.graphLineWidth
        self.redSplineShapeNode.alpha = 0.8
        self.redSplineShapeNode.zPosition = 20
        self.redSplineShapeNode.isAntialiased = true
        
        
        self.blueLinePath.addLines(between: blueLineArray)
        self.blueSplineShapeNode = SKShapeNode(path: self.blueLinePath)
        self.blueSplineShapeNode.strokeColor = colors[1] //.blue
        self.blueSplineShapeNode.fillColor = colors[1]
        self.blueSplineShapeNode.lineWidth = self.graphLineWidth
        self.blueSplineShapeNode.alpha = 0.8
        self.blueSplineShapeNode.zPosition = 20
        self.blueSplineShapeNode.isAntialiased = true
        
        self.yellowLinePath.addLines(between: yellowLineArray)
        self.yellowSplineShapeNode = SKShapeNode(path: self.yellowLinePath)
        self.yellowSplineShapeNode.strokeColor = colors[2] //.green
        self.yellowSplineShapeNode.fillColor = colors[2]
        self.yellowSplineShapeNode.lineWidth = self.graphLineWidth
        self.yellowSplineShapeNode.alpha = 0.8
        self.yellowSplineShapeNode.zPosition = 20
        self.yellowSplineShapeNode.isAntialiased = true
        
        self.greenLinePath.addLines(between: greenLineArray)
        self.greenSplineShapeNode = SKShapeNode(path: self.greenLinePath)
        self.greenSplineShapeNode.strokeColor = colors[3] //.white //colors[3]
        self.greenSplineShapeNode.fillColor = colors[3]
        self.greenSplineShapeNode.lineWidth = self.graphLineWidth
        self.greenSplineShapeNode.alpha = 0.8
        self.greenSplineShapeNode.zPosition = 20
        self.greenSplineShapeNode.isAntialiased = true
        
        self.orangeLinePath.addLines(between: orangeLineArray)
        self.orangeSplineShapeNode = SKShapeNode(path: self.orangeLinePath)
        self.orangeSplineShapeNode.strokeColor = colors[4] // .black //colors[4]
        self.orangeSplineShapeNode.fillColor = colors[4]
        self.orangeSplineShapeNode.lineWidth = self.graphLineWidth
        self.orangeSplineShapeNode.alpha = 0.8
        self.orangeSplineShapeNode.zPosition = 20
        self.orangeSplineShapeNode.isAntialiased = true
        
        self.addChild(self.redSplineShapeNode)
        self.addChild(self.blueSplineShapeNode)
        self.addChild(self.yellowSplineShapeNode)
        self.addChild(self.greenSplineShapeNode)
        self.addChild(self.orangeSplineShapeNode)
        
        let label = SKLabelNode()
        label.position = CGPoint(x:0,y:0)
        label.fontColor = .white
        label.fontName = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.thin).fontName
        self.addChild(label)
        self.label = label
        self.label!.zPosition = 150
        self.label!.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        
        let squeezeLabel = SKLabelNode(text: "Yellow 0.00 ") //initialise text and pad with an extra space so we can get the size
        squeezeLabel.position = CGPoint(x:-0.5 * squeezeLabel.frame.size.width,y:-280)
        squeezeLabel.fontColor = .black
        squeezeLabel.fontName = UIFont.systemFont(ofSize: 16.0, weight: UIFont.Weight.light).fontName
        squeezeLabel.accessibilityTraits = UIAccessibilityTraitUpdatesFrequently
        

        self.addChild(squeezeLabel)
        self.squeezeLabel = squeezeLabel
        self.squeezeLabel!.zPosition = 150
        self.squeezeLabel!.alpha = 0.01

        self.squeezeLabel!.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        self.squeezeLabel!.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left

        self.squeezeLabel!.constraints = [SKConstraint.positionX(SKRange(lowerLimit: -0.5 * squeezeLabel.frame.size.width,
                                                                         upperLimit: -0.5 * squeezeLabel.frame.size.width))]

        let peakLabel = SKLabelNode()
        peakLabel.position = CGPoint(x:0,y:0)
        peakLabel.color = .white
        self.addChild(peakLabel)
        self.peakLabel = peakLabel
        
        
    }
    public override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        let h = self.frame.height
        let w = self.frame.width
        let smallestDimension : CGFloat = h > w ? w : h //- 88
        
        let newScale = (smallestDimension - 20.0) / CGFloat(dataPoints)
        self.scaleFactor = 1.0
        

        self.rectangleInner?.run(SKAction.scale(to: newScale, duration: 0.1))
        self.rectangle?.run(SKAction.scale(to: newScale, duration: 0.1)){
            
            //            self.updateDataPoints()
        }

        self.redSplineShapeNode.run(SKAction.scale(to: newScale, duration: 0.1))
        self.blueSplineShapeNode.run(SKAction.scale(to: newScale, duration: 0.1))
        self.yellowSplineShapeNode.run(SKAction.scale(to: newScale, duration: 0.1))
        self.greenSplineShapeNode.run(SKAction.scale(to: newScale, duration: 0.1))
        self.orangeSplineShapeNode.run(SKAction.scale(to: newScale, duration: 0.1))
        
        if self.thresholdLineArray.count > 0 {
            for i in 0...4 {
                self.thresholdLineArray[i].run(SKAction.scale(to: newScale, duration: 0.1))
            }
        }
    }
    
    public override func didApplyConstraints(){
        self.updateThresholds()
    }

    public func updateThresholds() {
        let height = (self.rectangle?.frame.height)!
        
        let yoffset = (self.rectangle?.position.y)! - (self.rectangle?.frame.height)! * CGFloat(0.5)
        for i in 0...4 {
            self.thresholdLineArray[i].position.y = yoffset + height * CGFloat(self.skoogSides[i].threshold)
        }
    }
    
    public func drawThresholds() {
        let height = (self.rectangle?.frame.height)!
        
        let yoffset = (self.rectangle?.position.y)! - (self.rectangle?.frame.height)! * CGFloat(0.5)
        for i in 0...4 {
            let dash_line = makeDashedLine(yPosition: yoffset + (height * CGFloat(0.0)), color: colors[i])
            self.thresholdLineArray.append(dash_line)
        }
    }
    
    func makeRectangle(location: CGPoint, size: CGSize, color: SKColor) ->SKShapeNode {
        let Rectangle = SKShapeNode(rectOf: size) // Size of Circle = Radius setting.
        Rectangle.position = location  //touch location passed from touchesBegan.
        Rectangle.name = "rectangle"
        Rectangle.strokeColor = color
        Rectangle.lineWidth = self.lineWidth
        Rectangle.glowWidth = 0.0
        Rectangle.fillColor = .clear
        self.addChild(Rectangle)
        return Rectangle
    }
    
    /////////////////////////////////////////////////////////////////////////
    // MARK: - Shader Code
    /////////////////////////////////////////////////////////////////////////
    
    public func radialShader(color: UIColor, endColor: UIColor? = nil) -> SKShader {
        let outerColor = color.vectorFloat4Value
        
        var innerColor : vector_float4
        if endColor == nil {
            innerColor = color.lighter(by: 30).vectorFloat4Value
        }
        else {
            innerColor = endColor!.vectorFloat4Value
        }
        
        let shader = SKShader(fileNamed: "RadialGradient.fsh")
        shader.uniforms = [SKUniform(name: "outerColor", vectorFloat4: outerColor),
                           SKUniform(name: "innerColor", vectorFloat4: innerColor)]
        return shader
    }
    
    public func linearShader(color: UIColor, endColor: UIColor? = nil) -> SKShader {
        var myStartColor : vector_float4
        var myEndColor : vector_float4
        if endColor == nil {
            myStartColor = color.darker(by: 10).vectorFloat4Value
            myEndColor = color.lighter(by: 40).vectorFloat4Value
        }
        else {
            myStartColor = color.vectorFloat4Value
            myEndColor = endColor!.vectorFloat4Value
        }
        
        let shader = SKShader(fileNamed: "LinearGradient.fsh")
        shader.uniforms = [SKUniform(name: "startColor", vectorFloat4: myStartColor),
                           SKUniform(name: "endColor", vectorFloat4: myEndColor)]
        return shader
    }
    
    func makeDashedLine(yPosition: CGFloat, color: SKColor) ->SKShapeNode {
        var points = [CGPoint(x: -244, y: 0), CGPoint(x: 244, y: 0)]
        let line = SKShapeNode(points: &points, count: points.count)
        let pattern : [CGFloat] = [2.0, 4.0]
        
        let DashedLinePath = line.path?.copy(dashingWithPhase: 0, lengths: pattern)
        let DashedLine = SKShapeNode(path: DashedLinePath!)
        DashedLine.position = CGPoint(x: 12.0, y: yPosition)
        DashedLine.fillColor = yPosition == 0.0 ? .clear : color
        DashedLine.strokeColor = yPosition == 0.0 ? .clear : color
        DashedLine.lineWidth = self.lineWidth
        DashedLine.zPosition = 50
        self.addChild(DashedLine)
        
        let xrange = SKRange(lowerLimit: 0, upperLimit: 0)
        let lockToCenter = SKConstraint.positionX(xrange)
        DashedLine.constraints = [ lockToCenter ]
        
        return DashedLine
    }
    
    func makeCircle(location: CGPoint, radius: CGFloat, color: SKColor) ->SKShapeNode{
        let Circle = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
        Circle.position = location  //touch location passed from touchesBegan.
        Circle.name = "circle"
        Circle.strokeColor = color
        Circle.lineWidth = self.lineWidth
        Circle.glowWidth = 0.0
        Circle.fillColor = .clear
        self.addChild(Circle)
        return Circle
    }
    
    public func animateCalibration() {
        self.calibrationCircle!.path = nil
        label?.text = NSLocalizedString("Calibrating", comment: "Calibration progress label")
        label?.alpha = CGFloat(1.0)
        self.calibrationCircle!.setScale(1.0)
        self.calibrationCircle!.alpha = CGFloat(1.0)
        self.circle!.alpha = CGFloat(1.0)
        
        let radius : CGFloat = 120
        let duration = 2.0
        let steps = 320
        let timeInterval = duration/TimeInterval(steps)
        let incr = CGFloat(1) / CGFloat(steps)
        var percent = CGFloat(0.0)
        
        let animate = SKAction.run {
            percent += incr
            self.calibrationCircle!.path = self.calibrationArc(radius: radius, percent:percent)
        }
        let wait = SKAction.wait(forDuration:timeInterval)
        let action = SKAction.sequence([wait, animate])
        
        run(SKAction.repeat(action,count:steps)) {
            self.run(SKAction.wait(forDuration:timeInterval)) {
                let fade = SKAction.fadeOut(withDuration: 0.5)
                let shrink = SKAction.scale(by: 0.67, duration: 0.5)
                let FadeScaleSequence = SKAction.group([fade, shrink])
                self.calibrationCircle!.run(FadeScaleSequence)
                self.label?.run(fade) {
                    self.label?.text = ""
                }
                self.circle!.run(fade) {
                    if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Calibration complete", comment: "Calibration complete AX text"))
                        self.rectangle?.activating = false
                    }
                }
            }
        }
    }
    
    // Creates a CGPath in the shape of a pie with slices missing
    public func calibrationArc(radius:CGFloat, percent:CGFloat) -> CGPath {
        let start:CGFloat = CGFloat.pi * 2
        let end = CGFloat.pi * 2 - (CGFloat.pi * 2 * percent)
        let center = CGPoint.zero
        let newPath = CGMutablePath()
        newPath.move(to:center)
        newPath.addArc(center: CGPoint(x:0,y:0), radius: radius, startAngle: start, endAngle: end, clockwise: true)
        newPath.addLine(to: CGPoint(x:0,y:0))
        return newPath
    }
    
    public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    public override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    
    func touchDown(atPoint pos : CGPoint) {
    }
    
    func touchMoved(toPoint pos : CGPoint) {
    }
    
    func touchUp(atPoint pos : CGPoint) {
        if Skoog.sharedInstance.skoogConnected {
            animateCalibration()
            graphSceneDelegate?.touchUp()
        }
    }
    
    public func setLineWidth(width: Double) {
        self.lineWidth = CGFloat(width)
    }
    
    public func setGlow(amount: Double) {
        self.glowAmount = CGFloat(amount)
    }
    
    public func addDataPoint(side: Int, value: Double) {
        if graphSceneDelegate!.getReadyToPlay() {
            if value > 0.0 {
                colorBuffer.remove(at: dataPoints-2)
                colorBuffer.insert(side, at: 1)
                
                if value > 0.0 {
                    for i in 0...4 {
                        if i != side {
                            self.thresholdLineArray[i].strokeColor = .clear
                        }
                        else {
                            self.thresholdLineArray[i].strokeColor = colors[i]
                            
                        }
                    }
                }
                
//                let height = (self.rectangle?.frame.height)!  - 3 * (self.lineWidth * self.scaleFactor) /* CGFloat(0.5.squareRoot())*/
//                
//                let yOffset = (self.rectangle?.position.y)! - (self.rectangle?.frame.height)! / 2 + (self.lineWidth * self.scaleFactor)
//                let xOffset = (self.rectangle?.position.x)! - (self.rectangle?.frame.width)! / 2 + (self.lineWidth * self.scaleFactor)
                
                let height : CGFloat = CGFloat(dataPoints) * self.scaleFactor
                let yOffset : CGFloat = -(CGFloat(dataPoints) / 2.0) * self.scaleFactor
                let xOffset = yOffset
                
                x1Buffer.remove(at: dataPoints-2)
                x1Buffer.insert(side == 0 ? value : 0.0, at: 1)
                redLineArray.remove(at: dataPoints-2)
                redLineArray.insert(CGPoint(x: xOffset, y: yOffset + (height * CGFloat(x1Buffer[1]))), at: 1)
                
                y1Buffer.remove(at: dataPoints-2)
                y1Buffer.insert(side == 1 ? value : 0.0, at: 1)
                blueLineArray.remove(at: dataPoints-2)
                blueLineArray.insert(CGPoint(x: xOffset, y: yOffset + (height * CGFloat(y1Buffer[1]))), at: 1)
                
                x2Buffer.remove(at: dataPoints-2)
                x2Buffer.insert(side == 2 ? value : 0.0, at: 1)
                yellowLineArray.remove(at: dataPoints-2)
                yellowLineArray.insert(CGPoint(x: xOffset, y: yOffset + (height * CGFloat(x2Buffer[1]))), at: 1)
                
                y2Buffer.remove(at: dataPoints-2)
                y2Buffer.insert(side == 3 ? value : 0.0, at: 1)
                greenLineArray.remove(at: dataPoints-2)
                greenLineArray.insert(CGPoint(x: xOffset, y: yOffset + (height * CGFloat(y2Buffer[1]))), at: 1)
                
                z1Buffer.remove(at: dataPoints-2)
                z1Buffer.insert(side == 4 ? value : 0.0, at: 1)
                orangeLineArray.remove(at: dataPoints-2)
                orangeLineArray.insert(CGPoint(x: xOffset, y: yOffset + (height * CGFloat(z1Buffer[1]))), at: 1)
                
                for i in 1 ..< dataPoints-2 {
                    redLineArray[i].x = redLineArray[i].x + (dataPointOffset * self.scaleFactor)
                    blueLineArray[i].x = blueLineArray[i].x + (dataPointOffset * self.scaleFactor)
                    yellowLineArray[i].x = yellowLineArray[i].x + (dataPointOffset * self.scaleFactor)
                    greenLineArray[i].x = greenLineArray[i].x + (dataPointOffset * self.scaleFactor)
                    orangeLineArray[i].x = orangeLineArray[i].x + (dataPointOffset * self.scaleFactor)
                }
            }
        }
    }
    public func updateDataPoints() {
//        let xOffset = (self.rectangle?.position.x)! - (self.rectangle?.frame.width)! / 2 + (self.lineWidth * self.scaleFactor)
//        let yOffset = (self.rectangle?.position.y)! - (self.rectangle?.frame.height)! / 2 + (self.lineWidth * self.scaleFactor)
        let yOffset : CGFloat = -(492.0 / 2.0) * self.scaleFactor
        let xOffset = yOffset
        
        for i in 0..<dataPoints {
            x1Buffer[i] = 0.0
            y1Buffer[i] = 0.0
            x2Buffer[i] = 0.0
            y2Buffer[i] = 0.0
            z1Buffer[i] = 0.0
            let addition = CGFloat(i)
            redLineArray[i].x = CGFloat(xOffset  + (addition * self.scaleFactor))
            redLineArray[i].y = CGFloat(yOffset)
            
            blueLineArray[i].x = CGFloat(xOffset + (addition * self.scaleFactor))
            blueLineArray[i].y = CGFloat(yOffset)
            
            yellowLineArray[i].x = CGFloat(xOffset + (addition * self.scaleFactor))
            yellowLineArray[i].y = CGFloat(yOffset)
            
            greenLineArray[i].x = CGFloat(xOffset + (addition * self.scaleFactor))
            greenLineArray[i].y = CGFloat(yOffset)
            
            orangeLineArray[i].x = CGFloat(xOffset + (addition * self.scaleFactor))
            orangeLineArray[i].y = CGFloat(yOffset)
        }
    }
    
    public override func update(_ currentTime: TimeInterval) {
        self.redLinePath = CGMutablePath()
        self.blueLinePath = CGMutablePath()
        self.yellowLinePath = CGMutablePath()
        self.greenLinePath = CGMutablePath()
        self.orangeLinePath = CGMutablePath()
        
        self.redLinePath.addLines(between: redLineArray)
        self.blueLinePath.addLines(between: blueLineArray)
        self.yellowLinePath.addLines(between: yellowLineArray)
        self.greenLinePath.addLines(between: greenLineArray)
        self.orangeLinePath.addLines(between: orangeLineArray)
        
        self.redSplineShapeNode.path = self.redLinePath
        self.blueSplineShapeNode.path = self.blueLinePath
        self.yellowSplineShapeNode.path = self.yellowLinePath
        self.greenSplineShapeNode.path = self.greenLinePath
        self.orangeSplineShapeNode.path = self.orangeLinePath
        
        self.squeezeLabel?.text = self.squeezeLabelText
        self.squeezeLabel?.alpha = self.squeezeLabelAlpha
    }
}
