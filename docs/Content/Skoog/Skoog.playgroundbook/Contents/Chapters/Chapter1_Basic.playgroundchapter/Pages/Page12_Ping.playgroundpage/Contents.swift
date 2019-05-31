//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 
 */
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal:** Meet the "Ping" - a musical buddy for your Skoog.
 
Ping comes in 6 different flavors: red, blue, yellow, green, orange, and white.
 
 When a ripple or pulse from your Skoog bumps into the Ping, it goes **"ping"** (makes a sound). A red Ping will only respond to red ripples or pulses, blue to blue, and so on. White Pings are special, because they respond to ripples and pulses of all colors.
 
 All Pings play the same sound style as your Skoog, but they can echo back a different note, depending on their `noteShift` property.
 
 * callout(Ping `noteShift`):
    The Ping knows what note caused the colored ripple/pulse that bumped into it and it responds by playing a note that can be the same, higher, or lower than the original  depending on the noteShift argument.
 
 **Exercise** Your Ping can be dragged around the screen. See how it responds differently when it is closer and farther from the Skoog circle and how it responds to ripples and pulses!

 **Challenge** Play with your Ping. Try changing its `color` and its `noteShift` properties.
 */
//#-hidden-code

import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    public var inst: SoundStyle = .marimba
    
func setup() {
	showRipples = false

//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ripple(color:size:), pulse(color:size:))
//#-code-completion(identifier, show, name, side, color, size, strength, value, rawValue)
//#-code-completion(identifier, show, ., red, blue, yellow, green, orange, white)
//#-code-completion(identifier, show, acid, candyBee, fmModulator, sineWave, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani)
//#-code-completion(identifier, show, *, /, +, -, ==, !=, =, ., if, else, {, }, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9)
setSound(/*#-editable-code */.saw/*#-end-editable-code*/)
	
addPing(/*#-editable-code */"red"/*#-end-editable-code*/, noteShift: /*#-editable-code tap to enter a number of notes*/12/*#-end-editable-code*/)
    
//#-hidden-code
}
//#-end-hidden-code
func press(side: Side, strength: Double) {
//#-editable-code
ripple(color: side.color, size: strength)
//#-end-editable-code
}
//#-hidden-code

    public override func peak(_ side: Side,_ peak: Double) {
        press(side: side, strength: peak)
		super.peak(side, peak)

    }
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", contents.skoogSKscene.getBasicDescription(), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient4)

var taskColor = contents.skoogSKscene.pingArray[0]!.colorString
var taskShift = contents.skoogSKscene.pingArray[0]!.noteOffset

if taskColor != "red" && taskShift != 12 {
    PlaygroundPage.current.assessmentStatus = .pass(message: NSLocalizedString("Great job!", comment: "Great job string"))
}

PlaygroundPage.current.liveView = contents
