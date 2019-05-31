//#-hidden-code
//
// Copyright (C) 2017 Skoogmusic Ltd. All Rights Reserved.
// See LICENSE.txt for this sample’s licensing information.
//
//
import UIKit
import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
    func setup() {
        //Override default values
        skoog.red.active = true
        skoog.blue.active = true
        skoog.yellow.active = true
        skoog.green.active = true
        skoog.orange.active = true
        growCircle = true
        changeAlpha = true
        showRipples = false
        showPressLabels = false
        showSqueezeLabel = false
        changeColor = true
        setRipple(speed: 1.5)
        
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, addPing(_:noteShift:distance:angle:))

/*:#localized(key: "FirstProseBlock")
 **Goal** - Set up your Skoog and discover some of the exciting things it can do.  Let's get started!
 
 1. Press "Run My Code."
 2. Next, follow these [instructions](glossary://connect) to connect your Skoog.
 3. Give it a go! What happens when you squeeze harder?
 
 * callout(NOTE):
 If your Skoog behaves unexpectedly, run this [simple test](glossary://simpleTest) to check that everything is ok.
 
 We've added a few "Pings" to the Live View for you to play with. Can you figure out what the different colors do? You'll meet Pings again later.
         
 **Exercise:** Explore the Skoog to see if you can find all 5 notes. Notice how the circle changes color and causes a ripple when you play a different note?
 */
setSound(.elecpiano)
        
setNotes(red:     48,
         blue:    50,
         yellow:  52,
         green:   55,
         orange:  57)

addPing("white",
        noteShift: 5,
        distance: 0.25,
        angle: 180)

addPing("orange",
        noteShift: 8,
        distance: 1.0,
        angle: 0)

addPing("green",
        noteShift: 9,
        distance: 1.0,
        angle: 72)

addPing("yellow",
        noteShift: 8,
        distance: 1.0,
        angle: 144)
        
addPing("red",
        noteShift: 9,
        distance: 1.0,
        angle: 216)
        
addPing("blue",
        noteShift: 9,
        distance: 1.0,
        angle: 288)
		
//#-editable-code tap to edit
//#-end-editable-code
//#-hidden-code
    }
    
    public override func peak(_ side: Side,_ peak: Double) {
        var threshold = 0.6
        if peak > threshold {
            ripple(color: side.color, size: peak)
        }
        else {
            pulse(color: side.color, size: peak)
        }
        super.peak(side, peak)
    }
}


let contents	=	skoogContents()
contents.setup()
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", contents.skoogSKscene.getBasicDescription(), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient4)


PlaygroundPage.current.liveView = contents

//#-end-hidden-code
