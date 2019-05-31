//
//  LiveViewController.swift
//  SkoogAPI
//
//  Created by Keith Nagle on 02/08/2016.
//  Copyright © 2016 Skoogmusic Ltd. All rights reserved.
//

import UIKit
import SpriteKit
import CoreBluetooth
import CoreAudioKit
import SceneKit
import PlaygroundSupport

open class LiveViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer, BTUIDelegate {
    public var lvScene = liveScene(size: CGRect(x: 0,
                                                y:	0,
                                                width: 512,
                                                height: 768).size
    )
    
    public let lvView = SKView(frame: CGRect(x: 0,
                                             y:	0,
                                             width: 512,
                                             height: 768)
    )
    
    public let logo = UIImage(named: "skoog-logo-white")
    public var logoView : UIImageView?

    
    var bluetoothUI : BluetoothMIDIViewController?
    
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

    
    public init() {
        super.init(nibName: nil, bundle: nil)
        
        // Do any additional setup after loading the view, typically from a nib.
        
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.clipsToBounds = true
        self.view.translatesAutoresizingMaskIntoConstraints = false
        
        lvView.translatesAutoresizingMaskIntoConstraints = false
        lvView.allowsTransparency = true
        

        self.view.addSubview(lvView)
        
        logoView = UIImageView(image: logo)
        self.view.addSubview(logoView!)
        logoView?.translatesAutoresizingMaskIntoConstraints = false

        
        let horizontalConstraint = NSLayoutConstraint(item: lvView, attribute: .leading, relatedBy: .equal, toItem: self.liveViewSafeAreaGuide, attribute: .leading, multiplier: 1, constant: 0)
        let verticalConstraint = NSLayoutConstraint(item: lvView, attribute: .trailing, relatedBy: .equal, toItem: self.liveViewSafeAreaGuide, attribute: .trailing, multiplier: 1, constant: 0)
        let topConstraint1 = NSLayoutConstraint(item: lvView, attribute: .top, relatedBy: .equal, toItem: self.liveViewSafeAreaGuide, attribute: .top, multiplier: 1, constant:0)
        let bottomConstraint1 = NSLayoutConstraint(item: lvView, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        
        let hcConstraint = NSLayoutConstraint(item: logoView!, attribute: .centerX, relatedBy: .equal, toItem: self.view, attribute: .centerX, multiplier: 1, constant: 0)
        let vcConstraint = NSLayoutConstraint(item: logoView!, attribute: .centerY, relatedBy: .equal, toItem: self.view, attribute: .centerY, multiplier: 1, constant: 0)
        let hConstraint = NSLayoutConstraint(item: logoView!, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant:212)
        let wConstraint = NSLayoutConstraint(item: logoView!, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1, constant: 400)
        
        lvView.ignoresSiblingOrder = true
        
        
        lvView.presentScene(lvScene)
        lvScene.scaleMode = .resizeFill
        lvScene.anchorPoint = CGPoint(x: 0.5, y: 0.5)

        
        self.view.addConstraints([horizontalConstraint, verticalConstraint, topConstraint1, bottomConstraint1, hcConstraint, vcConstraint, hConstraint, wConstraint])
        
        refreshUI()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name(rawValue: skoogNotificationKey), object: nil, queue: nil, using: notify)
        
    }
    
    public func notify(notification:Notification) -> Void {

        guard let userInfo = notification.userInfo else {
                return
        }
        
        if let connectionStatus  = userInfo["connectionStatus"] as? Bool {
            bluetoothUI?.skoogConnected = connectionStatus
            bluetoothUI?.skoogConnectionStatus(connected:connectionStatus)
        }
    }
    
 
    public func refreshUI() {
        if bluetoothUI != nil {
            bluetoothUI!.view.removeFromSuperview()
            bluetoothUI!.removeFromParentViewController()
            bluetoothUI = nil
        }
        bluetoothUI = BluetoothMIDIViewController()
        bluetoothUI?.delegate = self
        bluetoothUI?.view.translatesAutoresizingMaskIntoConstraints = false

        self.addChildViewController(bluetoothUI!)
        self.view.addSubview((bluetoothUI?.view)!)
        
        NSLayoutConstraint.activate([
            bluetoothUI!.view.trailingAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.trailingAnchor, constant: -22),
            bluetoothUI!.view.topAnchor.constraint(equalTo: self.liveViewSafeAreaGuide.topAnchor, constant: 22)
        ])
        
        Timer.scheduledTimer(timeInterval:0.1, target: self, selector: #selector(skoogSearchTask), userInfo: nil, repeats: false)

        
    }
    
    @objc public func skoogSearchTask() {
        Skoog.sharedInstance.searchForSkoog()
    }
    
    
    open override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    public func setBackgroundGradient(gradient: BackgroundGradient){
        
        let bgColor = UIColor(red: 235.0/255.0, green: 235.0/255.0, blue: 235.0/255.0, alpha: 1.0)
        let blendedColor = (bgColor.blend(color: gradient.colors.0, alpha: 0.46),
                            bgColor.blend(color: gradient.colors.1, alpha: 0.46))
        
        lvScene.background?.fillShader = lvScene.linearShader(color: blendedColor.0, endColor: blendedColor.1)
    }

    
    
/////////////////////////////////////////////////////////////////////////
// MARK: - Touchscreen Functions
/////////////////////////////////////////////////////////////////////////

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //refreshUI()
        if self.bluetoothUI!.state == State.selecting {
            if self.bluetoothUI!.skoogConnected {
                self.bluetoothUI?.update(state: State.connected)
            }
            else {
                self.bluetoothUI?.update(state: State.noConnection)
            }
        }
        else if self.bluetoothUI!.state == State.searching {
            self.bluetoothUI?.update(state: State.noConnection)
        }
    }
}

public class liveScene: SKScene {
    
    public var background : SKShapeNode?
//    public var logoTexture = SKTexture(imageNamed:"skoog-logo-white")
//    public var logo : SKSpriteNode?
    public var skoogBase = SKSpriteNode(imageNamed: "SkoogBase")
    public var connectionHand = SKSpriteNode(imageNamed: "PressHand")
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public override init(size: CGSize) {
        super.init(size: size)
        
        background = SKShapeNode(rectOf: CGSize(width: 1400, height: 1400))
        background?.zPosition = -500
        background?.lineWidth = 0
        background?.alpha = 0.1
        background?.fillShader = linearShader(color: .orange, endColor: .purple)
        
        background?.name = "background"
        self.addChild(background!)
    }
    
    public override func sceneDidLoad(){
//        logo = SKSpriteNode(texture: logoTexture)
//        self.addChild(logo!)
//        logo?.position = CGPoint(x: 0, y: 0)
//        logo?.size = CGSize(width: 400, height: 212)
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
}

extension LiveViewController: PlaygroundLiveViewMessageHandler {
    public func liveViewMessageConnectionOpened() {
        // We don't need to do anything in particular when the connection opens.
    }
    
    public func liveViewMessageConnectionClosed() {
        // We need to make sure the bluetoothUI refreshes itself when the connection closes.
        refreshUI()
    }
    
    public func receive(_ message: PlaygroundValue) {
        guard case let .string(text) = message else {return}
        // add any response to the message here
    }
}
