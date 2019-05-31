//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2016 Apple Inc. All Rights Reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
**Goal** - Create colored ripples and pulses when your Skoog is pressed.

We can use the `ripple()` and `pulse()` functions to trigger some pretty cool animations whenever Skoog is pressed.
 
 * callout(Ripple Example):
	`ripple(color: side.color, size: strength)`
 * callout(Pulse Example):
	`pulse(color: side.color, size: strength)`
 
These functions should be called inside our `press()` event handler, and they share the following [parameters](glossary://parameter):
* `color` - Lets the effect know what color to be.
* `size`  - Tells it how big to be.

 **Exercise 1:** Experiment with the `ripple()` and `pulse()` effects. How do they differ?\
 **Exercise 2:** Explore the parameters. Use the `strength` of your press to set the size. What happens when you set the size or color to a fixed value?
*/
//#-hidden-code

import UIKit

import PlaygroundSupport
import CoreAudioKit
import SpriteKit
import SceneKit

PlaygroundSupport.PlaygroundPage.current.needsIndefiniteExecution = true

public class skoogContents: PlaygroundViewController {
	func setup() {
    }
//#-end-hidden-code
//#-code-completion(everything, hide)
//#-code-completion(identifier, show, ripple(color:size:), pulse(color:size:))
//#-code-completion(identifier, show, side, size, strength, rawValue, value, ., color) 
//#-code-completion(literal, show, boolean, color)
//#-code-completion(identifier, show, *, /, +, -, ==, !=)
func press(side: Side, strength: Double) {
    //#-editable-code
    
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
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View.  This will change color depending on what side of the Skoog you press. A matching colored ripple or pulse will animate depending on your code.", comment: "live view 10 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setSound(.vibraphone)
contents.setBackgroundGradient(gradient: .gradient5)

PlaygroundPage.current.liveView = contents
