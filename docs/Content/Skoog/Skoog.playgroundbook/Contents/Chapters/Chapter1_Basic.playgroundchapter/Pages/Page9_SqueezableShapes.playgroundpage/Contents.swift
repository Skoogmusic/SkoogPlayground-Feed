//#-hidden-code
//
//  Contents.swift
//
//  Copyright (c) 2016 Skoogmusic Ltd. All Rights Reserved.
//
//#-end-hidden-code
/*:#localized(key: "FirstProseBlock")
 
 **Goal** - Make the circle grow or change transparency when the Skoog is squeezed.
 
   * callout(Squeeze Events):
     The `squeeze()` [event handler](glossary://eventHandler) **continuously** updates while you are touching your Skoog. Just like the `press()` function, the `squeeze()` function can tell what side is being pressed and how hard, along with a number of other useful parameters.
 
The circle in the live view automatically changes color depending on what side you press; normally it's a fixed size and fully opaque. Let's try using our squeeze data to make it change size and transparency:
 
 * Circle size can be controlled using `grow(value: Double)`.
 * Transparency (otherwise known as [alpha](glossary://alpha)) can be controlled using `alpha(value: Double)`.

**Challenge** We've set up some code for the red and blue sides to get you started. Try setting up all of the other sides and see if you can change the circle size and transparency at the same time.
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
        showRipples = false
        showSqueezeLabel = true
        showPressLabels = false
        changeAlpha = false
//        changeColor = false
        setSound(.minimogo)

	}
    //#-end-hidden-code
    //#-code-completion(everything, hide)
    //#-code-completion(identifier, show, grow(value:), alpha(value:), :, ., *, /, +, -)
	//#-code-completion(identifier, show, side, size, name, strength, rawValue, value, ., color)
    //#-code-completion(literal, show, boolean, color)
    //#-code-completion(keyword, show, for, if, let, var, while)
func squeeze(side: Side) {
    if side.name == .red {
        //#-editable-code
        alpha(value: side.rawValue)
        //#-end-editable-code
    }
    if side.name == .blue {
        //#-editable-code
        grow(value: side.rawValue)
        alpha(value: side.rawValue)
        //#-end-editable-code
    }
    if side.name == .yellow {
        //#-editable-code tap to add code for yellow
        //#-end-editable-code
    }
    if side.name == .green {
        //#-editable-code tap to add code for green
        //#-end-editable-code
    }
    if side.name == .orange {
        //#-editable-code tap to add code for orange
        //#-end-editable-code
    }
}
    //#-hidden-code
    
    public override func continuous(_ side: Side) {
//        super.continuous(side)
//        skoogSKscene.circle!.strokeColor = side.color.withAlphaComponent(1.0)
        
        squeeze(side:side)
    }
}
let contents	=	skoogContents()
contents.setup()
contents.view.clipsToBounds = true
contents.view.translatesAutoresizingMaskIntoConstraints = false
contents.skoogSKscene.circle?.sceneDescription = String(format: "%@ %@ %@", NSLocalizedString("A black Skoog Circle appears in the center of the Live View.   This will change color, size and transparency depending on where and how hard you press the Skoog, and on what functions you have used in your code.", comment: "live view 9 label"), contents.skoogSKscene.getNumberOfPings(), contents.skoogSKscene.getPingDescriptions())
contents.setBackgroundGradient(gradient: .gradient5)

PlaygroundPage.current.liveView = contents
