//#-hidden-code
/*
 Copyright (C) 2016 Skoogmusic Ltd. All Rights Reserved.
 See LICENSE.txt for this sample’s licensing information.
 
 */
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")

**Goal:** Set up multiple Pings. It’s time for your performance!

This is your blank canvas: choose your notes and instrument, set up your display, and try adding a few extra Pings to the `setup()` block of your code too. Refer back to previous pages if you have to, and have fun!

 * callout(To add a Ping):
    `addPing("white", noteShift: 12, distance: Double?, angle: Double? )`

By default Pings are arranged in a spiral, creating a cascade of notes. They can also be arranged by distance from the center (measured as the number of Ping diameters), and by angle (in degrees clockwise from 12 o'clock).

**Exercise 1:** Create three blue Pings at a distance of 1.0, and noteShifts of 5, 10, and 14 to make a chord.\
**Exercise 2:** To play a simple note sequence, add three red Pings at a fixed angle at distances of 0.5, 1.5, and 2.5, and noteShifts of 12, 19, 24.
  * callout(Tip):
   Pings are best enjoyed in fullscreen! Touch the middle of the screen till the slider appears then drag left.
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
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ripple(color:size:), pulse(color:size:))
//#-code-completion(identifier, show, addPing(_:noteShift:distance:angle:))

//#-code-completion(identifier, show, setNotes, setRipple, speed, noteShift, distance, angle, side, color, size, strength, value, rawValue, addPing, setSound(_:), Instrument.type, ., name, true, false)
//#-code-completion(identifier, show, acid, candyBee, fmModulator, sineWave, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani)
//#-code-completion(literal, show, boolean, color)
//#-code-completion(keyword, show, for, if, let, var, while)
setSound(/*#-editable-code */.marimba/*#-end-editable-code*/)
	
setRipple(speed: /*#-editable-code */1.0/*#-end-editable-code*/)
	
setNotes(red:   /*#-editable-code */48/*#-end-editable-code*/,
		blue:   /*#-editable-code */50/*#-end-editable-code*/,
		yellow: /*#-editable-code */52/*#-end-editable-code*/,
		green:  /*#-editable-code */55/*#-end-editable-code*/,
		orange: /*#-editable-code */57/*#-end-editable-code*/)
	
//#-editable-code tap to edit
//#-end-editable-code
//#-hidden-code
}
//#-end-hidden-code
    
func press(side: Side, strength: Double) {
    var threshold = /*#-editable-code */0.65/*#-end-editable-code*/
    if strength > threshold {
        //#-editable-code tap to edit
        //#-end-editable-code
    }
    else {
        //#-editable-code tap to edit
        //#-end-editable-code
    }
}
    //#-hidden-code
    public override func peak(_ side: Side,_ peak: Double) {
        //on this page, call press before super, otherwise note settings will be out pf step
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

PlaygroundPage.current.liveView = contents
