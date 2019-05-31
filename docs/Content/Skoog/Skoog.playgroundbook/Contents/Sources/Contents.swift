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
 
 By default Pings arrange themselves in a spiral to create a cascade of notes. They can be also arranged by distance from the center (measured as the number of Ping diameters), and by angle (in degrees clockwise from 12 o'clock).
 
 **Exercise 1:**  Create three blue Pings at a distance of 1.0, and noteShifts of 5, 10, and 14 to make a chord.\
 **Exercise 2:** To play a simple note sequence, add three red Pings at a fixed angle at distances of 0.5, 1.5, and 2.5, and noteShifts of 12, 19, 24.
 * callout(Tip):
 This playground is best enjoyed in fullscreen!
 */
//#-hidden-code

import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

//PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    public var inst: SoundStyle = .marimba
	
    func setup() {
		setBackgroundGradient(gradient: .gradient1)
        //#-end-hidden-code
        //#-code-completion(everything, hide)
        //#-code-completion(identifier, show, setNotes, setRipple, speed, noteShift, distance, angle, side, color, size, strength, value, rawValue, addPing, setSound(_:), Instrument.type, ., name, true, false, acid, candyBee, fmModulator, solarWind, gamelan, strat, rhodes, jharp, marimba, ocarina, minimogo, elecpiano, nylonguitar, vibraphone, afromallet, timpani)
        //#-code-completion(literal, show, boolean, color)
        //#-code-completion(keyword, show, for, if, let, var, while)
        //#-editable-code tap to edit
        setSound(.saw)
        
        showPressLabels = true
        
        setRipple(speed: 1.5)
        
        setNotes(red:    48,
                 blue:   50,
                 yellow: 52,
                 green:  55,
                 orange: 57)
        
        addPing("green", noteShift: 5)
        addPing("yellow", noteShift: 10)
        addPing("white", noteShift: 7)
		
        addPing("red", noteShift: 12,
                distance: 0.25,
                angle: 195)
        addPing("red", noteShift: 19,
                distance: 1.35,
                angle: 195)
        addPing("red", noteShift: 24,
                distance: 2.5,
                angle: 195)
        
        addPing("blue", noteShift: 5,
                distance: 1.0)
        
        addPing("blue",  noteShift: 10,
                distance: 1.0)
        
        addPing("blue", noteShift: 14,
                distance: 1.0)
        
        //#-end-editable-code
        //#-hidden-code
    }
    //#-end-hidden-code
    
    func press(side: Side, strength: Double) {
        let input = side.value
        let threshold = /*#-editable-code */0.1/*#-end-editable-code*/
        if input > threshold {
            //#-editable-code
            ripple(color: side.color, size: strength)
            //#-end-editable-code
        }
        else {
            //#-editable-code
            pulse(color: side.color, size: strength)
            //#-end-editable-code
        }
    }
    //#-hidden-code
    public override func peak(_ side: Side,_ peak: Double) {
        //on this page, call press before super, otherwise note settings will be out pf step
        press(side: side, strength: peak)
        super.peak(side, peak)
    }
    
    public override func continuous(_ side: Side) {
        super.continuous(side)
//        filterCutOff(frequency: 100.0 + side.rawValue * 3000.0 )
//        filterResonance(resonance: -20.0 + side.rawValue * 20.0 )

//        squeeze(side:side)
    }

    
}
//let contents	=	skoogContents()
//contents.setup()
//contents.view.clipsToBounds = true
//contents.view.translatesAutoresizingMaskIntoConstraints = false
//contents.view.isAccessibilityElement = true
//contents.view.accessibilityLabel = NSLocalizedString("A white Skoog Circle appears in the center of the Live View.  This will change color depending on what side of the Skoog you press and a matching colored ripple or pulse will animate depending on your code. Several small circular Pings will be arranged around the outside of the Skoog Circle depending on your code. When a colored ripple or pulse meets a Ping, the Ping will glow gently and make a sound if it has the same color.  A white Ping will make a sound when ripples or pulses of any color meet it.", comment: "live view 13 label")
//safeAreaContainer.addSubview(contents.view)
//
//
////NSLayoutConstraint.activate([
////    contents.view.leadingAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.leadingAnchor),
////    contents.view.trailingAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.trailingAnchor),
////    contents.view.topAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.topAnchor),
////    contents.view.bottomAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.bottomAnchor)
////    ])
//NSLayoutConstraint.activate([
//    contents.view.leadingAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.leadingAnchor),
//    contents.view.trailingAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.trailingAnchor),
//    contents.view.topAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.topAnchor),
//    contents.view.bottomAnchor.constraint(equalTo: safeAreaContainer.liveViewSafeAreaGuide.bottomAnchor, constant: 84)
//    ])
//
//PlaygroundPage.current.liveView = safeAreaContainer
