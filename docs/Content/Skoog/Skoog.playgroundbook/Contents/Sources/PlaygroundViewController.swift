//
//  PlaygroundViewController.swift
//  SkoogAPI
//
//  Created by David Skulina and Keith Nagle.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//
//import PlaygroundBluetooth
import UIKit
import SpriteKit
import CoreBluetooth
import CoreAudioKit
import SceneKit
import PlaygroundSupport

public typealias Index = Int
public typealias MidiNoteNumber = Int
public typealias MidiChannel = Int
public typealias MidiVelocity = Int

public var enableVoiceOver = true

open class PlaygroundViewController: UIViewController, bleMessagesDelegate, SkoogSceneDelegate, SkoogDelegate, GraphSceneDelegate, PlaygroundLiveViewMessageHandler, PlaygroundLiveViewSafeAreaContainer {
    
    public var drawGraph = false
    public var changeAlpha = false
    public var growCircle = false
    public var showRipples = false
    public var playNotes = true
	public var releaseNotes = false
    public var changeColor = true
    public var showPressLabels = false
    public var showSqueezeLabel = false
	public var showNoteLabels = false
    public var peakMode = true
    
    public var announcementString : String = ""
    public var colorString : String = ""
    public var rippleString : String = ""
    public var pulseString : String = ""
    public var growString : String = ""
    public var alphaString : String = ""
    
    public var calibrationTimer : Timer?

    
    var firmwareMajorVersion : Int = -1 {
        didSet {
            setFirmwareMajorVersion(firmwareMajorVersion: firmwareMajorVersion) 
        }
    }
    var firmwareMinorVersion : Int = -1 {
        didSet {
            setFirmwareMinorVersion(firmwareMinorVersion: firmwareMinorVersion)
        }
    }

    let playground      = self
	
	/// Instrument
    public var instrument  : Instrument = Instrument()
    public var instType	: SoundStyle = .marimba

	public enum Scale {
		case major, majorBlues, minor, minorBlues
	}
	
	public enum Note {
		case C,Csharp,D,Eflat,E,F,Fsharp,G,Gsharp,A,Bflat,B
	}
		
    public var notes : [MidiNoteNumber] = [60,62,64,65,67]


    public var skoogSKscene = SkoogScene(size: CGRect(x: 0,
                                                      y:	0,
                                                      width: 512,
                                                      height: 768).size
    )
    
    public let skoogSKView = SKView(frame: CGRect(x: 0,
                                                  y:	0,
                                                  width: 512,
                                                  height: 768)
    )
    
    var bluetoothUI : BluetoothMIDIViewController?
    
    var connectedPeripheral : CBPeripheral?
    
    
    
    
    
    public var bluetooth : BLEMessages?
    public var skoogConnected : Bool = false
    var newConnection : Bool = false
    var connectedSkoog : CBPeripheral? = nil
    public var readyToPlay : Bool = false

    
    public let skoog    = Skoog.sharedInstance
    
    public let red = Side()
    public let blue = Side()
    public let yellow = Side()
    public let green = Side()
    public let orange = Side()
    public var skoogSides : [Side] = []
    public var currentSide = Side()
    
    public var rectangle = GraphScene(size: CGRect(x: 0,
                                                   y:	0,
                                                   width: 512,
                                                   height: 768).size
    )
	
	
    public enum BackgroundGradient {
        case gradient1
        case gradient2
        case gradient3
        case gradient4
        case gradient5
        case gradient6
        var colors: (UIColor, UIColor) {
            switch self {
            case .gradient1:
                return (color1: UIColor(red: 151.0/255.0, green: 170.0/255.0, blue: 219.0/255.0, alpha: 1.0),
                        color2: UIColor(red: 234.0/255.0, green: 64.0/255.0, blue: 99.0/255.0, alpha: 1.0))
            case .gradient2:
                return (color1: UIColor(red: 18.0/255.0, green: 214.0/255.0, blue: 226.0/255.0, alpha: 1.0),
                        color2: UIColor(red: 112.0/255.0, green: 224.0/255.0, blue: 154.0/255.0, alpha: 1.0))
            case .gradient3:
                return (color1: UIColor(red: 89.0/255.0, green: 201.0/255.0, blue: 171.0/255.0, alpha: 1.0),
                color2: UIColor(red: 255.0/255.0, green: 235.0/255.0, blue: 106.0/255.0, alpha: 1.0))
            case .gradient4:
                return (color1: UIColor(red: 197.0/255.0, green: 222.0/255.0, blue: 158.0/255.0, alpha: 1.0),
                        color2: UIColor(red: 127.0/255.0, green: 168.0/255.0, blue: 215.0/255.0, alpha: 1.0))
            case .gradient5:
                return (color1: UIColor(red: 125.0/255.0, green: 204.0/255.0, blue: 199.0/255.0, alpha: 1.0),
                        color2: UIColor(red: 255.0/255.0, green: 246.0/255.0, blue: 159.0/255.0, alpha: 1.0))
            case .gradient6:
                return (color1: UIColor(red: 18.0/255.0, green: 214.0/255.0, blue: 226.0/255.0, alpha: 1.0),
                        color2: UIColor(red: 112.0/255.0, green: 224.0/255.0, blue: 154.0/255.0, alpha: 1.0))
            }
        }
    }







/////////////////////////////////////////////////////////////////////////
// MARK: - Initialisation Code
/////////////////////////////////////////////////////////////////////////
	
    public init() {
        super.init(nibName: nil, bundle: nil)
        // Do any additional setup after loading the view, typically from a nib.
        red.index = 0
        blue.index = 1
        yellow.index = 2
        green.index = 3
        orange.index = 4

        red.name = .red
        blue.name = .blue
        yellow.name = .yellow
        green.name = .green
        orange.name = .orange
        
        red.color      =   skoog.red.color
        blue.color     =   skoog.blue.color
        yellow.color   =   skoog.yellow.color
        green.color    =   skoog.green.color
        orange.color   =   skoog.orange.color
        
        instrumentSetup() // change instrument soundfont

        self.skoogSides = [red, blue, yellow, green, orange]
 
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    @objc func applicationWillEnterForeground(notification: NSNotification) {
        // here my app did become active
        enableVoiceOver = true
    }
    @objc func applicationWillResignActive(notification: NSNotification) {
        // here my app did enter background
        enableVoiceOver = false
    }
    
    open override func viewDidLoad() {
		super.viewDidLoad()
        
        // Observer UIApplicationDidBecomeActive,UIApplicationDidEnterBackground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaygroundViewController.applicationWillEnterForeground(notification:)),
            name: NSNotification.Name.UIApplicationWillEnterForeground,
            object: nil)
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(PlaygroundViewController.applicationWillResignActive(notification:)),
            name:NSNotification.Name.UIApplicationWillResignActive,
            object: nil)
        
        self.view.backgroundColor = .clear
        
        self.view.clipsToBounds = true
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        skoog.setPolyMode(active: false)
        
        skoog.delegate = self
        
        bluetooth = BLEMessages()
        bluetooth?.delegate = self
        
        
        skoogSKView.translatesAutoresizingMaskIntoConstraints = false
        skoogSKView.allowsTransparency = true
//        skoogSKView.showsNodeCount = true // uncomment for testing
//        skoogSKView.showsFPS = true // uncomment for testing
//        skoogSKView.showsDrawCount = true // uncomment for testing
        // Our feedback circle display
        self.view.addSubview(skoogSKView)
        
        let horizontalConstraint = NSLayoutConstraint(item: skoogSKView, attribute: .leading, relatedBy: .equal, toItem: self.view, attribute: .leading, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: skoogSKView, attribute: .trailing, relatedBy: .equal, toItem: self.view, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint1 = NSLayoutConstraint(item: skoogSKView, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant:0)
        let bottomConstraint1 = NSLayoutConstraint(item: skoogSKView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant:0)

        skoogSKView.ignoresSiblingOrder = true
        
        if self.drawGraph {
            rectangle.scaleMode = .resizeFill
            rectangle.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            rectangle.graphSceneDelegate = self
            skoogSKView.presentScene(rectangle)
        }
        else {
            skoogSKscene.scaleMode = .resizeFill // .fill .resizeFill aspectFit .aspectFill
            skoogSKscene.anchorPoint = CGPoint(x: 0.5, y: 0.5)
            skoogSKscene.sceneDelegate = self
            skoogSKView.presentScene(skoogSKscene)
        }
        
        // adjust sensitivity for each side of the Skoog. Value range is 0 to 12
        for i in 0 ... 4 {
            setResponse(index: i, value: 2.0)
        }
        
        refreshBTUI() //initialise the BT MIDI UI
        

        self.view.addConstraints([horizontalConstraint, verticalConstraint, topConstraint1, bottomConstraint1])
        
        
//        // The timer corrects a display issue where the CABTMIDICentralViewController
//        // might display part of itself "offscreen"
        Timer.scheduledTimer(timeInterval:0.1, target: self, selector: #selector(skoogSearchTask), userInfo: nil, repeats: false)
    }
    
    public func receive(_ message: PlaygroundValue) {
        if case let .boolean(test) = message {
            if test == false {
                self.setBackgroundGradient(gradient: .gradient6)
            }
        }
    }
	
    public func refreshBTUI() {
        if bluetoothUI != nil {
            bluetoothUI!.view.removeFromSuperview()
            bluetoothUI!.removeFromParentViewController()
            bluetoothUI = nil
        }
        bluetoothUI = BluetoothMIDIViewController()
        bluetoothUI?.view.translatesAutoresizingMaskIntoConstraints = false
        
        self.addChildViewController(bluetoothUI!)
        self.view.addSubview((bluetoothUI?.view)!)
        
//        let BTtopConstraint = bluetoothUI!.view.topAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.topAnchor, constant: 22)
        //BTtopConstraint.priority = UILayoutPriorityDefaultLow
        
        NSLayoutConstraint.activate([
            bluetoothUI!.view.trailingAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.trailingAnchor, constant: -22),
            bluetoothUI!.view.topAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.topAnchor, constant: 22)
            ])
        
        Timer.scheduledTimer(timeInterval:0.1, target: self, selector: #selector(skoogSearchTask), userInfo: nil, repeats: false)
    }
    
    public func setBackgroundGradient(gradient: BackgroundGradient){
        
        let bgColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
        let blendedColor = (bgColor.blend(color: gradient.colors.0, alpha: 0.46),
                            bgColor.blend(color: gradient.colors.1, alpha: 0.46))
        
		skoogSKscene.background?.fillShader = skoogSKscene.linearShader(color: blendedColor.0, endColor: blendedColor.1)
        
        if drawGraph {
            rectangle.background?.fillShader = skoogSKscene.linearShader(color: blendedColor.0, endColor: blendedColor.1)
        }
	}
	
	
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Skoog Functions
/////////////////////////////////////////////////////////////////////////
    public func setFirmwareMajorVersion(firmwareMajorVersion : Int) {
        if self.skoogConnected {
            self.skoog.firmwareMajorVersion = firmwareMajorVersion 
        }
    }
    
    public func setFirmwareMinorVersion(firmwareMinorVersion : Int) {
        if self.skoogConnected {
            self.skoog.firmwareMinorVersion = firmwareMinorVersion
            self.skoog.initialiseSkoog()
        }
    }
    
    @objc public func skoogSearchTask() {
        skoog.searchForSkoog()
        // if we have a BLE connection to Skoog this will trigger a calibration
        // If not, nothing will happen, it will fail gracefully.
    }
    
    public func setResponse(index: Int, value: Double) {
        skoog.sides[index].response = value
    }
    
    public func getReadyToPlay() -> Bool {
        return readyToPlay
    }
    
    public func setReadyToPlay(value: Bool? = nil){
        if let val = value {
            if val {
                if skoog.skoogConnected {
                    skoog.calibrating = false
                }
            }
        
            self.readyToPlay = val
            
            red.active = val
            blue.active = val
            yellow.active = val
            green.active = val
            orange.active = val
        }
    }
    
    @objc public func setReadyToPlay(){
        if skoog.skoogConnected {
            self.readyToPlay = true
            skoog.calibrating = false
            red.active = true
            blue.active = true
            yellow.active = true
            green.active = true
            orange.active = true
        }
    }
    
    @objc public func calibrateTask() {
        skoog.calibrating = true
        bluetooth?.calibrate()
        
        if self.calibrationTimer != nil {
            if (self.calibrationTimer?.isValid)! {
                self.calibrationTimer?.invalidate()
            }
        }
        
        self.calibrationTimer = Timer.scheduledTimer(timeInterval:1.0, target: self, selector: #selector(setReadyToPlay), userInfo: nil, repeats: false)
    }
    
    public func skoogConnectionStatus(_ connected: Bool) {
        bluetoothUI?.skoogConnectionStatus(connected: connected)
        
        if connected == true && skoog.skoogConnected == true{
            bluetooth?.findSkoog(shouldConnect: true)
            Timer.scheduledTimer(timeInterval:1.5, target: self, selector: #selector(calibrateTask), userInfo: nil, repeats: false)
            if self.drawGraph {
                rectangle.animateCalibration()
            }
            else {
                skoogSKscene.animateCalibration()
            }
        }
        else {
            setReadyToPlay(value:false) //this has to happen beofew showing the CABT
        }
    }
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Threshold Functions
/////////////////////////////////////////////////////////////////////////
    
	
    public func updateThresholds() {
        rectangle.updateThresholds()
    }
    
    public func setThresholds(red: Double? = nil, blue: Double? = nil, yellow: Double? = nil, green: Double? = nil, orange: Double? = nil){
        if let Red = red {
            self.red.threshold = Double(Red)
            self.skoog.sides[0].threshold = self.red.threshold
        }
        
        if let Blue = blue {
            self.blue.threshold = Double(Blue)
            self.skoog.sides[1].threshold = self.blue.threshold
        }
        
        if let Yellow = yellow {
            self.yellow.threshold = Double(Yellow)
            self.skoog.sides[2].threshold = self.yellow.threshold
        }
        
        if let Green = green {
            self.green.threshold = Double(Green)
            self.skoog.sides[3].threshold = self.green.threshold
        }
        
        if let Orange = orange {
            self.orange.threshold = Double(Orange)
            self.skoog.sides[4].threshold = self.orange.threshold
        }
        self.skoogSides = [self.red, self.blue, self.yellow, self.green, self.orange]
        rectangle.skoogSides = self.skoogSides
    }
	
	
	
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Alpha Functions
/////////////////////////////////////////////////////////////////////////
    
    public func alphaOn() {
        self.changeAlpha = true
    }
    
    public func alphaOff() {
        self.changeAlpha = false
    }

    public func alpha(value: Double){
        self.alphaString = NSLocalizedString("changing alpha", comment: "changing alpha string")
        skoogSKscene.changeAlpha(strength: value)
    }

    
/////////////////////////////////////////////////////////////////////////
// MARK: - Ripple Functions
/////////////////////////////////////////////////////////////////////////
    
    public func rippleOn() {
        showRipples = true
    }
    
    public func setRipple(time: Double) {
        if time <= 0.0 {
            skoogSKscene.durationMultiplier = 0.001
        }
        else {
            skoogSKscene.durationMultiplier = time
        }
    }
	
    public func setRipple(speed: Double) {
        if speed <= 0.1 {
            skoogSKscene.durationMultiplier = 10
        }
        else {
            skoogSKscene.durationMultiplier = 1/speed
        }
    }
    
    
/**
	Triggers an expanding circle in the liveView.
	
	- parameters:
	- color: lets the ripple know what color to be (optional).  Defaults to `.white` if unspecified.
	- size: tells it how big to be when it is created (optional). Defaults to `1.0` if unspecified.
*/
    open func ripple(color: UIColor? = nil, size: Double? = nil) {
        self.rippleString = NSLocalizedString("ripple", comment: "ripple string")
        
		var c = color
		if c == nil {
            c = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.05)   // white
		}
        
        var s = size
		if s == nil {
            s = 0.025
        }
        skoogSKscene.startRipple(color: c!, size: s!)
    }
    
    
    /**
     Triggers an pulsing glow around the skoog circle in the liveView.
     
     - parameters:
     - color: lets the ripple know what color to be (optional).  Defaults to `.white` if unspecified.
     - size: tells it how big to be when it is created (optional). Defaults to `1.0` if unspecified.
     */
    open func pulse(color: UIColor? = nil, size: Double? = nil) {
        self.pulseString = NSLocalizedString("pulse", comment: "pulse string")
        var c = color
        if c == nil {
            c = SKColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)   // white
        }
        
        var s = size
        if s == nil {
            s = 0.025
        }
        skoogSKscene.startPulse(color: c!, size: s!)
    }

	
	public func releaseRipple(side: Side) {
		skoogSKscene.releaseRipple(color: side.color)
	}

	
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Label Functions
/////////////////////////////////////////////////////////////////////////


    public func printMessage(_ message: String, value : String? = "", side: Side? = nil, style: LabelStyle? = LabelStyle.random){
        if let mySide = side {
            skoogSKscene.messageLabelFade(message: message, side: mySide, value: value, style: style!)
        }
        else {
            skoogSKscene.messageLabelFade(message: message, value: value, style: style!)
        }
    }
	
    public func printSoundStyle(){
        skoogSKscene.soundStyleLabel?.setValueUpdate(text: "\(instrument.type)".uppercaseFirst)
        skoogSKscene.soundStyleLabel?.setAlphaUpdate(alpha: 0.8)
    }
    
    public func printSqueeze(_ value: Double, colorName: String = ""){
        if readyToPlay {
            if value > 0.004 {
                if (skoogSKscene.squeezeLabel?.hasActions())! {
                    skoogSKscene.squeezeLabel?.removeAllActions()
                }
                skoogSKscene.squeezeLabel?.setLabelUpdate(text: colorName.uppercaseFirst + " ")
                skoogSKscene.squeezeLabel?.setValueUpdate(text: String(format:"%0.2f", value))
                skoogSKscene.squeezeLabel?.setAlphaUpdate(alpha: CGFloat(0.5 * (1.0 + value)))
            }
            else {
                if !(skoogSKscene.squeezeLabel?.hasActions())! {
					skoogSKscene.squeezeLabel?.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3), completion: {
						self.skoogSKscene.squeezeLabel?.setValueUpdate(text: String(format:"%0.2f", 0.00))
                        self.skoogSKscene.squeezeLabel?.setAlphaUpdate(alpha: 0.2)
                    })
                }
            }
        }
    }
	
	
	public func squeezeLabel(_ value: Double){
        if readyToPlay {
            if value > 0.004 {
                if (skoogSKscene.label?.hasActions())! {
                    skoogSKscene.label?.removeAllActions()
                }
                skoogSKscene.squeezeLabelText = NSLocalizedString("Squeeze", comment: "Squeeze label") + " = " + String(format:"%0.2f", value)
                skoogSKscene.squeezeLabelAlpha = CGFloat(0.5 * (1.0 + value))
            }
            else{
                if !(skoogSKscene.label?.hasActions())! {
					skoogSKscene.label?.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3), completion: {
                        self.skoogSKscene.squeezeLabelAlpha = 0.2
                    })
                }
            }
        }
	}
	
    
    public func squeezeLabel(_ value: Double, colorName: String = ""){
        if readyToPlay {
            if value > 0.004 {
                if (skoogSKscene.label?.hasActions())! {
                    skoogSKscene.label?.removeAllActions()
                }
                skoogSKscene.squeezeLabelText = colorName.uppercaseFirst + " " + NSLocalizedString("Squeeze", comment: "Squeeze label") + " = " + String(format:"%0.2f", value)
                skoogSKscene.squeezeLabelAlpha = CGFloat(0.5 * (1.0 + value))
            }
            else{
                if !(skoogSKscene.label?.hasActions())! {
					skoogSKscene.label?.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3), completion: {
                      self.skoogSKscene.squeezeLabelAlpha = 0.2
                    })
                }
            }
        }
    }
    
	
	public func squeezeLabel(_ value: Double, graph: Bool){
		if graph && readyToPlay {
            if value > 0.000 {
                if (rectangle.squeezeLabel?.hasActions())! {
                    rectangle.squeezeLabel?.removeAllActions()
                }
                rectangle.squeezeLabelText = NSLocalizedString("Squeeze", comment: "Squeeze label") + " = " + String(format:"%0.2f", value)
                rectangle.squeezeLabelAlpha = CGFloat(0.5 * (1.0 + value))
            }
            else{
                if !(rectangle.squeezeLabel?.hasActions())! {
					rectangle.squeezeLabel?.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3), completion: {
                        self.rectangle.squeezeLabelAlpha = 0.2
                    })
                }
            }
        }
	}
	
    public func squeezeLabel(_ value: Double, graph: Bool, colorName: String = ""){
        if graph && readyToPlay {
            if value > 0.000 {
                if (rectangle.squeezeLabel?.hasActions())! {
                    rectangle.squeezeLabel?.removeAllActions()
                }
                rectangle.squeezeLabelText = colorName.uppercaseFirst + " " + String(format:"%0.2f", value)
                rectangle.squeezeLabelAlpha = CGFloat(0.5 * (1.0 + value))
            }
            else{
                if !(rectangle.squeezeLabel?.hasActions())! {
					rectangle.squeezeLabel?.run(SKAction.fadeAlpha(to: 0.2, duration: 0.3), completion: {
                        self.rectangle.squeezeLabelAlpha = 0.2
                    })
                }
            }
        }
    }
	
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Grow Functions
/////////////////////////////////////////////////////////////////////////
    
	public func grow(side: Side, value: Double){
        self.growString = NSLocalizedString("changing size", comment: "changing size string")
		skoogSKscene.changeSize(side: side.index, size: value)

	}
    
    public func grow(value: Double) {
        self.growString = NSLocalizedString("changing size", comment: "changing size string")
        skoogSKscene.changeSize(size: value)
        
    }
	
    public func grow() {
        self.growCircle = true
    }
    
    public func dontGrow() {
        self.growCircle = false
    }
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Glow Functions
/////////////////////////////////////////////////////////////////////////
    
    public func glow(value: Double){
        skoogSKscene.setGlow(amount: value)
    }
    
    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Touchscreen Functions
/////////////////////////////////////////////////////////////////////////
    
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //refreshUI()
        print ("self.bluetoothUI!.state = \(self.bluetoothUI!.state)")
        if self.bluetoothUI!.state == State.selecting {
            if self.bluetoothUI!.skoogConnected {
                self.bluetoothUI?.update(state: State.connected)
                print ("updating to state = \(State.connected)")
            }
            else {
                self.bluetoothUI?.update(state: State.noConnection)
                print ("updating to state = \(State.noConnection)")

            }
        }
        else if self.bluetoothUI!.state == State.searching || self.bluetoothUI!.state == State.disconnecting {
            self.bluetoothUI?.update(state: State.noConnection)
            print ("updating to state = \(State.noConnection)")
        }        
    }

    
    public func touchUp() {
        setReadyToPlay(value:false)
        bluetooth?.findSkoog(shouldConnect: true)
        Timer.scheduledTimer(timeInterval:1.0, target: self, selector: #selector(calibrateTask), userInfo: nil, repeats: false)
    }

	
/////////////////////////////////////////////////////////////////////////
// MARK: - Instrument setup methods
/////////////////////////////////////////////////////////////////////////
    
    // set a default instrument sound.
    public func instrumentSetup() {
        setSound(.marimba)
    }
	
	/**
	Set the Sound Style for the Skoog.
	- parameters:
		- style: name of the Sound Style.
	
	*/
    public func setSound(_ style: SoundStyle) {
        if style != instrument.type {
            instrument.stopGraph()
            instrument.type = style
            instrument.loadSoundStyle(type: style)
            instrument.startGraph()
        }
    }
/////////////////////////////////////////////////////////////////////////
// MARK: - Note setup methods
/////////////////////////////////////////////////////////////////////////

	/**
	Helper function to set the musical note for each side of the Skoog. Notes can be set individually or all together. Here is how to set each side to play the first 5 notes of the C-major scale:
     
        setNotes(red:    60,
                 blue:   62,
                 yellow: 64,
                 green:  65,
                 orange: 67)
     
	 - parameters:
		- red: Set the MIDI number for the red side (optional).
		- blue: Set the MIDI number for the blue side (optional).
		- yellow: Set the MIDI number for the yellow side (optional).
		- green: Set the MIDI number for the green side (optional).
		- orange: Set the MIDI number for the orange side (optional).
	 */
    public func setNotes(red: MidiNoteNumber? = nil, blue: MidiNoteNumber? = nil, yellow: MidiNoteNumber? = nil, green: MidiNoteNumber? = nil, orange: MidiNoteNumber? = nil){
        if let Red = red {
            notes[0] = Red
        }
        
        if let Blue = blue {
            notes[1] = Blue
        }
        
        if let Yellow = yellow {
            notes[2] = Yellow
        }
        
        if let Green = green {
            notes[3] = Green
        }
        
        if let Orange = orange {
            notes[4] = Orange
        }
    }
	
	public func setNotes(side: Side, note: MidiNoteNumber){
			notes[side.index] = note
	}
	
	public func setScale(root: Note, type: Scale, octave: Int){
		
		var intervals : [Int]
		let offset = octave * 12 + root.hashValue
		
		switch type {	 //			 C D E F G A B  C
			case .major: //TTSTTTS - 0 2 4 5 7 9 11 12
				intervals = [0,2,4,7,9]
			case .majorBlues:
				intervals = [0,2,5,7,9]
			case .minor: //TSTTSTT - 0 2 3 5 7 8 10 12
				intervals = [0,3,5,7,10]
			case .minorBlues: 
				intervals = [0,3,5,8,10]
			}
		let newNotes = intervals.map { $0 + offset }
		
		setNotes(red	: newNotes[0],
				 blue	: newNotes[1],
				 yellow	: newNotes[2],
				 green	: newNotes[3],
				 orange : newNotes[4])
		
	}
	
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Ping methods
/////////////////////////////////////////////////////////////////////////
	open func pingPlay(index: Int, offset: Int, strength: Double) {
        instrument.noteOn(noteNum: notes[index] + offset,
                          velocity: MidiVelocity(18.0 + strength*109.0),
                          channel: index)
	}
    
    open func pingStop(index: Int, offset: Int) {
		instrument.noteOff(noteNum: notes[index%5] + offset,
						   channel: index%5)
    }
    
    public func addPing(_ type: String, noteShift: MidiNoteNumber) {
        skoogSKscene.createPingNode(type: type, noteOffset: noteShift)
    }
	
	public func addPing(_ type: String, noteShift: MidiNoteNumber, distance: Double ) {
		skoogSKscene.createPingNode(type: type, noteOffset: noteShift, distance: distance)
	}
	
    public func addPing(_ type: String, noteShift: MidiNoteNumber, angle: Double ) {
        skoogSKscene.createPingNode(type: type, noteOffset: noteShift, angle: angle)
    }
    
    public func addPing(_ type: String, noteShift: MidiNoteNumber, distance: Double, angle: Double ) {
        skoogSKscene.createPingNode(type: type, noteOffset: noteShift, distance: distance, angle: angle)
    }
    
    

	
/////////////////////////////////////////////////////////////////////////
// MARK: - MIDI methods
/////////////////////////////////////////////////////////////////////////

    public func noteOn(sideIndex: Index, velocity:Double) {
        if readyToPlay == true{
            instrument.noteOn(noteNum: notes[sideIndex],
                              velocity: MidiVelocity(48.0 + velocity*79.0),
                              channel: sideIndex)
        }

        if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
            if self.drawGraph {
                if self.rectangle.rectangle?.announceAX == true {
                    UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, skoogSides[sideIndex].name.rawValue)
                }
            }
            if skoogSKscene.circle?.announceAX == true {
                self.colorString = String(format: "%@", skoogSides[sideIndex].name.rawValue)
            }
        }
    }
    
    public func noteOff(sideIndex: Index) {
        instrument.noteOff(noteNum: notes[sideIndex],
                           channel: sideIndex)
    }
    
    public func volume(sideIndex: Index, value:Double){
        instrument.volume(value: Int(Float(value) * 127.0),
                          channel: sideIndex) //offset by 2: MPE note channels start at 2
    }
    
    
    public func modulate(sideIndex: Index, value:Double){
        instrument.modulate(value: Int(Float(value) * 127.0),
                            channel: sideIndex) //offset by 2: MPE note channels start at 2
    }
    
    public func pan(sideIndex: Index, value:Double){
        instrument.pan(value: Int(Float(value) * 127.0),
                       channel: sideIndex) //offset by 2: MPE note channels start at 2
    }
    
    public func expression(sideIndex: Index, value:Double){
        instrument.expression(value: Int(Float(value) * 127.0),
                              channel: sideIndex) //offset by 2: MPE note channels start at 2
    }
    
    public func pitchBend(sideIndex: Index, value:Double){
        instrument.pitchBend(bend: Int(Float(1 + value) * 8192.0),
                             channel: sideIndex)
    }
    
    public func pitchBendUp(sideIndex: Index, value:Double){
        
        instrument.pitchBend(bend: Int(Float(1 + value) * 8192.0),
                             channel: sideIndex)
    }
    
    public func pitchBendDown(sideIndex: Index, value:Double){
        instrument.pitchBend(bend: Int(Float(1 - value) * 8192.0),
                             channel: sideIndex)
    }
    
    public func pitchBendRange(range:Int){
        for i in 0 ... 4 {
            instrument.pitchRange(range: range,
                                  channel: i) //offset by 2: MPE note channels start at 2
        }
    }
    
    public func channelPressure(sideIndex: Index, value:Double){
        instrument.channelPressure(pressure: Int(Float(value) * 127.0),
                                   channel: sideIndex)
    }

	
	public func afterTouch(sideIndex: Index, value:Double){
		instrument.afterTouch(note:		notes[sideIndex],
		                      touch:	Int(Float(value) * 127.0),
		                      channel:	sideIndex)
	}
	
/////////////////////////////////////////////////////////////////////////
// MARK: - FX methods
/////////////////////////////////////////////////////////////////////////
 
    public func filterCutOff(frequency: Double){
        instrument.filterCutOff(frequency: frequency)
    }
	
    public func filterResonance(resonance: Double){
        instrument.filterResonance(resonance: resonance)
    }

	
	
	
/////////////////////////////////////////////////////////////////////////
// MARK: - Delegate methods - overridden in Contents.swift
/////////////////////////////////////////////////////////////////////////
    
    public func playNote(side: Side, strength: Double) {

		noteOn(sideIndex:side.index, velocity: strength)

		if self.changeColor {
			skoogSKscene.changeCircleColor(side: side.index, size: side.rawValue)
		}
		if self.showPressLabels {
			skoogSKscene.labelFade(side:side, value: strength)
		}
		if self.showRipples {
			ripple(color: side.color, size: strength)
		}
		if self.showNoteLabels {
			skoogSKscene.noteLabelFade(side:side, note: notes[side.index])
		}
    }

    
    
    open func peak(_ side: Side,_ peak: Double) {
        // handle global setup
        if side.active {
            if self.playNotes {
                noteOn(sideIndex:side.index, velocity: peak)
            }
            if self.changeColor {
                skoogSKscene.changeCircleColor(side: side.index, size: peak)
            }
            if self.showPressLabels {
                skoogSKscene.labelFade(side:side, value: peak)
            }
            if self.showRipples {
                ripple(color: side.color, size: peak)
            }
            if self.showNoteLabels {
                skoogSKscene.noteLabelFade(side:side, note: notes[side.index])
            }
            let fullString = String(format: " %@ %@ %@ %@ %@", self.colorString, self.rippleString, self.pulseString, self.growString, self.alphaString)
            self.announcementString.append(fullString)
            if self.announcementString != "" {
                if UIAccessibilityIsVoiceOverRunning() && enableVoiceOver {
                    if skoogSKscene.circle?.announceAX == true {
                        UIAccessibilityPostNotification(UIAccessibilityAnnouncementNotification, self.announcementString)
                    }
                }
            }
        }
    }
    
    open func continuous(_ side: Side) {
        // handle global setup
        if side.active {
            if self.changeAlpha {
                alpha(value: side.rawValue)
            }
            if self.growCircle {
                grow(side: side, value: side.rawValue)
            }
            if self.showSqueezeLabel {
                printSqueeze(side.rawValue, colorName: side.name.rawValue)
            }
            if self.drawGraph {
                rectangle.addDataPoint(side: side.index, value: side.rawValue)
                squeezeLabel(side.rawValue, graph: true, colorName: side.name.rawValue)
            }
        }
    }
	
    open func release(_ side: Side) {
        // handle global setup
        if self.playNotes || !skoog.skoogConnected || self.releaseNotes{
            noteOff(sideIndex:side.index)
        }
		if !skoogSKscene.pingArray.isEmpty { //only send release ripples if any Pings exist
			releaseRipple(side: side)
        }
        
        if self.changeColor {
            skoogSKscene.changeCircleColor(side: side.index, size: 0.0)
        }
        
        self.announcementString = ""
        self.colorString = ""
        self.rippleString = ""
        self.pulseString = ""
        self.growString = ""
        self.alphaString = ""
    }
    open func updateProbe(_ packet: [Int]) {
        // do nothing in Swift Playgrounds
    }
    open func showMagnetWarning() {
        // do nothing in Swift Playgrounds
    }
}
