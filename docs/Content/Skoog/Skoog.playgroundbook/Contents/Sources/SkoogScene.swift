//
//  SkoogScene.swift
//  SkoogSwitch
//
//  Created by David Skulina on 06/09/2016.
//  Copyright © 2017 Skoogmusic Ltd. All rights reserved.
//

import Foundation
import SpriteKit
import GameplayKit
import AudioToolbox
import UIKit

let skoogDarkGrey = SKColor(red: 38.0/255.0, green: 44.0/255.0, blue: 38.0/255.0, alpha: 1.0)
let skoogWhite = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
let swiftRed = SKColor(red: 234.0/255.0, green: 91.0/255.0, blue: 51.0/255.0, alpha: 1.0)

struct PhysicsCategory {
	static let None     : UInt32 = 0
	static let All      : UInt32 = UInt32.max
	static let Ping	: UInt32 = 0b1       // 1
	static let Ripple	: UInt32 = 0b10      // 2
	static let Repeater	: UInt32 = 0b100     // 3
	static let Source	: UInt32 = 0b1000    // 4
}

protocol SkoogSceneDelegate: class {
    func touchUp()
    func getReadyToPlay() -> Bool
	func pingPlay(index: Int, offset: Int, strength: Double)
    func pingStop(index: Int, offset: Int)
}

public class SkoogRipple: SKShapeNode {
    public var strength : CGFloat = 0.0
    public var index : Int = 0

    public override init() {
        super.init()
        self.zPosition = -10
        self.lineWidth = 3.0
        self.glowWidth = 2.5
        self.fillColor = .clear
        self.name = "ripple"
        self.physicsBody = SKPhysicsBody(circleOfRadius: self.frame.width/2)
        self.physicsBody!.isDynamic = true
        self.physicsBody!.categoryBitMask = PhysicsCategory.Ripple
        self.physicsBody!.contactTestBitMask = PhysicsCategory.Ping
        self.physicsBody!.collisionBitMask = PhysicsCategory.None
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}

public class SkoogSource: SKShapeNode {
    public var announceAX = true
    var radius : CGFloat = 0.0
    var color : UIColor = skoogDarkGrey
    var location : CGPoint = CGPoint(x:0, y:0)
    public var sceneDescription : String = "Place holder string"
    fileprivate var activating : Bool = false
    
    
    static func source(radius: CGFloat) -> SkoogSource {
        let skoogSource = SkoogSource(circleOfRadius: radius)
        
        skoogSource.isAccessibilityElement = true
        skoogSource.position = skoogSource.location
        skoogSource.name = "circle"
        skoogSource.strokeColor = skoogSource.color
        skoogSource.lineWidth = 8.0
        skoogSource.glowWidth = 0.0
        skoogSource.fillColor = .clear
        skoogSource.alpha = 0.8
        skoogSource.zPosition = 5
        
        return skoogSource
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
                return NSLocalizedString("Skoog Circle", comment: "Skoog circle AX string")
            }
        }
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            let summary = UIAccessibilityCustomAction(name: NSLocalizedString("Scene description", comment: "AX action name"), target: self, selector: #selector(sceneSummaryAXAction))
            let orientation = UIAccessibilityCustomAction(name: NSLocalizedString("Skoog orientation", comment: "AX orientation name"), target: self, selector: #selector(skoogOrientationAXAction))
            
            let announcement = UIAccessibilityCustomAction(name: announceAX ? NSLocalizedString("deactivate announcements", comment: "AX deactivata announcement name") : NSLocalizedString("activate announcements", comment: "AX activate announcement name"), target: self, selector: #selector(skoogAnnouncementAXAction))
            let orientationReminder = UIAccessibilityCustomAction(name: NSLocalizedString("color reminder", comment: "AX color reminder name"), target: self, selector: #selector(skoogOrientationReminderAXAcation))
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
        if self.announceAX == true {
            self.announceAX = false
        }
        else {
            self.announceAX = true
        }
        let announcement = String(format: "%@ %@", NSLocalizedString("announcements ", comment: "Detailed announcements AX string"), self.announceAX ? NSLocalizedString("activated", comment: "activated AX string") : NSLocalizedString("deactivated", comment: "deactivated AX string"))
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, announcement)
    }
}

public class SkoogPing: SKShapeNode {
    public var noteOffset : Int = 0
    public var colorString : String = ""
    
    static func ping(width: CGFloat) -> SkoogPing {
        let skoogPing = SkoogPing(rectOf: CGSize(width: width, height: width))
        
        skoogPing.lineWidth = 0.0
        skoogPing.strokeColor = .clear
        skoogPing.isAccessibilityElement = true
        
        return skoogPing
    }
    
    public override var accessibilityLabel : String? {
        set { }
        get {
            let x = self.position.x
            let y = self.position.y - 22
            let angle = atan2(-x, -y) * (180.0 / CGFloat.pi) + 180
            let distance = (sqrt(x * x + y * y) - 64 - 5 - 0.5 * self.frame.width) / 48
            let onTopString = NSLocalizedString("On top of the Skoog Circle", comment: "on top string")
            let angleString = String(format: NSLocalizedString("sd:allPages.angleMessage", comment: "angle message - {angle in degrees}"), angle)
            let distanceString = String(format: NSLocalizedString("sd:allPages.distanceMessage", comment: "distance message - {distance in pixels}"), distance)
            let string = String(format: "%@, %@, %@, %@", self.name!, self.colorString, distance < 0 ? onTopString : distanceString, angleString)
                return string
        }
    }
    
    public override var accessibilityCustomActions : [UIAccessibilityCustomAction]? {
        set { }
        get {
            let description = UIAccessibilityCustomAction(name: NSLocalizedString("Ping description", comment: "ping custom action description"), target: self, selector: #selector(pingDescriptionAXAction))
            return [description]
        }
    }
    @objc func pingDescriptionAXAction() {
        let pingDescription = String(format: NSLocalizedString("sd:allPages.pingDescription", comment: "ping description message"), self.colorString, self.noteOffset)
        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, pingDescription)
    }
}

public enum LabelStyle : Int {
    case normal = 0
    case random
    case clearNormal
    case clearRandom
}


public class SkoogScene: SKScene, SKPhysicsContactDelegate {
    weak var sceneDelegate:SkoogSceneDelegate?
	
	public var source : SKNode?
	public var pingArray = [SkoogPing?]()

	public var ripple : SkoogRipple?
    public var skoogSource : SkoogSource?
    public var circle : SkoogSource?
    public var circle2 : SKShapeNode?
	public var background : SKShapeNode?
	
	
    public var calibrationInnerCircle : SKShapeNode?
    public var calibrationCircle : SKShapeNode?
	public var guide : SKShapeNode?
	
    public var incrementCounter : CGFloat = 1.0
    public var label : SKLabelNode?
    public var peakLabel : SKLabelNode?
	public var noteLabel : SkoogLabel?
	public var testLabel : SkoogLabel?
    public var soundStyleLabel : SkoogLabel?
    public var squeezeLabel: SkoogLabel?

    public var calibrationLabel : SKLabelNode?
    public var durationMultiplier = 1.0
    public var lineWidth : CGFloat = 8.0
    public var glowAmount : CGFloat = 1.0
    public var currentColor : UIColor = skoogDarkGrey
    public var touched: Bool = false
    public var isUpdating: Bool = false
	
    public var skWait = SKAction.wait(forDuration: 0.1)
    public var skScale = SKAction()
	public var scaleAndPop = SKAction()
    public let skRemove = SKAction.removeFromParent()
    
    public var squeezeLabelText : String = ""
    public var squeezeLabelAlpha : CGFloat = 0.0
    public var circleAlpha : CGFloat = 0.8
    public var circleGrow : CGFloat = 1.0
    
	var hit : Int = 0
	var hitNode : SKNode?
	
    public let colors : [SKColor] = [   SKColor(red: 218.0/255.0, green: 60.0/255.0,  blue: 0.0, alpha: 1.0),         // red
                                        SKColor(red: 55.0/255.0,  green: 127.0/255.0, blue: 178.0/255.0, alpha: 1.0), // blue
                                        SKColor(red: 254.0/255.0, green: 224.0/255.0, blue: 0.0, alpha: 1.0),         // yellow
                                        SKColor(red: 61.0/255.0,  green: 155.0/255.0, blue: 53.0/255.0, alpha: 1.0),  // green
                                        SKColor(red: 249.0/255.0, green: 154.0/255.0, blue: 0.0, alpha: 1.0)]         // orange
    
    
    public var sourceShaders = [SKShader?]()
    public var pingConstraintFullScreenPortrait : SKConstraint?
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Initialisation Code
/////////////////////////////////////////////////////////////////////////

    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
		
        self.backgroundColor = skoogWhite
		self.name = "skoogScene"
        
        sourceShaders = [radialShader(color: colors[0]),
                         radialShader(color: colors[1]),
                         radialShader(color: colors[2]),
                         radialShader(color: colors[3]),
                         radialShader(color: colors[4]),
                         radialShader(color: skoogDarkGrey)]
        
        
        
		background = SKShapeNode(rectOf: CGSize(width: 1400, height: 1400))
		background?.zPosition = -500
		background?.lineWidth = 0
        background?.alpha = 0.1
        background?.fillShader = linearShader(color: .orange, endColor: .purple)

		background?.name = "background"
		self.addChild(background!)


        self.circle		= SkoogSource.source(radius: 64.0)
        self.circle2	= makeCircle(location:CGPoint(x:256,y:400), radius: 60, color: skoogDarkGrey)
        self.ripple		= makeRipple(location:CGPoint(x:256,y:400), radius: 64, color: .clear)
		
		circle2?.fillShader = sourceShaders[5]!
		circle2?.isAccessibilityElement = false
        circle2?.strokeColor = .white
        circle2?.lineWidth = 4
        circle2?.glowWidth = 0
        circle?.alpha = 0.8

        self.addChild(self.circle!)
        self.circle?.isAccessibilityElement = true

        
        self.calibrationInnerCircle	= makeCircle(location:CGPoint(x:0,y:0), radius: 64+48, color: skoogDarkGrey)
        self.calibrationInnerCircle!.alpha = CGFloat(0.0)
        self.calibrationInnerCircle!.zPosition = 100
        self.calibrationInnerCircle!.fillColor = skoogDarkGrey
        
        let path = CGMutablePath()
        path.addArc(center: CGPoint(x:0,y:0), radius: 120, startAngle: 0, endAngle: 0, clockwise: true) //
        self.calibrationCircle = SKShapeNode(path: path)
        self.calibrationCircle!.zRotation = CGFloat.pi / 2

        self.calibrationCircle?.lineWidth = 0
        self.calibrationCircle?.fillColor = .white
        self.calibrationCircle?.strokeColor = .clear
        self.calibrationCircle?.glowWidth = 10
        self.calibrationCircle?.zPosition = 99
        
        self.addChild(self.calibrationCircle!)
		
		self.changeCircleColor(side:0, size: 0.0)
        
		
        let label = SKLabelNode(text: "Sound Style: elecpiano ")
        label.position = CGPoint(x:-0.5 * label.frame.size.width,y:-240)
        label.color = .white
        label.fontColor = skoogDarkGrey
        label.alpha = 0.0
        label.fontName = UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.semibold).fontName
        label.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        label.horizontalAlignmentMode = SKLabelHorizontalAlignmentMode.left
        self.addChild(label)
        self.label = label
        
        
        let calibrationLabel = SKLabelNode()
        calibrationLabel.position = CGPoint(x:0,y:0)
        calibrationLabel.color = .white
        calibrationLabel.fontName = UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.light).fontName
        calibrationLabel.name = "calibrationLabelNode"
        self.addChild(calibrationLabel)
        self.calibrationLabel = calibrationLabel
        self.calibrationLabel!.zPosition = 150
        self.calibrationLabel!.verticalAlignmentMode = SKLabelVerticalAlignmentMode.center
        self.calibrationLabel!.isAccessibilityElement = false
        self.calibrationLabel!.isUserInteractionEnabled = false
        
        let peakLabel = SKLabelNode()
        peakLabel.position = CGPoint(x:256,y:584)
        peakLabel.color = .darkGray
        peakLabel.fontColor = .white
        peakLabel.fontName = UIFont.systemFont(ofSize: 32.0, weight: UIFont.Weight.semibold).fontName
        self.addChild(peakLabel)
        self.peakLabel = peakLabel
		
        let noteLabel = SkoogLabel.label(showImage: false)
		noteLabel.position = CGPoint(x:256,y:584)
		self.addChild(noteLabel)
		self.noteLabel = noteLabel
        
		let soundStyleLabel = SkoogLabel.label(showImage: true)
		soundStyleLabel.position = CGPoint(x:-0.5 * label.frame.size.width,y:-192)
        soundStyleLabel.setLabel(text: "")
        soundStyleLabel.alpha = 0.0
		self.addChild(soundStyleLabel)
		self.soundStyleLabel = soundStyleLabel

        let squeezeLabel = SkoogLabel.label(showImage: false)
        squeezeLabel.position = CGPoint(x:-0.5 * label.frame.size.width,y:-192)
        squeezeLabel.setLabel(text: "")
        squeezeLabel.setValue(text: "")
        squeezeLabel.alpha = 0.0
        squeezeLabel.alignMode = 1
        self.addChild(squeezeLabel)
        self.squeezeLabel = squeezeLabel
        
        
		physicsWorld.gravity = CGVector.zero
		physicsWorld.contactDelegate = self
		
		self.guide = drawGuide()
        
        
        let xrange = SKRange(lowerLimit: 0, upperLimit: 0)
        let yrange = SKRange(lowerLimit: 22, upperLimit: 22)
        let lockToCenter = SKConstraint.positionX(xrange, y: yrange)
        
        self.circle?.constraints = [ lockToCenter ]
        self.circle2?.constraints = [ lockToCenter ]
        self.ripple?.constraints = [ lockToCenter ]
        self.guide?.constraints = [ lockToCenter ]
        self.calibrationCircle?.constraints = [ lockToCenter ]
        self.calibrationInnerCircle!.constraints = [ lockToCenter ]
        calibrationLabel.constraints = [ lockToCenter ]
        
//        let screenSize : CGSize = self.view?.frame.size != nil ? (self.view?.frame.size)! : CGSize(width: 1024, height: 768)
        let screenSize = self.size

        self.pingConstraintFullScreenPortrait = SKConstraint.positionX(SKRange(lowerLimit: -0.5 * screenSize.width + 24 , upperLimit: 0.5 * screenSize.width - 24),
                                                                       y: SKRange(lowerLimit: -0.5 * screenSize.height + 24 , upperLimit: 0.5 * screenSize.height - 24))
	}
	
	
	
    func makeCircle(location: CGPoint, radius: CGFloat, color: SKColor) -> SKShapeNode {
        let Circle = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
        Circle.position = location  //touch location passed from touchesBegan.
        Circle.name = "circle"
        Circle.strokeColor = color
        Circle.lineWidth = self.lineWidth
        Circle.glowWidth = 0.0
        Circle.fillColor = .clear
		Circle.zPosition = 10

        self.addChild(Circle)
        return Circle
    }
	
	func makeRipple(location: CGPoint, radius: CGFloat, color: SKColor) -> SkoogRipple {
		let Ripple = SkoogRipple(circleOfRadius: radius ) // Size of Circle = Radius setting.
		Ripple.position = location  //touch location passed from touchesBegan.
		Ripple.strokeColor = color
        Ripple.index = 10 //indicates that this is a source ripple
		Ripple.physicsBody = SKPhysicsBody(circleOfRadius: radius)
		Ripple.physicsBody?.isDynamic = true
		Ripple.physicsBody?.categoryBitMask = PhysicsCategory.Ripple
		Ripple.physicsBody?.contactTestBitMask = PhysicsCategory.Ping
		Ripple.physicsBody?.collisionBitMask = PhysicsCategory.None
		self.addChild(Ripple)
		return Ripple
	}
	
	// draw circular guide markers in background
	public func drawGuide() -> SKShapeNode{
	
		let parent = SKShapeNode()
		//parent.position = CGPoint(x:0,y:0)
		
		var pingDiameter : CGFloat = 48
		if !self.pingArray.isEmpty {
			pingDiameter = self.pingArray[0]!.frame.width
		}
		
		var circleRadius : CGFloat = 40
		if let circle = self.circle {
			circleRadius = 0.5 * circle.frame.width
            parent.position = self.circle!.position

		}
		
		let numHoops = Int(4 * circleRadius / pingDiameter)
		for n in 1...numHoops{
			let hoop : SKShapeNode
				if n < numHoops {
					hoop = SKShapeNode(circleOfRadius: circleRadius + CGFloat(n) * pingDiameter)
					hoop.alpha = 0.6 - 0.59 * CGFloat(n) /  CGFloat(numHoops)
					hoop.strokeColor = .white
					hoop.lineWidth = 4.0
					hoop.glowWidth = 0
                    hoop.name = "hoop"
                    hoop.position = CGPoint(x:0,y:0)
                    hoop.fillColor = .clear
                    hoop.zPosition = -200
                    parent.addChild(hoop)
				}
		}
		
		self.addChild(parent)
		return parent
	}
	
	
	// Not using this code yet
	func createSourceNode(location: CGPoint, radius: CGFloat, color: SKColor) ->SKShapeNode{
		
		let parent = SKShapeNode()
		parent.position = location
        
		
		let outerCircle = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
		outerCircle.position = CGPoint(x:0,y:0)  //touch location passed from touchesBegan.
		outerCircle.name = "outerCircle"
		outerCircle.strokeColor = .lightGray
		outerCircle.lineWidth = self.lineWidth
		outerCircle.glowWidth = 0.0
		outerCircle.fillColor = .white
		outerCircle.zPosition = -10
		parent.addChild(outerCircle)

		let innerCircle = SKShapeNode(circleOfRadius: 0.125 * radius ) // Size of Circle = Radius setting.
		innerCircle.position = CGPoint(x:0,y:0)  //touch location passed from touchesBegan.
		innerCircle.name = "innerCircle"
		innerCircle.strokeColor = color
		innerCircle.lineWidth = self.lineWidth
		innerCircle.glowWidth = 0.0
		innerCircle.fillColor = color
		outerCircle.zPosition = 0
		parent.addChild(innerCircle)
		
		let outerRing = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
		outerRing.position = CGPoint(x:0,y:0)  //touch location passed from touchesBegan.
		outerRing.name = "ring"
		outerRing.strokeColor = color
		outerRing.lineWidth = self.lineWidth
		outerRing.glowWidth = 0.0
		outerRing.fillColor = .clear
		outerRing.zPosition = 10
		parent.addChild(outerRing)
		
		self.addChild(parent)
		return parent
	}
    

    
    public func createPingNode(type: String, noteOffset: Int, distance: Double? = nil, angle: Double? = nil){
        let radius : CGFloat = 24
        var color : SKColor
        var typeName = type
        switch(type){
        case "red", NSLocalizedString("red", comment: "the color red"):
            typeName = "red"
            color = colors[0]
            break
        case "blue", NSLocalizedString("blue", comment: "the color blue"):
            typeName = "blue"
            color = colors[1]
            break
        case "yellow", NSLocalizedString("yellow", comment: "the color yellow"):
            typeName = "yellow"
            color = colors[2]
            break
        case "green", NSLocalizedString("green", comment: "the color green"):
            typeName = "green"
            color = colors[3]
            break
        case "orange", NSLocalizedString("orange", comment: "the color orange"):
            typeName = "orange"
            color = colors[4]
            break
        case "any":
            color = skoogWhite
            break
        default:
            color = skoogWhite
            typeName = "any"
            break
        }
        
        let parent = SkoogPing.ping(width: 48)
        
//        let pingXrange = SKRange(lowerLimit: -512+24, upperLimit: 512 - 24)
//        let pingYrange = SKRange(lowerLimit: -368+25, upperLimit: 512 - 24)
        parent.constraints = [ self.pingConstraintFullScreenPortrait! ]
        parent.colorString = type
        
        let nSegments = 12
        let segmentRow    = Int(self.pingArray.endIndex / nSegments)
        
        // Check to see if a angle argument has been supplied
        let segmentAngle : CGFloat
        if angle == nil {
            segmentAngle  = 2.0 * .pi * CGFloat(self.pingArray.endIndex % nSegments) / CGFloat(nSegments)
        }
        else {
            segmentAngle  = (2.0 * .pi * CGFloat(angle! / 360.0)) - .pi * 0.33
        }
        
        // Check to see if a distance argument has been supplied
        let segmentLength : CGFloat
		if distance == nil {
			segmentLength = 120 + (120 * segmentAngle / .pi) + 3 * CGFloat(segmentRow) * radius
		}
		else {
			segmentLength = (0.5 * self.circle!.frame.width + radius) + 2.0 * radius * CGFloat(distance!)
		}

        
        parent.position = CGPoint(x: self.circle!.position.x + segmentLength * sin(segmentAngle + .pi * 0.33),
                                  y: 22.0 + segmentLength * cos(segmentAngle + .pi * 0.33))
        
        
		parent.physicsBody = SKPhysicsBody(circleOfRadius: radius)
		parent.physicsBody?.isDynamic = true
		parent.physicsBody?.categoryBitMask = PhysicsCategory.Ping
		parent.physicsBody?.contactTestBitMask = PhysicsCategory.Ripple
		parent.physicsBody?.collisionBitMask = PhysicsCategory.None
		parent.zPosition = 50

		let circle = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
		circle.position = CGPoint(x:0,y:0)  //touch location passed from touchesBegan.
		circle.name = "ping_"+typeName
		circle.strokeColor = .lightGray
		circle.lineWidth = 0 //self.lineWidth
		circle.glowWidth = 0.0
		circle.fillColor = color

		circle.zPosition = 0
        
        let shader = linearShader(color: color)
        circle.fillShader = shader
		parent.addChild(circle)
		
		let ring = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
		ring.position = CGPoint(x:2,y:-2)  //touch location passed from touchesBegan.
		ring.name = "glow"
		ring.strokeColor = color.withAlphaComponent(0.0)
		ring.lineWidth = 1 //self.lineWidth
		ring.glowWidth = 1
		ring.fillColor = .clear
		ring.zPosition = -10
		parent.addChild(ring)
		 
        
        let circleDepth = SKShapeNode(circleOfRadius: radius ) // Size of Circle = Radius setting.
        circleDepth.position = CGPoint(x:2,y:-2)  //touch location passed from touchesBegan.
        circleDepth.name = "ping_depth"+typeName
        circleDepth.lineWidth = 0 //self.lineWidth
        circleDepth.glowWidth = 0.0
        if typeName == "any" {
            circleDepth.fillColor = skoogDarkGrey.lighter(by:80)
        }
        else {
            circleDepth.fillColor = color.darker(by: 30)
        }
        circleDepth.zPosition = -5
        
        parent.addChild(circleDepth)
        
        let circleShadow = SKShapeNode(circleOfRadius: radius + 1.5 ) // Size of Circle = Radius setting.
        circleShadow.position = CGPoint(x:3,y:-3)  //touch location passed from touchesBegan.
        circleShadow.name = "ping_depth"+typeName
        circleShadow.lineWidth = 0 //self.lineWidth
        circleShadow.glowWidth = 0.0
        if typeName == "any" {
            circleShadow.fillColor = skoogDarkGrey.lighter(by:80).withAlphaComponent(0.1)
        }
        else {
            circleShadow.fillColor = color.darker(by: 30).withAlphaComponent(0.1)
        }
        circleShadow.zPosition = -15
        
        parent.addChild(circleShadow)


        self.addChild(parent)           //add the parent notde to the scene

        parent.name = "Ping \(self.pingArray.endIndex + 1)"    // use the array's “past the end” position to set the new ping name
        parent.noteOffset = noteOffset
        self.pingArray.append(parent)                         // now add the ping to the array
	}
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Accessibility
/////////////////////////////////////////////////////////////////////////

    public func getBasicDescription() -> String {
        return NSLocalizedString("A black skoog circle appears in the center of the Live View.  This will change color depending on what side of the Skoog you press, and a matching colored ripple or pulse will animate depending on your code.", comment: "live view label part 1")
    }
    
    public func getNumberOfPings() -> String {
         return String(format: NSLocalizedString("sd:allPages.pingCountDescription", comment: "ping count description - {number of pings on screen}"), self.pingArray.count)
    }
    
    public func getPingDescriptions() -> String {
        return pingArray.count > 0 ? NSLocalizedString("When a colored ripple or pulse meets a ping, the ping will glow gently and make a sound if it has the same color.  A white ping will make a sound when ripples or pulses of any color meet it.", comment: "live view label part 3") : ""
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
    
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Label Code
/////////////////////////////////////////////////////////////////////////

    public func labelFade(side: Side, value: Double) {
        
        //First remove any existing nodes with the same name
        if let existingNode = self.childNode(withName: "pressLabel" + side.name.rawValue) {
            existingNode.removeAllActions()
            existingNode.run(SKAction.removeFromParent())
        }
        
        if let n = self.peakLabel?.copy() as! SKLabelNode? {
            if let circle = self.circle {
                n.position = CGPoint(x: circle.position.x, y: circle.position.y + 100 + CGFloat(side.index) * 35)
            }
            n.fontColor = colors[side.index]
            n.text = NSLocalizedString("Press ", comment: "Press label") + String(format:"%0.2f", value)
            n.name = "pressLabel" + side.name.rawValue

			n.run(SKAction.sequence([SKAction.wait(forDuration: 0.1 * durationMultiplier),
									 SKAction.fadeOut(withDuration: 1.0 * durationMultiplier),
									 SKAction.removeFromParent()]))
            
            self.addChildSafely(node: n)
        }
    }
	
   	
    public func messageLabelFade(message: String? = "", side: Side? = nil, value: String? = "", style: LabelStyle = .random) {
        
        var myColor : SKColor
        if let mySide = side {
            myColor = colors[mySide.index]
        }
        else {
            myColor = .white
        }
        
        let sideName = side == nil ? "" : side!.name.rawValue
        
        for i in self.children {
            if i.name == "bottomLabel_" + sideName {
                i.removeAllActions()
                i.run(SKAction.removeFromParent())
            }
        }
        
        let n = SkoogLabel.label(showImage:false)
        n.setFontColor(color: myColor)
        n.setLabel(text: message!)
        n.setValue(text: value!)
        n.name = "bottomLabel_" + sideName
        
        if let circle = self.circle {
            var xRandomness : CGFloat = 0
            var yRandomness : CGFloat = 0
            switch(style){
            case .random, .clearRandom :
                xRandomness = CGFloat(random(min: -120, max: 120))
                yRandomness = CGFloat(random(min: -50, max: 50))
            case .normal, .clearNormal:
                xRandomness = 0
                yRandomness = 0
            }
            n.position = CGPoint(x: -0.5 * (n.label.frame.width + n.value.frame.width) + xRandomness, y: circle.position.y - 262 + yRandomness)
        }
        self.addChildSafely(node: n)
        
        n.run(SKAction.sequence([SKAction.wait(forDuration: 0.1 * durationMultiplier),
                                 SKAction.fadeOut(withDuration: 1.0 * durationMultiplier),
                                 SKAction.removeFromParent()]))
//        }
    }

    
	
	public func noteLabelFade(side: Side, note: MidiNoteNumber) {
        //First remove any existing nodes with the same name
//        if let existingNode = self.childNode(withName: "noteLabel_" + side.name.rawValue) {
//            existingNode.removeAllActions()
//            existingNode.run(SKAction.removeFromParent())
//        }
        
//        let sideName = side.name.rawValue
        
        for i in self.children {
            if i.name == "noteLabel_"/* + sideName*/ {
                i.removeAllActions()
                i.run(SKAction.removeFromParent())
            }
        }
        
        
        let n = SkoogLabel.label(showImage:false)
        
        n.setFontColor(color: colors[side.index])
        n.setLabel(text: NSLocalizedString("MIDI", comment: "MIDI should not be localized"))
        n.setValue(text: " " + String(note) + " (" + midiNoteName(number: note) + ")")
    
        let xRandomness = CGFloat(random(min: -120, max: 120))
        let yRandomness = CGFloat(random(min: 0, max: 100))

        if let circle = self.circle {
            n.position = CGPoint(x: -0.5 * (n.label.frame.width + n.value.frame.width) + xRandomness, y: circle.position.y - 252 + yRandomness)

//            n.position = CGPoint(x: -0.5 * (n.label.frame.width + n.value.frame.width), y: circle.position.y - 256 + CGFloat(side.index) * 35)
        }

        n.name = "noteLabel_" //+ side.name.rawValue
        
        n.run(SKAction.sequence([SKAction.wait(forDuration: 0.1 * durationMultiplier),
                                 SKAction.fadeOut(withDuration: 1.0 * durationMultiplier),
                                 SKAction.removeFromParent()]))
        
        self.addChildSafely(node: n)
	}

	
	//Helper Function
	public func midiNoteName(number: MidiNoteNumber) -> String{
        let chromaticNames = [NSLocalizedString("C", comment: "the musical note C"),
                              NSLocalizedString("C♯", comment: "the musical note C♯"),
                              NSLocalizedString("D", comment: "the musical note D"),
                              NSLocalizedString("E♭", comment: "the musical note E♭"),
                              NSLocalizedString("E", comment: "the musical note E"),
                              NSLocalizedString("F", comment: "the musical note F"),
                              NSLocalizedString("F♯", comment: "the musical note F♯"),
                              NSLocalizedString("G", comment: "the musical note G"),
                              NSLocalizedString("G♯", comment: "the musical note G♯"),
                              NSLocalizedString("A", comment: "the musical note A"),
                              NSLocalizedString("B♭", comment: "the musical note B♭"),
                              NSLocalizedString("B", comment: "the musical note B")];
		let note = number % 12
		let octave = (number / 12) - 2 //we are starting octave 0 at midinote 24
		return chromaticNames[note] + String(octave)
	}
    
    public func animateCalibration() {
        if self.hasActions() {
            self.removeAllActions()
        }
        
        if self.calibrationCircle!.hasActions() {
            self.calibrationCircle!.removeAllActions()
        }
        if self.calibrationLabel!.hasActions() {
            self.calibrationLabel!.removeAllActions()
        }
        
        if self.calibrationInnerCircle!.hasActions() {
            self.calibrationInnerCircle!.removeAllActions()
        }
        
        self.calibrationCircle!.path = nil
        self.calibrationLabel?.text = NSLocalizedString("Calibrating", comment: "Calibration progress label")
        self.calibrationLabel?.alpha = CGFloat(1.0)
        self.calibrationCircle!.setScale(1.0)
        self.calibrationCircle!.alpha = CGFloat(1.0)
        self.calibrationInnerCircle!.alpha = CGFloat(1.0)
        
        let radius : CGFloat = 0.5 * self.calibrationInnerCircle!.frame.width + 48
        let duration = 2.0
        let steps = 320
        let timeInterval = duration/TimeInterval(steps)
        let incr = CGFloat(1) / CGFloat(steps)
        var percent = CGFloat(0.0)
        
        let animate = SKAction.run {
            percent += incr
            self.calibrationCircle!.path = self.calibrationCircle(radius: radius, percent:percent)
        }
        let wait = SKAction.wait(forDuration:timeInterval)
        let action = SKAction.sequence([wait, animate])
        
        self.run(SKAction.repeat(action,count:steps)) {
            let fade = SKAction.fadeOut(withDuration: 0.5)
            let shrink = SKAction.scale(by: 0.67, duration: 0.5)
            let FadeScaleSequence = SKAction.group([fade, shrink])
            self.calibrationCircle!.run(FadeScaleSequence)
            self.calibrationLabel?.run(fade) {
                self.calibrationLabel?.text = ""
            }
            self.calibrationInnerCircle!.run(fade) {
                if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, NSLocalizedString("Calibration complete", comment: "Calibration complete AX text"))
                    self.circle?.activating = false
                }
            }
        }
    }
    
    // Creates a CGPath in the shape of a pie with slices missing
    func calibrationCircle(radius:CGFloat, percent:CGFloat) -> CGPath {
        let start:CGFloat = CGFloat.pi * 2
        let end = CGFloat.pi * 2 - (CGFloat.pi * 2 * percent)
        let center = CGPoint.zero
        let newPath = CGMutablePath()
        newPath.move(to:center)
        newPath.addArc(center: CGPoint(x:0,y:0), radius: radius, startAngle: start, endAngle: end, clockwise: true)
        newPath.addLine(to: CGPoint(x:0,y:0))
        return newPath
    }
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Animation Code
/////////////////////////////////////////////////////////////////////////    
	
    public func startRipple(color: UIColor, size: Double) {
        if sceneDelegate!.getReadyToPlay() {
            if (size > 0.024) {
                var myDurationMultiplier = durationMultiplier
                
                var sideIndex = 10
                switch(color){
                case colors[0]:
                    sideIndex = 0
                    break
                case colors[1]:
                    sideIndex = 1
                    break
                case colors[2]:
                    sideIndex = 2
                    break
                case colors[3]:
                    sideIndex = 3
                    break
                case colors[4]:
                    sideIndex = 4
                    break
                default:
                    myDurationMultiplier = 2
                    break
                }
                
                if let n = self.ripple?.copy() as! SkoogRipple? {
                    n.strokeColor = color.withAlphaComponent(CGFloat(size))
                    n.strength = CGFloat(size)
                    n.index = sideIndex
                    
                    skScale = SKAction.scale(to: 5.0, duration: 3.0 * myDurationMultiplier)
					
					scaleAndPop = SKAction.sequence([skWait, skScale])
                    let fadeOut = SKAction.fadeOut(withDuration: 0.2 + 2.3 * size * myDurationMultiplier)
                    let group = SKAction.group([fadeOut, scaleAndPop])
                    n.run(group, completion: {
                            n.removeFromParent()
                    })
                    self.addChildSafely(node: n)
                }
            }
        }
    }
	
    public func startPulse(color: UIColor, size: Double) {
        if sceneDelegate!.getReadyToPlay() {
            if (size > 0.024) {
                
                var sideIndex = 10  //triggered on release
                switch(color){
                case colors[0]:
                    sideIndex = 0
                    break
                case colors[1]:
                    sideIndex = 1
                    break
                case colors[2]:
                    sideIndex = 2
                    break
                case colors[3]:
                    sideIndex = 3
                    break
                case colors[4]:
                    sideIndex = 4
                    break
                default:
                    break
                }

				if let n = self.ripple?.copy() as! SkoogRipple?{
					n.strokeColor = color
					n.strength = CGFloat(size)
					n.index = sideIndex
					let expand : CGFloat = 4
					let duration : TimeInterval = 0.6 //s
					let updatePulse = SKAction.customAction(withDuration: duration) {
						(node, elapsedTime) in
						if let nd = node as? SkoogRipple {
							let growth = sin(.pi * elapsedTime / CGFloat (duration))
							nd.glowWidth =  1 + CGFloat(size) * expand * growth
							nd.setScale(1 + CGFloat(size) * 0.5 * growth)
							nd.strokeColor = color.withAlphaComponent(growth)
						}
					}
					n.run(SKAction.sequence([updatePulse,
					                            SKAction.removeFromParent()]))
                    self.addChildSafely(node: n)
				}
            }
        }
    }

	public func releaseRipple(color: UIColor) {
		if sceneDelegate!.getReadyToPlay() {
			
				let myDurationMultiplier = 2.1 * durationMultiplier
				
				var sideIndex = 10
				switch(color){
				case colors[0]:
					sideIndex = 5
					break
				case colors[1]:
					sideIndex = 6
					break
				case colors[2]:
					sideIndex = 7
					break
				case colors[3]:
					sideIndex = 8
					break
				case colors[4]:
					sideIndex = 9
					break
				default:
					break
				}
				
				if let n = self.ripple?.copy() as! SkoogRipple? {
					n.strokeColor = UIColor.white.withAlphaComponent(0.5)
					n.zPosition = -50
					n.strength = CGFloat(1)
					n.index = sideIndex

					if let circle = self.circle {
						n.position = CGPoint(x: circle.position.x, y: circle.position.y)
						n.lineWidth = 2.0
						n.glowWidth = 0.0
                        
						let fadeOut = SKAction.fadeOut(withDuration: 1.5 * myDurationMultiplier)
						let SKseq = SKAction.sequence([skWait, skWait, skScale]) //skScale is set at Ripple Time, so shouldnt need to reset.
						let group = SKAction.group([fadeOut,SKseq])
						n.run(group, completion: {
                            n.removeFromParent()
                        })
                        self.addChildSafely(node: n)
					}
					else {
						n.lineWidth = 1.0
						n.glowWidth = 0.5
                        
						n.run(SKAction.fadeOut(withDuration: 1.5 * myDurationMultiplier))
						n.run(SKAction.sequence([SKAction.wait(forDuration: 0.1 * durationMultiplier),
						                         SKAction.scale(to: 25, duration: 1.5 * myDurationMultiplier),
						                         SKAction.removeFromParent()]))
                        self.addChildSafely(node: n)
                    }
				}
			}
	}
    
    
    
    public func addChildSafely(node: SKNode) {
        if !isUpdating {
            self.addChild(node) // Actions only run once node is added to the scene
        }
        else {
            DispatchQueue.main.async {
                while (self.isUpdating){} // added safety check to make sure we wait until isUpdating is false
                self.addChild(node)
            }
        }
    }
    
    public func removeFromParentSafely(node: SKNode) {
        if !isUpdating {
            node.removeFromParent() // Actions only run once node is added to the scene
        }
        else {
            DispatchQueue.main.async {
                while (self.isUpdating){} // added safety check to make sure we wait until isUpdating is false
                if !self.isUpdating {
                    node.removeFromParent()
                }
            }
        }
    }
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Ping Collision Code
/////////////////////////////////////////////////////////////////////////

    func rippleDidCollideWithPing(ripple: SkoogRipple, ping: SkoogPing, impulse: CGFloat, normal: CGVector) {
        
        //What colour was the ripple that collided with the ping?
        let rippleStrokeColor = ripple.strokeColor
        let pingColor = rippleStrokeColor
        //let size  = ripple.strength
        
        let glowNode = ping.childNode(withName: "glow")
        //let width = (glowNode as? SKShapeNode)!.glowWidth
        let expand : CGFloat = 4
        let duration : TimeInterval = 0.6 //s
        
        //Calculate ripple area as a measure of activation strength.
        let rippleArea = ripple.frame.width * ripple.frame.width
        let sourceArea : CGFloat = 160 * 160
        let rippleAreaMax = 24 * sourceArea // max radius is 5x, so max area 5^2 = 25x, want difference from source area, so less 1, hence 24.
        
        
        let rippleRatio = rippleArea > sourceArea
            ? 1 - (rippleArea - sourceArea) / rippleAreaMax
            : 1          // originalsize/growth
        
        //define SKactions
        let updateGlow = SKAction.customAction(withDuration: duration) {
            (node, elapsedTime) in
            if let n = node as? SKShapeNode {
                let growth = sin(.pi * elapsedTime / CGFloat (duration))
                n.glowWidth =  1 + rippleRatio * expand * growth
                n.setScale(1 + rippleRatio * 0.25 * growth)
                n.strokeColor = pingColor.withAlphaComponent(rippleRatio * growth)
            }
        }
        
        
        let releaseGlow = SKAction.customAction(withDuration: duration) {
            (node, elapsedTime) in
            if let n = node as? SKShapeNode {
                let growth = sin(.pi * elapsedTime / CGFloat (duration))
                n.glowWidth =  1 + 0.25 * 0.75 * rippleRatio * expand * growth
                n.setScale(1 + 0.75 * rippleRatio * 0.25 * growth)
                n.strokeColor = UIColor.white.withAlphaComponent(0.25 * rippleRatio * growth)
            }
        }
        
        
        //Deal with note-on ripples
        if ping.childNode(withName: "ping_any") != nil && ripple.index < 5  {
            sceneDelegate!.pingPlay(index: ripple.index, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        else if ping.childNode(withName: "ping_red") != nil  && ripple.index == 0 {
            sceneDelegate!.pingPlay(index: 0, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        else if ping.childNode(withName: "ping_blue") != nil  && ripple.index == 1 {
            sceneDelegate!.pingPlay(index: 1, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        else if ping.childNode(withName: "ping_yellow") != nil  && ripple.index == 2 {
            sceneDelegate!.pingPlay(index: 2, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        else if ping.childNode(withName: "ping_green") != nil  && ripple.index == 3 {
            sceneDelegate!.pingPlay(index: 3, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        else if ping.childNode(withName: "ping_orange") != nil  && ripple.index == 4 {
            sceneDelegate!.pingPlay(index: 4, offset: ping.noteOffset, strength: Double(ripple.strength * rippleRatio))
            if glowNode!.hasActions(){
                glowNode!.removeAllActions()
            }
            glowNode!.run(updateGlow)
        }
        //Deal with release/note-off ripples now....
        else if ping.childNode(withName: "ping_any") != nil  && ripple.index >= 5  && ripple.index < 10{
            if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
            }
			glowNode!.run(releaseGlow, withKey: "release")
			sceneDelegate!.pingStop(index: ripple.index, offset: ping.noteOffset)

        }
        else if ping.childNode(withName: "ping_red") != nil  && ripple.index == 5 {
			if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
			}
			sceneDelegate!.pingStop(index: 0, offset: ping.noteOffset)
			glowNode!.run(releaseGlow, withKey: "release")
        }
        else if ping.childNode(withName: "ping_blue") != nil  && ripple.index == 6 {
            if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
			}
			sceneDelegate!.pingStop(index: 1, offset: ping.noteOffset)
			glowNode!.run(releaseGlow, withKey: "release")
        }
        else if ping.childNode(withName: "ping_yellow") != nil  && ripple.index == 7 {
            if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
			}
			sceneDelegate!.pingStop(index: 2, offset: ping.noteOffset)
			glowNode!.run(releaseGlow, withKey: "release")
        }
        else if ping.childNode(withName: "ping_green") != nil  && ripple.index == 8 {
            if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
			}
			sceneDelegate!.pingStop(index: 3, offset: ping.noteOffset)
			glowNode!.run(releaseGlow, withKey: "release")
        }
        else if ping.childNode(withName: "ping_orange") != nil  && ripple.index == 9 {
            if glowNode!.action(forKey: "release") != nil {
				glowNode!.removeAllActions()
			}
			sceneDelegate!.pingStop(index: 4, offset: ping.noteOffset)
			glowNode!.run(releaseGlow, withKey: "release")
        }
        
    }
    
    public func didBegin(_ contact: SKPhysicsContact) {
		
		var firstBody: SKPhysicsBody
		var secondBody: SKPhysicsBody
		if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
			firstBody = contact.bodyA
			secondBody = contact.bodyB
		}
		else {
			firstBody = contact.bodyB
			secondBody = contact.bodyA
		}
		
		if ((firstBody.categoryBitMask & PhysicsCategory.Ping != 0) &&
			(secondBody.categoryBitMask & PhysicsCategory.Ripple != 0)) {
			if let ping = firstBody.node as? SkoogPing, let
				ripple = secondBody.node as? SkoogRipple {
				// ignore collisions where the ripple index is 10 - as this is our central "source" ripple
                if ripple.index != 10 {
					rippleDidCollideWithPing(ripple: ripple, ping: ping, impulse: contact.collisionImpulse, normal: contact.contactNormal)
				}
			}
		}
    }
    
    
    
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Circle Color Functions
/////////////////////////////////////////////////////////////////////////
	
	
    public func changeCircleColor(side: Int, size: Double){
        let newSize = CGFloat(size * 127)

        if newSize > 0.0 {
            if sceneDelegate!.getReadyToPlay() {
                if let circle = self.circle {
					if circle.action(forKey: "changeColor") != nil {
						circle.removeAction(forKey: "changeColor")
					}
                    self.currentColor = colors[side]
                }
                if let circle2 = self.circle2 {
                    if circle2.action(forKey: "changeColor") != nil {
                        circle2.removeAction(forKey: "changeColor")
                    }
                    circle2.run(shaderAction(shader: self.sourceShaders[side]!), withKey: "changeColor")
                }
            }
        }
        else {
            if let circle = self.circle {
                if circle.action(forKey: "changeColor") != nil {
                    circle.removeAction(forKey: "changeColor")
				}
				let currentStrokeColor = circle.strokeColor
                self.currentColor = skoogDarkGrey
            }
            if let circle2 = self.circle2 {
                if circle2.action(forKey: "changeColor") != nil {
                    circle2.removeAction(forKey: "changeColor")
                }
                circle2.run(shaderAction(shader: self.sourceShaders[5]!), withKey: "changeColor")
            }
        }
        
    }
    
    func shaderAction(shader: SKShader) -> SKAction
    {
        return SKAction.customAction(withDuration: 0.016, actionBlock: { (node : SKNode!, elapsedTime : CGFloat) -> Void in
                (node as! SKShapeNode).fillShader = shader
            }
        )
    }
    
    
    // In the class that calls colorTransitionAction
    // Include these variables
    // In my code its the class that aggregates the sprite
    var frgba = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var frgba2 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var frgba3 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var frgba4 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    
    var trgba = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var trgba2 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var trgba3 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    var trgba4 = [CGFloat(0.0), CGFloat(0.0), CGFloat(0.0), CGFloat(0.0)]
    
    func lerp(a : CGFloat, b : CGFloat, fraction : CGFloat) -> CGFloat
    {
        return (b-a) * fraction + a
    }
    
    func rgbaFillTransitionAction(fromColor : UIColor, toColor : UIColor, duration : Double = 0.4) -> SKAction
    {
        fromColor.getRed(&frgba[0], green: &frgba[1], blue: &frgba[2], alpha: &frgba[3])
        toColor.getRed(&trgba[0], green: &trgba[1], blue: &trgba[2], alpha: &trgba[3])
        
        return SKAction.customAction(withDuration: duration, actionBlock: { (node : SKNode!, elapsedTime : CGFloat) -> Void in
            let fraction = CGFloat(elapsedTime / CGFloat(duration))
            let transColor = UIColor(red: self.lerp(a: self.frgba[0], b: self.trgba[0], fraction: fraction),
                                     green: self.lerp(a: self.frgba[1], b: self.trgba[1], fraction: fraction),
                                     blue: self.lerp(a: self.frgba[2], b: self.trgba[2], fraction: fraction),
                                     alpha: self.lerp(a: self.frgba[3], b: self.trgba[3], fraction: fraction))
            (node as! SKShapeNode).fillColor = transColor
        }
        )
    }
	
    func rgbFillTransitionAction(fromColor : UIColor, toColor : UIColor, duration : Double = 0.4) -> SKAction
    {
        fromColor.getRed(&frgba[0], green: &frgba[1], blue: &frgba[2], alpha: &frgba[3])
        toColor.getRed(&trgba[0], green: &trgba[1], blue: &trgba[2], alpha: &trgba[3])
        
        return SKAction.customAction(withDuration: duration, actionBlock: { (node : SKNode!, elapsedTime : CGFloat) -> Void in
            let fraction = CGFloat(elapsedTime / CGFloat(duration))
            let transColor = UIColor(red: self.lerp(a: self.frgba[0], b: self.trgba[0], fraction: fraction),
                                     green: self.lerp(a: self.frgba[1], b: self.trgba[1], fraction: fraction),
                                     blue: self.lerp(a: self.frgba[2], b: self.trgba[2], fraction: fraction),
                                     alpha: self.frgba[3]) //stick with the original alpha
            (node as! SKShapeNode).fillColor = transColor
        }
        )
    }
	
	func rgbaStrokeTransitionAction(fromColor : UIColor, toColor : UIColor, duration : Double = 0.4) -> SKAction
	{
        fromColor.getRed(&frgba[0], green: &frgba2[1], blue: &frgba3[2], alpha: &frgba4[3])
//        fromColor.getRed(&frgba[0], green: &frgba[1], blue: &frgba[2], alpha: &frgba[3])
		toColor.getRed(&trgba[0], green: &trgba2[1], blue: &trgba3[2], alpha: &trgba4[3])
		
		return SKAction.customAction(withDuration: duration, actionBlock: { (node : SKNode!, elapsedTime : CGFloat) -> Void in
			let fraction = CGFloat(elapsedTime / CGFloat(duration))
			let transColor = UIColor(red: self.lerp(a: self.frgba[0], b: self.trgba[0], fraction: fraction),
			                         green: self.lerp(a: self.frgba[1], b: self.trgba[1], fraction: fraction),
			                         blue: self.lerp(a: self.frgba[2], b: self.trgba[2], fraction: fraction),
			                         alpha: self.lerp(a: self.frgba[3], b: self.trgba[3], fraction: fraction))
			(node as! SKShapeNode).strokeColor = transColor
		}
		)
	}

	
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Circle Alpha Functions
///////////////////////////////////////////////////////////////////////////
    
    public func changeAlpha(strength: Double) {
        if sceneDelegate!.getReadyToPlay() {
            let newAlpha = CGFloat(0.1 + strength * 0.6)
            if newAlpha > 0.0 {
                self.circleAlpha = newAlpha
            }
            else {
                self.circleAlpha = 0.8
            }
        }
    }
	
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Circle Size Functions
///////////////////////////////////////////////////////////////////////////
    public func changeSize(side: Int, size: Double) {
        if sceneDelegate!.getReadyToPlay() {
            let newSize = CGFloat(size)
            if newSize > 0.0 {
                if let circle = self.circle {
					let updateLineWidth = SKAction.customAction(withDuration: 0.0167) {
						(node, elapsedTime) in
						if let nd = node as? SKShapeNode {
//                            nd.strokeColor = colors[side]
							nd.glowWidth =  0//self.glowAmount + newSize * 2 * 48
							nd.lineWidth = self.lineWidth + newSize * 2 * 48
						}
					}
					
					if circle.action(forKey: "updateLineWidth") != nil {
						circle.removeAction(forKey: "updateLineWidth")
					}
					circle.run(updateLineWidth, withKey: "updateLineWidth")
                }
            }
        }
    }
	
	//Overloaded method for changeSize()
    public func changeSize(size: Double) {
        if sceneDelegate!.getReadyToPlay() {
            let newSize = CGFloat(size)
            if newSize > 0.0 {
//                if let circle = self.circle {
//                    let updateLineWidth = SKAction.customAction(withDuration: 0.0167) {
//                        (node, elapsedTime) in
//                        if let nd = node as? SKShapeNode {
//                            nd.glowWidth =  self.glowAmount
//                            nd.lineWidth = self.lineWidth + newSize * 96
//                        }
//                    }
//                    if circle.action(forKey: "updateLineWidth") != nil {
//                        circle.removeAction(forKey: "updateLineWidth")
//                    }
//                    circle.run(updateLineWidth, withKey: "updateLineWidth")
//                }
                self.circleGrow =  newSize * 96.0
            }
            else {
                 self.circleGrow = 0.0
//                if let circle = self.circle {
//                    let updateLineWidth = SKAction.customAction(withDuration: 0.0167) {
//                        (node, elapsedTime) in
//                        if let nd = node as? SKShapeNode {
//                            nd.glowWidth =  self.glowAmount
//                            nd.lineWidth = self.lineWidth
//                        }
//                    }
//                    if circle.action(forKey: "updateLineWidth") != nil {
//                        circle.removeAction(forKey: "updateLineWidth")
//                    }
//                    circle.run(updateLineWidth, withKey: "updateLineWidth")
//                }
            }
        }
    }
	
	
	public func setLineWidth(width: Double) {
		self.lineWidth = CGFloat(width)
	}
	
	public func setGlow(amount: Double) {
		self.glowAmount = CGFloat(amount)
	}
	


/////////////////////////////////////////////////////////////////////////
// MARK: - Touch interaction code
///////////////////////////////////////////////////////////////////////////
    
    var prevPos : Float = 0.0
    var prevY : Float = 0.0
    var xPos : Float = 0.0
    var yPos : Float = 0.0
    var deltaSpin: Float = 0.0
    
	public override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = true
		for t in touches {
			let position :CGPoint = t.location(in: self)
			hit = nodeHitTest(location: position)
			switch (hit) {
			case 1: //ping_red
                hitNode?.setScale(1.2)
				break
			case 2: //ping_blue
                hitNode?.setScale(1.2)
				break
			case 3: //ping_yellow
                hitNode?.setScale(1.2)
				break
			case 4: //ping_green
                hitNode?.setScale(1.2)
				break
			case 5: //ping_orange
                hitNode?.setScale(1.2)
				break
			case 6: //ping_any
				hitNode?.setScale(1.2)
				break
			case 10: //SkoogScene was hit - no other nodes
				self.touchDown(atPoint: t.location(in: self))
            case 20: //Circle
                break
            case 30: //SkoogScene was hit - no other nodes
                self.touchDown(atPoint: t.location(in: self))
			default:
                break
			}
		}
	}
	
	public override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
		for t in touches {
	
			let position :CGPoint = t.location(in: self)
				switch (hit) {
				case 1: //Red
                    hitNode!.position = position
                    break
                case 2: //Blue
                    hitNode!.position = position
                    break
                case 3: //Yellow
                    hitNode!.position = position
                    break
                case 4: //Green
                    hitNode!.position = position
                    break
                case 5: //Orange
                    hitNode!.position = position
                    break
                case 6: //Any
					hitNode!.position = position
					break
				default:
					self.touchMoved(toPoint: t.location(in: self))
					break
				}
		}
	}
	
	public override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.touched = false
		for t in touches {
            switch (hit) {
            case 1: //Red
                break
            case 2: //Blue
                break
            case 3: //Yellow
                break
            case 4: //Green
                break
            case 5: //Orange
                break
            case 6: //Any
                break
            case 20: //Circle
                self.touchUp(atPoint: t.location(in: self))
                break
            case 30: //Hoop
                break
            default:
                break
            }
            hitNode?.setScale(1)
		}
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
            sceneDelegate?.touchUp()
        }
	}
	
	public func nodeHitTest(location: CGPoint) -> Int {
		let node = self.atPoint(location)
		self.hitNode = node.parent
		
        if node.name != nil {
            switch (node.name!){
            case "ping_red":
                return 1
            case "ping_blue":
                return 2
            case "ping_yellow":
                return 3
            case "ping_green":
                return 4
            case "ping_orange":
                return 5
            case "ping_any":
                return 6
            case "skoogScene":
                return 10
            case "circle":
                return 20
            case "hoop":
                return 30
            default:
                return 0
            }
        }
        else {
            return 0
        }
	}
	
	func random() -> CGFloat {
		return CGFloat(Float(arc4random()) / 0xFFFFFFFF)
	}
	
	func random(min: CGFloat, max: CGFloat) -> CGFloat {
		return random() * (max - min) + min
	}
	
	
	public override func update(_ currentTime: CFTimeInterval) {
		self.isUpdating = true
        self.label?.text = self.squeezeLabelText
        self.label?.alpha = self.squeezeLabelAlpha
        self.circle?.strokeColor = currentColor.withAlphaComponent(circleAlpha)
        self.circle?.glowWidth =  self.glowAmount
        self.circle?.lineWidth = circleGrow
        
        
        if self.squeezeLabel?.needsUpdate == true {
            self.squeezeLabel?.update()
        }
        
        if self.soundStyleLabel?.needsUpdate == true {
            self.soundStyleLabel?.update()
        }
	}
    
    public override func didChangeSize(_ oldSize: CGSize) {
        
        let screenSize = self.size
        
        self.pingConstraintFullScreenPortrait = SKConstraint.positionX(SKRange(lowerLimit: -0.5 * screenSize.width + 24 , upperLimit: 0.5 * screenSize.width - 24),
                                                                       y: SKRange(lowerLimit: -0.5 * screenSize.height + 24 , upperLimit: 0.5 * screenSize.height - 24))
        
        for i in 0 ..< pingArray.count {
            pingArray[i]!.constraints = [ self.pingConstraintFullScreenPortrait! ]
        }
   
    }
    
    public override func didFinishUpdate(){
        
        self.isUpdating = false

    }
    
    
}
